import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

enum AuthStatus { unconfigured, initialising, signedOut, signedIn }

/// Result of an auth action, carrying a user-facing message.
class AuthResult {
  final bool ok;
  final String message;
  const AuthResult.success(this.message) : ok = true;
  const AuthResult.failure(this.message) : ok = false;
}

/// App-wide authentication state backed by Supabase Auth.
///
/// Mirrors the existing `CartController` pattern (ChangeNotifier singleton +
/// `ListenableBuilder`) so it fits the current state-management approach.
/// No tokens, keys or raw error payloads are ever logged.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _postAuthRouteKey = 'sage_post_auth_route';

  AuthStatus _status = AuthStatus.unconfigured;
  bool _clientInitialised = false;
  User? _user;
  bool _passwordRecovery = false;
  String? _initError;
  StreamSubscription<AuthState>? _sub;
  final List<FutureOr<void> Function()> _signOutHooks = [];
  final List<FutureOr<void> Function(User user)> _signInHooks = [];

  /// Route the app should open after an auth event completes (set by
  /// [consumePendingRoute] consumers such as `SageStudioApp`).
  final ValueNotifier<String?> pendingNavigation = ValueNotifier<String?>(null);

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isConfigured => _status != AuthStatus.unconfigured;
  bool get isClientReady => _clientInitialised;
  bool get isSignedIn => _status == AuthStatus.signedIn && _user != null;
  bool get isPasswordRecovery => _passwordRecovery;
  String? get initError => _initError;

  String get displayName {
    final meta = _user?.userMetadata ?? const {};
    final name = (meta['full_name'] ?? meta['name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    return _user?.email ?? 'Account';
  }

  GoTrueClient get _auth => Supabase.instance.client.auth;

  /// Initialise Supabase once at startup. Safe to call when unconfigured:
  /// the public website keeps working and portal features show a notice.
  Future<void> initialise() async {
    if (!SupabaseConfig.isConfigured) {
      _status = AuthStatus.unconfigured;
      if (SupabaseConfig.hasValues && SupabaseConfig.isForbiddenKey(SupabaseConfig.anonKey)) {
        _initError = 'A secret/service-role key was supplied. Only the publishable (anon) key may be used.';
      }
      notifyListeners();
      return;
    }
    _status = AuthStatus.initialising;
    try {
      var alreadyInitialised = false;
      try {
        Supabase.instance.client;
        alreadyInitialised = true;
      } catch (_) {}
      if (!alreadyInitialised) {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          publishableKey: SupabaseConfig.anonKey,
          authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
          debug: false,
        );
      }
      _clientInitialised = true;
      _user = _auth.currentUser;
      _status = _user != null ? AuthStatus.signedIn : AuthStatus.signedOut;
      _sub = _auth.onAuthStateChange.listen(_onAuthChange, onError: (_) {
        // Typically an invalid/expired OAuth or recovery link.
        _initError = 'That sign-in link is invalid or has expired. Please try again.';
        notifyListeners();
      });
      if (_user != null) {
        await _runSignInHooks(_user!);
        // If PKCE OAuth exchange completed during Supabase.initialize(), restore
        // any stored post-auth destination (e.g. '/account' or product return route).
        final route = await _takeStoredRoute();
        if (route != null && !_passwordRecovery) {
          pendingNavigation.value = route;
        }
      }
    } catch (e) {
      debugPrint('[AuthService.initialise] failed: $e');
      _status = AuthStatus.unconfigured;
      _initError = 'Customer accounts are temporarily unavailable.';
    }
    notifyListeners();
  }

  Future<void> _onAuthChange(AuthState state) async {
    final previous = _user;
    _user = state.session?.user ?? _auth.currentUser;
    switch (state.event) {
      case AuthChangeEvent.passwordRecovery:
        _passwordRecovery = true;
        _status = AuthStatus.signedIn;
        pendingNavigation.value = '/sign-in?mode=update-password';
        break;
      case AuthChangeEvent.signedIn:
        _status = AuthStatus.signedIn;
        if (previous?.id != _user?.id && _user != null) {
          await _runSignInHooks(_user!);
          final route = await _takeStoredRoute();
          if (route != null && !_passwordRecovery) pendingNavigation.value = route;
        }
        break;
      case AuthChangeEvent.signedOut:
        _status = AuthStatus.signedOut;
        _passwordRecovery = false;
        await _runSignOutHooks();
        break;
      default:
        _status = _user != null ? AuthStatus.signedIn : AuthStatus.signedOut;
    }
    notifyListeners();
  }

  /// Register cleanup that must run when the user signs out (e.g. clearing
  /// cart/favourites held in memory). Hooks must not throw.
  void addSignOutHook(FutureOr<void> Function() hook) => _signOutHooks.add(hook);

  /// Register work to run once a user is signed in (e.g. merging a guest cart).
  void addSignInHook(FutureOr<void> Function(User user) hook) => _signInHooks.add(hook);

  Future<void> _runSignOutHooks() async {
    for (final hook in _signOutHooks) {
      try {
        await hook();
      } catch (_) {}
    }
  }

  Future<void> _runSignInHooks(User user) async {
    for (final hook in _signInHooks) {
      try {
        await hook(user);
      } catch (_) {}
    }
  }

  String? get _redirectUrl {
    if (SupabaseConfig.authRedirectUrl.isNotEmpty) return SupabaseConfig.authRedirectUrl;
    if (kIsWeb) return '${Uri.base.origin}/';
    return null;
  }

  /// Remember where to return the visitor after sign-in (survives the full
  /// page redirect used by Google OAuth and email links).
  Future<void> rememberReturnRoute(String? route) async {
    final prefs = await SharedPreferences.getInstance();
    if (route == null || route.isEmpty || route.startsWith('/sign-in')) {
      await prefs.remove(_postAuthRouteKey);
    } else {
      await prefs.setString(_postAuthRouteKey, route);
    }
  }

  Future<String?> _takeStoredRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final route = prefs.getString(_postAuthRouteKey);
    await prefs.remove(_postAuthRouteKey);
    return route;
  }

  Future<String?> takeReturnRoute() => _takeStoredRoute();

  AuthResult _notConfigured() =>
      const AuthResult.failure('Customer accounts are not available yet. Please try again later.');

  Future<AuthResult> signInWithPassword(String email, String password) async {
    if (!isConfigured) return _notConfigured();
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
      return const AuthResult.success('Welcome back.');
    } on AuthException catch (e) {
      return AuthResult.failure(_friendly(e));
    } catch (_) {
      return const AuthResult.failure('We could not sign you in. Check your connection and try again.');
    }
  }

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (!isConfigured) return _notConfigured();
    try {
      final res = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone': phone.trim(),
        },
        emailRedirectTo: _redirectUrl,
      );
      if (res.session == null) {
        return const AuthResult.success(
            'Account created. Please check your inbox and confirm your email address to finish signing in.');
      }
      return const AuthResult.success('Your account has been created.');
    } on AuthException catch (e) {
      return AuthResult.failure(_friendly(e));
    } catch (_) {
      return const AuthResult.failure('We could not create your account. Check your connection and try again.');
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    if (!isConfigured) return _notConfigured();
    try {
      final launched = await _auth.signInWithOAuth(OAuthProvider.google, redirectTo: _redirectUrl);
      if (!launched) return const AuthResult.failure('Google sign-in could not be started.');
      return const AuthResult.success('Redirecting to Google…');
    } on AuthException catch (e) {
      return AuthResult.failure(_friendly(e));
    } catch (_) {
      return const AuthResult.failure('Google sign-in is unavailable right now. Please try again.');
    }
  }

  /// Always reports success to avoid revealing whether an email is registered.
  Future<AuthResult> sendPasswordReset(String email) async {
    if (!isConfigured) return _notConfigured();
    try {
      await _auth.resetPasswordForEmail(email.trim(), redirectTo: _redirectUrl);
    } on AuthException catch (e) {
      if (e.statusCode == '429') return AuthResult.failure(_friendly(e));
    } catch (_) {
      return const AuthResult.failure('We could not send the reset email. Check your connection and try again.');
    }
    return const AuthResult.success(
        'If an account exists for that email, a password reset link is on its way. The link expires shortly.');
  }

  Future<AuthResult> updatePassword(String newPassword) async {
    if (!isConfigured) return _notConfigured();
    if (!isSignedIn) return const AuthResult.failure('Your reset link has expired. Please request a new one.');
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
      _passwordRecovery = false;
      notifyListeners();
      return const AuthResult.success('Your password has been updated.');
    } on AuthException catch (e) {
      return AuthResult.failure(_friendly(e));
    } catch (_) {
      return const AuthResult.failure('We could not update your password. Please try again.');
    }
  }

  /// Signs out, revoking this session's refresh token server-side, and clears
  /// all user-specific in-memory state via the registered hooks.
  Future<void> signOut() async {
    if (!isConfigured) return;
    try {
      await _auth.signOut();
    } catch (_) {
      // Even if the network call fails, clear local state below.
    }
    _user = null;
    _status = AuthStatus.signedOut;
    _passwordRecovery = false;
    await rememberReturnRoute(null);
    await _runSignOutHooks();
    notifyListeners();
  }

  void clearInitError() {
    _initError = null;
    notifyListeners();
  }

  static String _friendly(AuthException e) {
    final msg = e.message.toLowerCase();
    if (e.statusCode == '429' || msg.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('invalid login credentials')) return 'Incorrect email or password.';
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email address first — check your inbox for the confirmation link.';
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (msg.contains('password') && (msg.contains('weak') || msg.contains('at least'))) {
      return 'Please choose a stronger password.';
    }
    if (msg.contains('same password') || msg.contains('different from the old')) {
      return 'Your new password must be different from your current one.';
    }
    if (msg.contains('provider is not enabled') || msg.contains('unsupported provider')) {
      return 'Google sign-in has not been enabled yet.';
    }
    return 'Something went wrong. Please try again.';
  }

  @visibleForTesting
  void debugSetState({required AuthStatus status, User? user}) {
    _status = status;
    _user = user;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
