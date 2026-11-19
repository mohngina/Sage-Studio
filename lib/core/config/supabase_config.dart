import 'dart:convert';

/// Client-side Supabase configuration.
///
/// Values are injected at build/run time with `--dart-define` so that no
/// project-specific values are committed to source control:
///
/// ```
/// flutter run -d chrome \
///   --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=<publishable-or-anon-key>
/// ```
///
/// Only the public URL and the publishable/anon key belong here. The
/// service-role / secret key must NEVER be supplied to the Flutter client;
/// [isForbiddenKey] actively refuses such keys.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zjhhodeqqpsjxwpejdah.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_aS39mfrkIkL5SQ81nfOp0w_X22nBT5Y',
  );

  /// Optional explicit OAuth / email redirect target (e.g. the deployed site
  /// origin). When empty, the current browser origin is used.
  static const String authRedirectUrl = String.fromEnvironment('AUTH_REDIRECT_URL');

  static bool get hasValues => url.isNotEmpty && anonKey.isNotEmpty;

  /// True when values are present and the key is safe for client use.
  static bool get isConfigured => hasValues && !isForbiddenKey(anonKey) && _looksLikeUrl(url);

  /// Detects secret keys that must never be shipped to a browser:
  /// new-style `sb_secret_...` keys and legacy JWT keys whose `role` claim is
  /// `service_role`. Never logs or returns the key itself.
  static bool isForbiddenKey(String key) {
    final trimmed = key.trim();
    if (trimmed.startsWith('sb_secret_')) return true;
    final parts = trimmed.split('.');
    if (parts.length == 3) {
      try {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        final claims = jsonDecode(payload);
        if (claims is Map && claims['role'] == 'service_role') return true;
      } catch (_) {
        // Not a decodable JWT; treat as a non-JWT publishable key.
      }
    }
    return false;
  }

  static bool _looksLikeUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
  }
}
