import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

import '../../models/portal_models.dart';
import '../features_helpers.dart' show isSageSelectProduct;
import '../../features/shop/cart_controller.dart';

/// Generates a Microsoft Word (.docx) order document for non-Sage-Select
/// studio furniture pieces and dispatches it to `sagestudio.ke@gmail.com`,
/// mirroring `EnquiryDocxService`.
class OrderDocxService {
  OrderDocxService._();

  static const String recipientEmail = 'sagestudio.ke@gmail.com';
  static const String studioLocation = 'Kamakis, Ruiru';

  static bool isSageSelect(CartItem item) => isSageSelectProduct(item.product);

  /// Generates a Microsoft Word (.docx) order document in memory.
  static List<int> generateOrderDocx({
    required String orderRef,
    required String fullName,
    required String email,
    required String phone,
    required Map<String, dynamic> deliveryAddress,
    required String? notes,
    required List<CartItem> items,
    required double totalKsh,
    required DateTime timestamp,
  }) {
    final archive = Archive();

    const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
    final contentTypesBytes = utf8.encode(contentTypesXml);
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesBytes.length, contentTypesBytes));

    const rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    final rootRelsBytes = utf8.encode(rootRelsXml);
    archive.addFile(ArchiveFile('_rels/.rels', rootRelsBytes.length, rootRelsBytes));

    const docRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>''';
    final docRelsBytes = utf8.encode(docRelsXml);
    archive.addFile(ArchiveFile('word/_rels/document.xml.rels', docRelsBytes.length, docRelsBytes));

    String esc(String text) => text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    final formattedDate =
        '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} EAT';

    final addressParts = <String>[
      if ((deliveryAddress['line1'] ?? '').toString().isNotEmpty) deliveryAddress['line1'].toString(),
      if ((deliveryAddress['line2'] ?? '').toString().isNotEmpty) deliveryAddress['line2'].toString(),
      if ((deliveryAddress['city'] ?? '').toString().isNotEmpty) deliveryAddress['city'].toString(),
      if ((deliveryAddress['region'] ?? '').toString().isNotEmpty) deliveryAddress['region'].toString(),
      if ((deliveryAddress['postal_code'] ?? '').toString().isNotEmpty) deliveryAddress['postal_code'].toString(),
      if ((deliveryAddress['country'] ?? '').toString().isNotEmpty) deliveryAddress['country'].toString(),
    ];
    final addressText = addressParts.join(', ');

    final itemParagraphs = items.map((item) {
      final p = item.product;
      return '''
    <w:p>
      <w:pPr><w:spacing w:after="100"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="111111"/></w:rPr>
        <w:t>• ${esc(p.title)} (${esc(p.subtitle)}) — ${esc(p.code)}</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr><w:ind w:left="360"/><w:spacing w:after="140"/></w:pPr>
      <w:r>
        <w:rPr><w:sz w:val="20"/><w:color w:val="555555"/></w:rPr>
        <w:t>Collection: ${esc(p.clan)} | Qty: ${item.quantity} | Unit: ${esc(formatKsh(p.priceKsh))} | Line Total: ${esc(formatKsh(item.lineTotal))}</w:t>
      </w:r>
    </w:p>''';
    }).join('\n');

    String section(String label, String value) => '''
    <w:p>
      <w:pPr><w:spacing w:after="140"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="725D24"/></w:rPr>
        <w:t>${esc(label)}:</w:t>
      </w:r>
      <w:r>
        <w:rPr><w:sz w:val="22"/></w:rPr>
        <w:t> ${esc(value)}</w:t>
      </w:r>
    </w:p>''';

    final docXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:pPr><w:jc w:val="center"/><w:spacing w:after="80"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="48"/><w:color w:val="725D24"/></w:rPr>
        <w:t>SAGE STUDIO</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr><w:jc w:val="center"/><w:spacing w:after="240"/></w:pPr>
      <w:r>
        <w:rPr><w:sz w:val="20"/><w:color w:val="666666"/></w:rPr>
        <w:t>NAIROBI, KENYA • CRAFTED IN KENYA</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr><w:jc w:val="center"/><w:spacing w:after="360"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="30"/><w:color w:val="CC5600"/></w:rPr>
        <w:t>CLIENT ORDER DOCUMENT — ${esc(orderRef)}</w:t>
      </w:r>
    </w:p>
    ${section('STUDIO RECIPIENT', '$recipientEmail ($studioLocation)')}
    ${section('ORDER REFERENCE', orderRef)}
    ${section('DATE & TIME SUBMITTED', formattedDate)}
    ${section('ORDER STATUS', 'Pending — Awaiting Studio Confirmation & Payment')}
    <w:p><w:pPr><w:spacing w:after="200"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="CC5600"/></w:rPr><w:t>CUSTOMER INFORMATION</w:t></w:r></w:p>
    ${section('FULL NAME', fullName)}
    ${section('EMAIL ADDRESS', email)}
    ${section('PHONE NUMBER', phone)}
    ${section('DELIVERY ADDRESS', addressText)}
    ${section('FINISH / DELIVERY NOTES', (notes == null || notes.trim().isEmpty) ? 'None provided' : notes.trim())}
    <w:p><w:pPr><w:spacing w:before="200" w:after="160"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="CC5600"/></w:rPr><w:t>ORDERED PIECES</w:t></w:r></w:p>
    $itemParagraphs
    <w:p>
      <w:pPr><w:spacing w:before="240" w:after="160"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="26"/><w:color w:val="CC5600"/></w:rPr>
        <w:t>ORDER TOTAL: ${esc(formatKsh(totalKsh))}</w:t>
      </w:r>
    </w:p>
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>
    </w:sectPr>
  </w:body>
</w:document>''';

    final docBytes = utf8.encode(docXml);
    archive.addFile(ArchiveFile('word/document.xml', docBytes.length, docBytes));

    return ZipEncoder().encode(archive) ?? <int>[];
  }

  /// Generates the `.docx` order document and dispatches it to
  /// `sagestudio.ke@gmail.com` via the backend email API.
  static Future<bool> processAndDispatchOrder({
    required String orderRef,
    required String fullName,
    required String email,
    required String phone,
    required Map<String, dynamic> deliveryAddress,
    required String? notes,
    required List<CartItem> items,
    required double totalKsh,
  }) async {
    final now = DateTime.now();
    final docxBytes = generateOrderDocx(
      orderRef: orderRef,
      fullName: fullName,
      email: email,
      phone: phone,
      deliveryAddress: deliveryAddress,
      notes: notes,
      items: items,
      totalKsh: totalKsh,
      timestamp: now,
    );

    final cleanName = fullName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = 'Sage_Studio_Order_${orderRef}_${cleanName.isEmpty ? "Client" : cleanName}.docx';
    final docxBase64 = base64Encode(docxBytes);

    final itemsSummary = items
        .map((i) =>
            '• ${i.product.title} (${i.product.subtitle}, ${i.product.code}) x${i.quantity} — ${formatKsh(i.lineTotal)}')
        .join('\n');

    final messageText = 'Order Reference: $orderRef\n'
        'Delivery Address: ${deliveryAddress.values.where((v) => v != null && v.toString().isNotEmpty).join(', ')}\n'
        'Order Total: ${formatKsh(totalKsh)}\n'
        'Notes: ${(notes == null || notes.trim().isEmpty) ? "None" : notes.trim()}\n\n'
        'Items:\n$itemsSummary';

    final payload = jsonEncode({
      'recipientEmail': recipientEmail,
      'orderRef': orderRef,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'serviceCategory': 'Sage Studio Order ($orderRef)',
      'message': messageText,
      'totalKsh': totalKsh,
      'items': items
          .map((i) => {
                'productId': i.baseProductId,
                'code': i.product.code,
                'title': i.product.title,
                'subtitle': i.product.subtitle,
                'clan': i.product.clan,
                'quantity': i.quantity,
                'unitPriceKsh': i.product.priceKsh,
                'lineTotalKsh': i.lineTotal,
              })
          .toList(),
      'fileName': fileName,
      'docxBase64': docxBase64,
      'submittedAt': now.toIso8601String(),
    });

    final endpoints = <String>[
      'http://localhost:8080/api/send-enquiry',
      '/api/send-enquiry',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: payload,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['success'] == true) {
            return true;
          }
        }
      } catch (_) {
        // Try next endpoint
      }
    }

    return false;
  }
}
