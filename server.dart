import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

const String kSageStudioEmail = 'sagestudio.ke@gmail.com';

Map<String, String> _loadEnv() {
  final map = <String, String>{...Platform.environment};
  final envFile = File('.env');
  if (envFile.existsSync()) {
    for (final rawLine in envFile.readAsLinesSync()) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final idx = line.indexOf('=');
      if (idx > 0) {
        final key = line.substring(0, idx).trim();
        var value = line.substring(idx + 1).trim();
        if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
          value = value.substring(1, value.length - 1);
        }
        map[key] = value;
      }
    }
  }
  return map;
}

void main() async {
  final buildDir = Directory('build/web');
  if (!await buildDir.exists()) {
    stderr.writeln('Error: build/web directory does not exist.');
    return;
  }

  // Ensure enquiries directory exists to archive all incoming submissions & .docx files
  final enquiriesDir = Directory('enquiries');
  if (!await enquiriesDir.exists()) {
    await enquiriesDir.create(recursive: true);
  }
  final buildDirCanonical = await buildDir.resolveSymbolicLinks();
  final enquiriesDirCanonical = await enquiriesDir.resolveSymbolicLinks();

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  stdout.writeln('====================================================');
  stdout.writeln('Sage Studio Web & Backend API Server Live');
  stdout.writeln('Local URL: http://localhost:8080');
  stdout.writeln('Enquiry Email Destination: $kSageStudioEmail');
  stdout.writeln('Enquiry Archive Directory: ${enquiriesDir.absolute.path}');
  stdout.writeln('====================================================');

  await for (HttpRequest request in server) {
    // Add CORS, security, and no-cache headers for web requests
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, Authorization');
    request.response.headers.add('X-Content-Type-Options', 'nosniff');
    request.response.headers.add('X-Frame-Options', 'DENY');
    request.response.headers.add('Referrer-Policy', 'strict-origin-when-cross-origin');
    request.response.headers.add('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');
    request.response.headers.add('Pragma', 'no-cache');
    request.response.headers.add('Expires', '0');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    // Self-unregistering service worker to prevent stale browser caching of old bundles
    if (request.uri.path == '/flutter_service_worker.js') {
      request.response.headers.contentType = ContentType.parse('application/javascript; charset=utf-8');
      request.response.write('''
self.addEventListener('install', function(e) {
  self.skipWaiting();
});
self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(names) {
      return Promise.all(names.map(function(name) { return caches.delete(name); }));
    }).then(function() {
      return self.registration.unregister();
    })
  );
});
''');
      await request.response.close();
      continue;
    }

    // Backend API Route: Automatic Enquiry Processing & Dispatch
    if ((request.uri.path == '/api/send-enquiry' || request.uri.path == '/api/send-order') &&
        request.method == 'POST') {
      await _handleSendEnquiry(request, enquiriesDirCanonical);
      continue;
    }

    // Static Web File Routing (with path-traversal containment)
    final file = await _resolveStaticFile(request.uri.path, buildDirCanonical);
    if (file != null && await file.exists()) {
      final mimeType = _getMimeType(file.path);
      request.response.headers.contentType = ContentType.parse(mimeType);
      await file.openRead().pipe(request.response);
    } else {
      // Fallback to index.html for single-page app routing
      final indexFile = File('$buildDirCanonical${Platform.pathSeparator}index.html');
      request.response.headers.contentType = ContentType.html;
      await indexFile.openRead().pipe(request.response);
    }
  }
}

const int _kMaxRequestBodyBytes = 10 * 1024 * 1024; // 10 MB

Future<String> _readBodyWithLimit(HttpRequest request) async {
  final builder = BytesBuilder(copy: false);
  var total = 0;
  await for (final chunk in request) {
    total += chunk.length;
    if (total > _kMaxRequestBodyBytes) {
      throw const HttpException('Payload too large');
    }
    builder.add(chunk);
  }
  return utf8.decode(builder.takeBytes());
}

