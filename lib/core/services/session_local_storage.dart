import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_local_storage_stub.dart'
    if (dart.library.js_interop) 'session_local_storage_web.dart' as web;

/// Stores Supabase Auth sessions in browser `sessionStorage` on Web so
/// sessions survive same-tab refreshes and Google OAuth redirects, but are
/// automatically cleared as soon as the browser tab is closed.
class SessionOnlyLocalStorage extends LocalStorage {
  const SessionOnlyLocalStorage({required this.persistSessionKey});

  final String persistSessionKey;

  @override
  Future<void> initialize() async {
    if (kIsWeb) {
      // Clear any previously persisted localStorage session from older builds.
      web.localRemoveItem(persistSessionKey);
    }
  }

  @override
  Future<bool> hasAccessToken() async =>
      kIsWeb && web.sessionGetItem(persistSessionKey) != null;

  @override
  Future<String?> accessToken() async =>
      kIsWeb ? web.sessionGetItem(persistSessionKey) : null;

  @override
  Future<void> removePersistedSession() async {
    if (kIsWeb) {
      web.sessionRemoveItem(persistSessionKey);
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (kIsWeb) {
      web.sessionSetItem(persistSessionKey, persistSessionString);
    }
  }
}
