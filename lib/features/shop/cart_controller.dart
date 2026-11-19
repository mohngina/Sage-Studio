import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/backend_errors.dart';
import '../../core/services/catalogue_lookup.dart';
import '../../core/services/portal_repositories.dart';
import '../../models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  String get baseProductId => CatalogueLookup.parseLineId(product.id).productId;
  String get variant => CatalogueLookup.parseLineId(product.id).variant;
  double get lineTotal => product.price * quantity;
}

class CartController extends ChangeNotifier {
  static final CartController instance = CartController._internal();
  factory CartController() => instance;

  CartController._internal() {
    AuthService.instance.addSignInHook((_) => _onSignedIn());
    AuthService.instance.addSignOutHook(_onSignedOut);
  }

  static const String _guestStorageKey = 'sage_guest_cart_v1';
  static const int maxQuantityPerLine = 99;

  CartBackend _backend = SupabaseCartBackend();
  final List<CartItem> _items = [];
  bool _loading = false;
  String? _syncError;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  String? get syncError => _syncError;

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  bool contains(String productId) => _items.any((item) => item.product.id == productId);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));

  bool get _useRemote => AuthService.instance.isSignedIn && AuthService.instance.isConfigured;

  /// Loads persisted cart state on startup (guest local storage when signed out,
  /// or remote cart when already signed in).
  Future<void> initialise() async {
    if (_useRemote) {
      await _onSignedIn();
    } else {
      await _loadGuestCart();
    }
  }

  void addToCart(Product product, {int quantity = 1}) {
    if (quantity <= 0) return;
    final canonical = CatalogueLookup.resolveLineId(product.id) ?? product;
    final existingIndex = _items.indexWhere((item) => item.product.id == canonical.id);
    int newQty;
    if (existingIndex >= 0) {
      newQty = (_items[existingIndex].quantity + quantity).clamp(1, maxQuantityPerLine);
      _items[existingIndex].quantity = newQty;
    } else {
      newQty = quantity.clamp(1, maxQuantityPerLine);
      _items.add(CartItem(product: canonical, quantity: newQty));
    }
    _syncError = null;
    notifyListeners();
    unawaited(_persistLineUpsert(canonical.id, newQty));
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _syncError = null;
    notifyListeners();
    unawaited(_persistLineRemove(productId));
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final clamped = quantity.clamp(1, maxQuantityPerLine);
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = clamped;
      _syncError = null;
      notifyListeners();
      unawaited(_persistLineUpsert(productId, clamped));
    }
  }

  void clearCart() {
    _items.clear();
    _syncError = null;
    notifyListeners();
    unawaited(_persistClear());
  }

  /// Clears in-memory items after the server has already converted the cart
  /// into an order (no remote delete call needed).
  void clearLocalAfterOrder() {
    _items.clear();
    _syncError = null;
    notifyListeners();
    unawaited(_saveGuestCart());
  }

  /// Re-validates all items in the cart against `CatalogueLookup`, dropping any
  /// product that no longer exists and refreshing prices from the canonical
  /// catalogue definition.
  void revalidateAgainstCatalogue() {
    final refreshed = <CartItem>[];
    for (final item in _items) {
      final canonical = CatalogueLookup.resolveLineId(item.product.id);
      if (canonical != null) {
        refreshed.add(CartItem(
          product: canonical,
          quantity: item.quantity.clamp(1, maxQuantityPerLine),
        ));
      }
    }
    _items
      ..clear()
      ..addAll(refreshed);
    notifyListeners();
  }

  Future<void> reloadFromServer() async {
    if (!_useRemote) return;
    _loading = true;
    _syncError = null;
    notifyListeners();
    try {
      final remote = await _backend.fetch();
      _items.clear();
      for (final line in remote) {
        final resolved = CatalogueLookup.resolve(line.productId, line.variant);
        if (resolved != null) {
          _items.add(CartItem(
            product: resolved,
            quantity: line.quantity.clamp(1, maxQuantityPerLine),
          ));
        }
      }
    } catch (e) {
      _syncError = BackendErrors.message(e, fallback: 'Could not sync your cart.');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _onSignedIn() async {
    if (!AuthService.instance.isConfigured) return;
    _loading = true;
    _syncError = null;
    notifyListeners();
    try {
      // Snapshot any guest items before fetching the user's account cart.
      final guestSnapshot = List<CartItem>.from(_items);
      final remote = await _backend.fetch();
      final merged = <String, CartItem>{};

      for (final line in remote) {
        final resolved = CatalogueLookup.resolve(line.productId, line.variant);
        if (resolved != null) {
          merged[resolved.id] = CartItem(
            product: resolved,
            quantity: line.quantity.clamp(1, maxQuantityPerLine),
          );
        }
      }

      final toUpsert = <CartItem>[];
      for (final guest in guestSnapshot) {
        final canonical = CatalogueLookup.resolveLineId(guest.product.id);
        if (canonical == null) continue;
        final existing = merged[canonical.id];
        final combinedQty = ((existing?.quantity ?? 0) + guest.quantity).clamp(1, maxQuantityPerLine);
        final mergedItem = CartItem(product: canonical, quantity: combinedQty);
        merged[canonical.id] = mergedItem;
        toUpsert.add(mergedItem);
      }

      _items
        ..clear()
        ..addAll(merged.values);

      for (final item in toUpsert) {
        final parsed = CatalogueLookup.parseLineId(item.product.id);
        await _backend.upsert(parsed.productId, parsed.variant, item.quantity);
      }
      await _clearGuestStorage();
    } catch (e) {
      _syncError = BackendErrors.message(e, fallback: 'Could not sync your cart.');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _onSignedOut() async {
    _items.clear();
    _loading = false;
    _syncError = null;
    await _clearGuestStorage();
    notifyListeners();
  }

  Future<void> _persistLineUpsert(String lineId, int quantity) async {
    if (_useRemote) {
      final parsed = CatalogueLookup.parseLineId(lineId);
      try {
        await _backend.upsert(parsed.productId, parsed.variant, quantity);
      } catch (e) {
        _syncError = BackendErrors.message(e, fallback: 'Could not save cart update.');
        notifyListeners();
      }
    } else {
      await _saveGuestCart();
    }
  }

  Future<void> _persistLineRemove(String lineId) async {
    if (_useRemote) {
      final parsed = CatalogueLookup.parseLineId(lineId);
      try {
        await _backend.remove(parsed.productId, parsed.variant);
      } catch (e) {
        _syncError = BackendErrors.message(e, fallback: 'Could not remove item.');
        notifyListeners();
      }
    } else {
      await _saveGuestCart();
    }
  }

  Future<void> _persistClear() async {
    if (_useRemote) {
      try {
        await _backend.clear();
      } catch (e) {
        _syncError = BackendErrors.message(e, fallback: 'Could not clear cart.');
        notifyListeners();
      }
    } else {
      await _clearGuestStorage();
    }
  }

  Future<void> _loadGuestCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_guestStorageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _items.clear();
      for (final entry in decoded) {
        if (entry is Map) {
          final id = entry['id']?.toString() ?? '';
          final qty = (entry['qty'] is num) ? (entry['qty'] as num).toInt() : 1;
          final resolved = CatalogueLookup.resolveLineId(id);
          if (resolved != null && qty > 0) {
            _items.add(CartItem(
              product: resolved,
              quantity: qty.clamp(1, maxQuantityPerLine),
            ));
          }
        }
      }
      notifyListeners();
    } catch (_) {
      // Ignore corrupt local storage
    }
  }

  Future<void> _saveGuestCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _items.map((i) => {'id': i.product.id, 'qty': i.quantity}).toList(growable: false);
      await prefs.setString(_guestStorageKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _clearGuestStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestStorageKey);
    } catch (_) {}
  }

  @visibleForTesting
  void debugConfigure({CartBackend? backend}) {
    if (backend != null) _backend = backend;
    _items.clear();
    _syncError = null;
    _loading = false;
    notifyListeners();
  }
}