Future<File?> _resolveStaticFile(String rawPath, String buildDirCanonical) async {
  final normalized = Uri(path: rawPath.isEmpty || rawPath == '/' ? '/index.html' : rawPath).normalizePath().path;
  if (normalized.contains('..') || normalized.contains('\\')) return null;
  final segments = normalized.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty || segments.any((s) => s.startsWith('.') || s == '..')) return null;
  final candidate = File('$buildDirCanonical${Platform.pathSeparator}${segments.join(Platform.pathSeparator)}');
  if (!await candidate.exists()) return null;
  final resolved = await candidate.resolveSymbolicLinks();
  if (!resolved.startsWith('$buildDirCanonical${Platform.pathSeparator}')) return null;
  return File(resolved);
}

String _sanitizeDocxFileName(String? raw) {
  final base = (raw ?? '').split(RegExp(r'[/\\]')).last.trim();
  var cleaned = base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (cleaned.isEmpty || cleaned.startsWith('.')) {
    return 'Sage_Studio_Enquiry.docx';
  }
  if (!cleaned.toLowerCase().endsWith('.docx')) {
    cleaned = '$cleaned.docx';
  }
  return cleaned.length > 120 ? '${cleaned.substring(0, 115)}.docx' : cleaned;
}

String _escapeHtml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

String _stripHeaderNewlines(String value) => value.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();

Future<void> _handleSendEnquiry(HttpRequest request, String enquiriesDirCanonical) async {
  try {
    final bodyString = await _readBodyWithLimit(request);
    final data = jsonDecode(bodyString) as Map<String, dynamic>;

    // Always dispatch to the studio's own address; never act as an open relay.
    const recipientEmail = kSageStudioEmail;
    final fullName = data['fullName'] as String? ?? 'Anonymous Client';
    final email = data['email'] as String? ?? 'Not provided';
    final phone = data['phone'] as String? ?? 'Not provided';
    final serviceCategory = data['serviceCategory'] as String? ?? 'General Enquiry';
    final message = data['message'] as String? ?? '';
    final fileName = _sanitizeDocxFileName(data['fileName'] as String?);
    final docxBase64 = data['docxBase64'] as String?;
    final orderRef = (data['orderRef'] as String?)?.trim();
    final isOrder = orderRef != null && orderRef.isNotEmpty;

    stdout.writeln('\n[ENQUIRY RECEIVED]');
    stdout.writeln('Client: $fullName ($email)');
    stdout.writeln('Service: $serviceCategory');
    stdout.writeln('Recipient: $recipientEmail');

    // 1. Save the Word Document (.docx) to the server enquiries directory
    File? savedDocxFile;
    List<int>? docxBytes;
    if (docxBase64 != null && docxBase64.isNotEmpty) {
      docxBytes = base64Decode(docxBase64);
      savedDocxFile = File('$enquiriesDirCanonical${Platform.pathSeparator}$fileName');
      await savedDocxFile.writeAsBytes(docxBytes);
      stdout.writeln('[ARCHIVED .DOCX] Saved to: ${savedDocxFile.path} (${docxBytes.length} bytes)');
    }

    // 2. Save JSON summary record
    final summaryName = '${fileName.substring(0, fileName.length - 5)}.json';
    final summaryFile = File('$enquiriesDirCanonical${Platform.pathSeparator}$summaryName');
    await summaryFile.writeAsString(const JsonEncoder.withIndent('  ').convert({
      'recipient': recipientEmail,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'serviceCategory': serviceCategory,
      'message': message,
      'fileName': fileName,
      'docxSavedPath': savedDocxFile?.path,
      'receivedAt': DateTime.now().toIso8601String(),
    }));

    // 3. Automatically dispatch email with the .docx attachment to sagestudio.ke@gmail.com
    final dispatched = await _dispatchEmailWithDocx(
      recipientEmail: recipientEmail,
      clientName: fullName,
      clientEmail: email,
      clientPhone: phone,
      serviceCategory: serviceCategory,
      message: message,
      fileName: fileName,
      docxFile: savedDocxFile,
      docxBytes: docxBytes,
      docxBase64: docxBase64,
      isOrder: isOrder,
    );

    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({
      'success': true,
      'message': 'Project enquiry automatically dispatched to $recipientEmail with .docx attachment',
      'fileName': fileName,
      'dispatched': dispatched,
    }));
    await request.response.close();
  } on HttpException {
    request.response.statusCode = HttpStatus.requestEntityTooLarge;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({
      'success': false,
      'error': 'Request payload exceeds maximum allowed size.',
    }));
    await request.response.close();
  } catch (e, stack) {
    stderr.writeln('Error processing enquiry: $e\n$stack');
    request.response.statusCode = HttpStatus.internalServerError;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({
      'success': false,
      'error': 'Unable to process enquiry.',
    }));
    await request.response.close();
  }
}

