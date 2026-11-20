import 'dart:convert';
import 'package:archive/archive.dart';
import 'enquiry_dispatch_helper.dart';

class EnquiryDocxService {
  static const String recipientEmail = 'sagestudio.ke@gmail.com';
  static const String studioLocation = 'Kamakis, Ruiru';
  static const String studioPhone = '+254 794 001715';
  static const String studioHours = 'Monday - Friday: 09:00 - 17:00 EAT (By private appointment only)';

  /// Generates a Microsoft Word (.docx) document in memory and returns the byte array.
  static List<int> generateEnquiryDocx({
    required String fullName,
    required String email,
    required String phone,
    required String serviceCategory,
    required String message,
    required DateTime timestamp,
  }) {
    final archive = Archive();

    // 1. [Content_Types].xml
    const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
    final contentTypesBytes = utf8.encode(contentTypesXml);
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesBytes.length, contentTypesBytes));

    // 2. _rels/.rels
    const rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    final rootRelsBytes = utf8.encode(rootRelsXml);
    archive.addFile(ArchiveFile('_rels/.rels', rootRelsBytes.length, rootRelsBytes));

    // 3. word/_rels/document.xml.rels
    const docRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>''';
    final docRelsBytes = utf8.encode(docRelsXml);
    archive.addFile(ArchiveFile('word/_rels/document.xml.rels', docRelsBytes.length, docRelsBytes));

    // Helper to escape XML characters
    String escapeXml(String text) {
      return text
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&apos;');
    }

    final formattedDate =
        '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} EAT';

    // 4. word/document.xml
    final docXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <!-- Brand Header -->
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
        <w:spacing w:after="80"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="48"/>
          <w:color w:val="725D24"/>
        </w:rPr>
        <w:t>SAGE STUDIO</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
        <w:spacing w:after="240"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:sz w:val="20"/>
          <w:color w:val="666666"/>
        </w:rPr>
        <w:t>NAIROBI, KENYA • CRAFTED IN KENYA</w:t>
      </w:r>
    </w:p>

    <!-- Subtitle / Notice -->
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
        <w:spacing w:after="360"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="30"/>
          <w:color w:val="CC5600"/>
        </w:rPr>
        <w:t>CLIENT PROJECT ENQUIRY FORM</w:t>
      </w:r>
    </w:p>

    <!-- Destination Information -->
    <w:p>
      <w:pPr><w:spacing w:after="160"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="725D24"/></w:rPr>
        <w:t>STUDIO RECIPIENT:</w:t>
      </w:r>
      <w:r>
        <w:rPr><w:sz w:val="22"/></w:rPr>
        <w:t> ${escapeXml(recipientEmail)} (${escapeXml(studioLocation)})</w:t>
      </w:r>
    </w:p>

    <w:p>
      <w:pPr><w:spacing w:after="160"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="725D24"/></w:rPr>
        <w:t>DATE &amp; TIME SUBMITTED:</w:t>
      </w:r>
      <w:r>
        <w:rPr><w:sz w:val="22"/></w:rPr>
        <w:t> ${escapeXml(formattedDate)}</w:t>
      </w:r>
    </w:p>

    <w:p>
      <w:pPr><w:spacing w:after="160"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="725D24"/></w:rPr>
        <w:t>SERVICE / CATEGORY OF INTEREST:</w:t>
      </w:r>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="CC5600"/></w:rPr>
        <w:t> ${escapeXml(serviceCategory)}</w:t>
      </w:r>
    </w:p>

    <w:p>
      <w:pPr><w:spacing w:after="160"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="725D24"/></w:rPr>
        <w:t>CLIENT FULL NAME:</w:t>
      </w:r>
      <w:r>
        <w:rPr><w:sz w:val="22"/></w:rPr>
        <w:t> ${escapeXml(fullName)}</w:t>
      </w:r>
    </w:p>

    <w:p>
      <w:pPr><w:spacing w:after="160"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="725D24"/></w:rPr>
        <w:t>EMAIL ADDRESS:</w:t>
      </w:r>
      <w:r>
        <w:rPr><w:sz w:val="22"/></w:rPr>
        <w:t> ${escapeXml(email)}</w:t>
      </w:r>
    </w:p>

    <w:p>
      <w:pPr><w:spacing w:after="160"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="725D24"/></w:rPr>
        <w:t>PHONE NUMBER:</w:t>
      </w:r>
      <w:r>
        <w:rPr><w:sz w:val="22"/></w:rPr>
        <w:t> ${escapeXml(phone.isEmpty ? 'Not specified' : phone)}</w:t>
      </w:r>
    </w:p>

    <w:p>
      <w:pPr><w:spacing w:before="240" w:after="120"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="725D24"/></w:rPr>
        <w:t>PROJECT DETAILS &amp; VISION:</w:t>
      </w:r>
    </w:p>

    <w:p>
      <w:pPr><w:spacing w:after="360"/></w:pPr>
      <w:r>
        <w:rPr><w:sz w:val="22"/></w:rPr>
        <w:t>${escapeXml(message.isEmpty ? 'No additional message provided.' : message)}</w:t>
      </w:r>
    </w:p>

    <!-- Studio Footer Notes -->
    <w:p>
      <w:pPr><w:spacing w:before="360" w:after="100"/></w:pPr>
      <w:r>
        <w:rPr><w:b/><w:sz w:val="20"/><w:color w:val="666666"/></w:rPr>
        <w:t>Sage Studio | Contemporary African Proportions</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr><w:spacing w:after="80"/></w:pPr>
      <w:r>
        <w:rPr><w:sz w:val="18"/><w:color w:val="888888"/></w:rPr>
        <w:t>Studio: ${escapeXml(studioLocation)} • Tel: ${escapeXml(studioPhone)}</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:rPr><w:sz w:val="18"/><w:color w:val="888888"/></w:rPr>
        <w:t>Direct Email: ${escapeXml(recipientEmail)} • Hours: ${escapeXml(studioHours)}</w:t>
      </w:r>
    </w:p>

  </w:body>
</w:document>''';

    final docBytes = utf8.encode(docXml);
    archive.addFile(ArchiveFile('word/document.xml', docBytes.length, docBytes));

    // Encode to standard ZIP-based .docx
    final encoder = ZipEncoder();
    final docxBytes = encoder.encode(archive);
    return docxBytes ?? <int>[];
  }

  /// Automatically dispatches the project enquiry and its generated Microsoft Word
  /// (.docx) document directly to sagestudio.ke@gmail.com via the backend email API.
  /// No file download is triggered for the user.
  static Future<bool> processAndDispatchEnquiry({
    required String fullName,
    required String email,
    required String phone,
    required String serviceCategory,
    required String message,
  }) async {
    final now = DateTime.now();

    // 1. Generate .docx Word Document in memory
    final docxBytes = generateEnquiryDocx(
      fullName: fullName,
      email: email,
      phone: phone,
      serviceCategory: serviceCategory,
      message: message,
      timestamp: now,
    );

    final cleanName = fullName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = 'Sage_Studio_Enquiry_${cleanName.isEmpty ? "Client" : cleanName}.docx';
    final docxBase64 = base64Encode(docxBytes);

    // 2. Prepare payload for automatic dispatch to sagestudio.ke@gmail.com
    final payload = jsonEncode({
      'recipientEmail': recipientEmail,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'serviceCategory': serviceCategory,
      'message': message,
      'fileName': fileName,
      'docxBase64': docxBase64,
      'submittedAt': now.toIso8601String(),
    });

    // 3. Send automatically via HTTP POST to backend API (no user download)
    return EnquiryDispatchHelper.dispatch(payload);
  }
}
