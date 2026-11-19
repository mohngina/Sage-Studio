import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sage_studio/core/config/supabase_config.dart';
import 'package:sage_studio/core/utils/validators.dart';

String _fakeJwt(Map<String, dynamic> claims) {
  String seg(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${seg({'alg': 'HS256', 'typ': 'JWT'})}.${seg(claims)}.signature';
}

void main() {
  group('Validators.email', () {
    test('rejects empty and malformed', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('a b@c.com'), isNotNull);
    });
    test('accepts valid, trimming whitespace', () {
      expect(Validators.email('client@sagestudio.co.ke'), isNull);
      expect(Validators.email('  first.last+tag@example.com '), isNull);
    });
  });

  group('Validators.newPassword', () {
    test('enforces length and mix', () {
      expect(Validators.newPassword(''), isNotNull);
      expect(Validators.newPassword('abc123'), isNotNull);
      expect(Validators.newPassword('abcdefgh'), isNotNull);
      expect(Validators.newPassword('12345678'), isNotNull);
      expect(Validators.newPassword('a' * 80 + '1'), isNotNull);
      expect(Validators.newPassword('sofa2025'), isNull);
    });
    test('confirm must match', () {
      final v = Validators.confirmPassword(() => 'sofa2025');
      expect(v(''), isNotNull);
      expect(v('sofa2026'), isNotNull);
      expect(v('sofa2025'), isNull);
    });
  });

  group('Validators misc', () {
    test('full name', () {
      expect(Validators.fullName(' '), isNotNull);
      expect(Validators.fullName('A'), isNotNull);
      expect(Validators.fullName('Amina Wambui'), isNull);
    });
    test('optional and required phone', () {
      expect(Validators.optionalPhone(''), isNull);
      expect(Validators.optionalPhone('+254 700 000000'), isNull);
      expect(Validators.optionalPhone('0700000000'), isNull);
      expect(Validators.optionalPhone('12ab'), isNotNull);
      expect(Validators.optionalPhone('123'), isNotNull);
      expect(Validators.requiredPhone(''), 'Please enter your phone number.');
      expect(Validators.requiredPhone('+254 700 000000'), isNull);
    });
    test('maxLength', () {
      final v = Validators.maxLength(5, required: true, field: 'City');
      expect(v(''), 'City is required.');
      expect(v('Nairobi'), isNotNull);
      expect(v('Thika'), isNull);
    });
  });

  group('SupabaseConfig.isForbiddenKey', () {
    test('rejects new-style secret keys', () {
      expect(SupabaseConfig.isForbiddenKey('sb_secret_abc123'), isTrue);
    });
    test('rejects legacy service_role JWTs', () {
      expect(SupabaseConfig.isForbiddenKey(_fakeJwt({'role': 'service_role'})), isTrue);
    });
    test('allows anon JWTs and publishable keys', () {
      expect(SupabaseConfig.isForbiddenKey(_fakeJwt({'role': 'anon'})), isFalse);
      expect(SupabaseConfig.isForbiddenKey('sb_publishable_abc123'), isFalse);
    });
    test('configured with valid non-secret client key by default', () {
      expect(SupabaseConfig.isConfigured, isTrue);
      expect(SupabaseConfig.isForbiddenKey(SupabaseConfig.anonKey), isFalse);
    });
  });
}