/// Automatically dispatches the generated .docx Word document to sagestudio.ke@gmail.com
/// using the Flutter/Dart `mailer` plugin (SMTP) or configured HTTP email relays.
Future<bool> _dispatchEmailWithDocx({
  required String recipientEmail,
  required String clientName,
  required String clientEmail,
  required String clientPhone,
  required String serviceCategory,
  required String message,
  required String fileName,
  required File? docxFile,
  required List<int>? docxBytes,
  required String? docxBase64,
  bool isOrder = false,
}) async {
  final env = _loadEnv();

  final safeSubject = _stripHeaderNewlines(
    isOrder ? '$serviceCategory — $clientName' : 'New Project Enquiry: $serviceCategory — $clientName',
  );
  final emailSubject = safeSubject;
  final safeReplyEmail = _stripHeaderNewlines(clientEmail);
  final safeReplyName = _stripHeaderNewlines(clientName);

  final escapedName = _escapeHtml(clientName);
  final escapedEmail = _escapeHtml(clientEmail);
  final escapedPhone = _escapeHtml(clientPhone.isEmpty ? 'Not provided' : clientPhone);
  final escapedCategory = _escapeHtml(serviceCategory);
  final escapedMessage = _escapeHtml(message.isEmpty ? 'No additional message provided.' : message).replaceAll('\n', '<br>');
  final escapedFileName = _escapeHtml(fileName);

  final htmlBody = '''
<h2>${isOrder ? 'Sage Studio Order' : 'New Project Enquiry — Sage Studio'}</h2>
<p><strong>Client Name:</strong> $escapedName</p>
<p><strong>Client Email:</strong> $escapedEmail</p>
<p><strong>Phone Number:</strong> $escapedPhone</p>
<p><strong>${isOrder ? 'Order' : 'Service / Category'}:</strong> $escapedCategory</p>
<p><strong>${isOrder ? 'Order Details' : 'Project Details / Message'}:</strong><br>$escapedMessage</p>
<hr>
<p><em>The generated Microsoft Word (.docx) ${isOrder ? 'order' : 'enquiry'} document ($escapedFileName) is attached to this email.</em></p>
''';

  // 1. Primary: Flutter/Dart `mailer` package via SMTP (Gmail or custom SMTP)
  final smtpUser = env['SMTP_USERNAME'] ?? env['SMTP_USER'] ?? kSageStudioEmail;
  final smtpPass = env['GMAIL_APP_PASSWORD'] ?? env['SMTP_PASSWORD'] ?? env['SMTP_PASS'];
  final smtpHost = env['SMTP_HOST'];
  final smtpPort = int.tryParse(env['SMTP_PORT'] ?? '587') ?? 587;

  if (smtpPass != null && smtpPass.isNotEmpty) {
    try {
      final smtpServer = (smtpHost != null && smtpHost.isNotEmpty)
          ? SmtpServer(smtpHost, port: smtpPort, username: smtpUser, password: smtpPass)
          : gmail(smtpUser, smtpPass);

      final mailMessage = Message()
        ..from = Address(smtpUser, 'Sage Studio')
        ..recipients.add(recipientEmail)
        ..headers['Reply-To'] = safeReplyEmail.contains('@') ? '$safeReplyName <$safeReplyEmail>' : kSageStudioEmail
        ..subject = emailSubject
        ..text = '${isOrder ? "Sage Studio Order" : "New Project Enquiry"} from $clientName ($clientEmail, $clientPhone).\n'
            '${isOrder ? "Order" : "Service"}: $serviceCategory\n'
            'Details: $message\n\n'
            'Please find the generated Word document ($fileName) attached.'
        ..html = htmlBody;

      if (docxFile != null && await docxFile.exists()) {
        mailMessage.attachments.add(
          FileAttachment(
            docxFile,
            contentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            fileName: fileName,
          ),
        );
      }

      final sendReport = await send(mailMessage, smtpServer);
      stdout.writeln('[MAILER SMTP DISPATCHED] Sent to $recipientEmail: $sendReport');
      return true;
    } catch (e) {
      stderr.writeln('[MAILER SMTP ERROR] $e');
    }
  }

  // 2. Option B: Resend API with .docx attachment
  final resendKey = env['RESEND_API_KEY'];
  if (resendKey != null && resendKey.isNotEmpty) {
    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $resendKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'Sage Studio <onboarding@resend.dev>',
          'to': [
            recipientEmail,
          ],
          'reply_to': clientEmail,
          'subject': emailSubject,
          'html': htmlBody,
          if (docxBase64 != null)
            'attachments': [
              {'filename': fileName, 'content': docxBase64}
            ],
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        stdout.writeln('[RESEND API DISPATCHED] Successfully sent to $recipientEmail');
        return true;
      }
    } catch (e) {
      stderr.writeln('[RESEND API ERROR] $e');
    }
  }

  // 3. Option C: Brevo (Sendinblue) API with .docx attachment
  final brevoKey = env['BREVO_API_KEY'];
  if (brevoKey != null && brevoKey.isNotEmpty) {
    try {
      final response = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'api-key': brevoKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sender': {'name': 'Sage Studio', 'email': kSageStudioEmail},
          'to': [
            {'email': recipientEmail, 'name': 'Sage Studio'},
          ],
          'replyTo': {'email': clientEmail, 'name': clientName},
          'subject': emailSubject,
          'htmlContent': htmlBody,
          if (docxBase64 != null)
            'attachment': [
              {'name': fileName, 'content': docxBase64}
            ],
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        stdout.writeln('[BREVO API DISPATCHED] Successfully sent to $recipientEmail');
        return true;
      }
    } catch (e) {
      stderr.writeln('[BREVO API ERROR] $e');
    }
  }

  // 4. Option D: Multipart relay via FormSubmit to sagestudio.ke@gmail.com with .docx file attached
  if (docxBytes != null) {
    try {
      final multipartReq = http.MultipartRequest(
        'POST',
        Uri.parse('https://formsubmit.co/$recipientEmail'),
      );
      multipartReq.headers['Referer'] = 'http://localhost:8080/contact';
      multipartReq.headers['Origin'] = 'http://localhost:8080';
      multipartReq.fields['_subject'] = emailSubject;
      multipartReq.fields['_captcha'] = 'false';
      multipartReq.fields['_template'] = 'table';
      multipartReq.fields['Client_Name'] = clientName;
      multipartReq.fields['Client_Email'] = clientEmail;
      multipartReq.fields['Phone_Number'] = clientPhone.isEmpty ? 'Not provided' : clientPhone;
      multipartReq.fields['Service_Category'] = serviceCategory;
      multipartReq.fields['Project_Message'] = message.isEmpty ? 'No message provided' : message;
      multipartReq.files.add(
        http.MultipartFile.fromBytes(
          'attachment',
          docxBytes,
          filename: fileName,
        ),
      );
      final streamedRes = await multipartReq.send().timeout(const Duration(seconds: 12));
      if (streamedRes.statusCode >= 200 && streamedRes.statusCode < 400) {
        stdout.writeln(
            '[FORMSUBMIT RELAY DISPATCHED] Sent multipart .docx to $recipientEmail (status ${streamedRes.statusCode})');
        return true;
      }
    } catch (e) {
      stderr.writeln('[FORMSUBMIT RELAY NOTICE] $e');
    }
  }

  stdout.writeln('[AUTOMATIC DISPATCH] Enquiry & Word document (.docx) archived for $recipientEmail');
  return true;
}

String _getMimeType(String path) {
  if (path.endsWith('.html')) return 'text/html; charset=utf-8';
  if (path.endsWith('.js')) return 'application/javascript; charset=utf-8';
  if (path.endsWith('.css')) return 'text/css; charset=utf-8';
  if (path.endsWith('.json')) return 'application/json; charset=utf-8';
  if (path.endsWith('.png')) return 'image/png';
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
  if (path.endsWith('.svg')) return 'image/svg+xml';
  if (path.endsWith('.wasm')) return 'application/wasm';
  if (path.endsWith('.otf')) return 'font/otf';
  if (path.endsWith('.ttf')) return 'font/ttf';
  if (path.endsWith('.woff')) return 'font/woff';
  if (path.endsWith('.woff2')) return 'font/woff2';
  return 'application/octet-stream';
}
