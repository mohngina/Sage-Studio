import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Converts backend exceptions into safe, user-facing messages.
class BackendErrors {
  BackendErrors._();

  /// Errors raised deliberately by our SQL functions carry friendly messages.
  static const _friendlyCodes = {'P0001', 'P0002', 'P0003', 'P0004', 'P0006', 'P0007', '22023'};

  static String message(Object error, {String fallback = 'Something went wrong. Please try again.'}) {
    debugPrint('[SageStudio BackendError] (${error.runtimeType}) $error');
    if (error is PostgrestException) {
      if (_friendlyCodes.contains(error.code)) return error.message;
      if (error.code == 'PGRST301' || error.code == 'PGRST302' || error.code == '28000') {
        return 'Your session has expired. Please sign in again.';
      }
      if (error.code == '42501') {
        return 'Database permission error (${error.message}). Please ensure the SQL table grants migration has been applied.';
      }
      if (error.code == '23503') return 'That product is no longer available in the database catalogue.';
      if (error.code == '23505') return 'You have already submitted this.';
      if (error.code == '23514') return 'Some of the information entered is not valid.';
      return fallback;
    }
    if (error is StorageException) {
      final status = error.statusCode ?? '';
      if (status == '413') return 'That image is too large. Please choose one under 2 MB.';
      if (status == '415' || error.message.toLowerCase().contains('mime')) {
        return 'Please choose a JPG, PNG or WEBP image.';
      }
      return 'We could not upload that image. Please try again.';
    }
    if (error is FunctionException) {
      final details = error.details;
      if (details is Map) {
        final msg = details['error'] ?? details['message'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      } else if (details is String && details.trim().isNotEmpty) {
        return details;
      }
      return error.reasonPhrase ?? fallback;
    }
    if (error is AuthException) return 'Your session has expired. Please sign in again.';
    final text = error.toString().toLowerCase();
    if (text.contains('socket') || text.contains('network') || text.contains('failed to fetch')) {
      return 'You appear to be offline. Check your connection and try again.';
    }
    return fallback;
  }
}
