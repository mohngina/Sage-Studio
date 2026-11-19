/// Pure input validators shared by the client portal forms.
///
/// Each returns `null` when valid, or a user-facing message otherwise, so they
/// plug directly into `TextFormField.validator`.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$");

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email address.';
    if (v.length > 254 || !_email.hasMatch(v)) return 'Please enter a valid email address.';
    return null;
  }

  /// Sign-in only checks presence; strength rules apply at registration.
  static String? passwordPresent(String? value) {
    if ((value ?? '').isEmpty) return 'Please enter your password.';
    return null;
  }

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please choose a password.';
    if (v.length < 8) return 'Use at least 8 characters.';
    if (v.length > 72) return 'Use at most 72 characters.';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Include at least one letter and one number.';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if ((value ?? '').isEmpty) return 'Please confirm your password.';
      if (value != original()) return 'Passwords do not match.';
      return null;
    };
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your full name.';
    if (v.length < 2) return 'Name is too short.';
    if (v.length > 100) return 'Name must be 100 characters or fewer.';
    return null;
  }

  /// Mandatory phone number validator.
  static String? requiredPhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your phone number.';
    return optionalPhone(v);
  }

  /// Optional phone number. Accepts international formats such as
  /// `+254 700 000000`, `0700000000`, `(020) 123-4567`.
  static String? optionalPhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!RegExp(r'^\+?[0-9 ()\-]{7,20}$').hasMatch(v)) {
      return 'Enter a valid phone number, e.g. +254 700 000000.';
    }
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number, e.g. +254 700 000000.';
    }
    return null;
  }

  static String? Function(String?) maxLength(int max, {bool required = false, String field = 'This field'}) {
    return (value) {
      final v = value?.trim() ?? '';
      if (required && v.isEmpty) return '$field is required.';
      if (v.length > max) return '$field must be $max characters or fewer.';
      return null;
    };
  }
}
