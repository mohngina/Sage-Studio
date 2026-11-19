import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/backend_errors.dart';
import '../../core/services/catalogue_lookup.dart';
import '../../core/services/portal_repositories.dart';
import '../../models/product_model.dart';

/// Manages saved/favourite products per authenticated customer.
///
/// Stores only base product IDs referencing `ProductData.sampleProducts`.
/// Automatically loads on sign-in and clears in-memory state on sign-out.
class FavouritesController extends ChangeNotifier {
  static final FavouritesController instance = FavouritesController._internal();
  factory FavouritesController() => instance;

  FavouritesController._internal() {
    AuthService.instance.addSignInHook((_) => load());
    AuthService.instance.addSignOutHook(_clearOnSignOut);
  }

  FavouritesBackend _backend = SupabaseFavouritesBackend();
  final Set<String> _ids = <String>{};
  bool _loading = false;
  String? _error;

  Set<String> get productIds => Set.unmodifiable(_ids);
  bool get isLoading => _loading;
  String? get error => _error;
  int get count => _ids.length;

  /// Resolves saved product IDs against the existing catalogue.
  List<Product> get products => _ids.map(CatalogueLookup.byId).whereType<Product>().toList(growable: false);

  static String _baseId(String productOrLineId) => CatalogueLookup.parseLineId(productOrLineId).productId;

  bool isFavourite(String productOrLineId) => _ids.contains(_baseId(productOrLineId));

  Future<void> load() async {
    if (!AuthService.instance.isSignedIn || !AuthService.instance.isConfigured) {
      _ids.clear();
      _error = null;
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final fetched = await _backend.fetch();
      _ids
        ..clear()
        ..addAll(fetched.where((id) => CatalogueLookup.byId(id) != null));
    } catch (e) {
      _error = BackendErrors.message(e, fallback: 'Could not load your saved items.');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Toggles favourite state for [productOrLineId]. Requires a signed-in user.
  /// Returns `null` on success or a user-facing error string on failure.
  Future<String?> toggle(String productOrLineId) async {
    if (!AuthService.instance.isSignedIn) {
      return 'Please sign in to save favourites.';
    }
    final id = _baseId(productOrLineId);
    if (CatalogueLookup.byId(id) == null) {
      return 'That product is no longer in the catalogue.';
    }
    final wasFav = _ids.contains(id);
    if (wasFav) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    _error = null;
    notifyListeners();

    if (!AuthService.instance.isConfigured) return null;

    try {
      if (wasFav) {
        await _backend.remove(id);
      } else {
        await _backend.add(id);
      }
      return null;
    } catch (e) {
      // Roll back optimistic change
      if (wasFav) {
        _ids.add(id);
      } else {
        _ids.remove(id);
      }
      final msg = BackendErrors.message(e, fallback: 'Could not update your favourites.');
      _error = msg;
      notifyListeners();
      return msg;
    }
  }

  Future<void> _clearOnSignOut() async {
    _ids.clear();
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @visibleForTesting
  void debugConfigure({FavouritesBackend? backend, Iterable<String>? seedIds}) {
    if (backend != null) _backend = backend;
    _ids.clear();
    if (seedIds != null) _ids.addAll(seedIds);
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
