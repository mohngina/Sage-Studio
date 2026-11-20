import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

/// Dispatches an enquiry/order `.docx` payload to the local Dart server when
/// running on localhost, and to the Supabase `send-enquiry` Edge Function on
/// hosted/cPanel deployments.
class EnquiryDispatchHelper {
  EnquiryDispatchHelper._();

  static Future<bool> dispatch(String payload) async {
    final host = Uri.base.host.toLowerCase();
    final isLocalhost = host == 'localhost' || host == '127.0.0.1';

    final targets = <({String url, Map<String, String> headers})>[
      if (isLocalhost)
        (
          url: 'http://localhost:8080/api/send-enquiry',
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      if (SupabaseConfig.hasValues)
        (
          url: '${SupabaseConfig.url}/functions/v1/send-enquiry',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'apikey': SupabaseConfig.anonKey,
            'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          },
        ),
      if (!isLocalhost)
        (
          url: '/api/send-enquiry',
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
    ];

    for (final target in targets) {
      try {
        final response = await http
            .post(
              Uri.parse(target.url),
              headers: target.headers,
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
        // Try next target
      }
    }

    return false;
  }
}
