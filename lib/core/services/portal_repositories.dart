import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/portal_models.dart';

/// Supabase data access for the client portal. Every query relies on RLS for
/// authorisation; the explicit `user_id` filters are for efficiency and to
/// satisfy PostgREST's "filter required" rule on deletes — not for security.

SupabaseClient get _db => Supabase.instance.client;

String _uid() {
  final id = _db.auth.currentUser?.id;
  if (id == null) throw const AuthException('Not signed in');
  return id;
}

Future<String> _requireUid() async {
  final session = _db.auth.currentSession;
  if (session != null && session.isExpired) {
    try {
      await _db.auth.refreshSession();
    } catch (_) {}
  }
  return _uid();
}

// ---------------------------------------------------------------------------
// Cart
// ---------------------------------------------------------------------------
class RemoteCartLine {
  final String productId;
  final String variant;
  final int quantity;
  const RemoteCartLine(this.productId, this.variant, this.quantity);
}

abstract class CartBackend {
  Future<List<RemoteCartLine>> fetch();
  Future<void> upsert(String productId, String variant, int quantity);
  Future<void> remove(String productId, String variant);
  Future<void> clear();
}

class SupabaseCartBackend implements CartBackend {
  @override
  Future<List<RemoteCartLine>> fetch() async {
    final rows =
        await _db.from('cart_items').select('product_id, variant, quantity').eq('user_id', _uid()).order('created_at');
    return rows
        .map((r) => RemoteCartLine(r['product_id'] as String, r['variant'] as String, (r['quantity'] as num).toInt()))
        .toList();
  }

  @override
  Future<void> upsert(String productId, String variant, int quantity) async {
    await _requireUid();
    await _db.from('cart_items').upsert(
      {'product_id': productId, 'variant': variant, 'quantity': quantity},
      onConflict: 'user_id,product_id,variant',
    );
  }

  @override
  Future<void> remove(String productId, String variant) async {
    await _db.from('cart_items').delete().eq('user_id', _uid()).eq('product_id', productId).eq('variant', variant);
  }

  @override
  Future<void> clear() async {
    await _db.from('cart_items').delete().eq('user_id', _uid());
  }
}

// ---------------------------------------------------------------------------
// Favourites
// ---------------------------------------------------------------------------
abstract class FavouritesBackend {
  Future<List<String>> fetch();
  Future<void> add(String productId);
  Future<void> remove(String productId);
}

class SupabaseFavouritesBackend implements FavouritesBackend {
  @override
  Future<List<String>> fetch() async {
    final rows =
        await _db.from('favourites').select('product_id').eq('user_id', _uid()).order('created_at', ascending: false);
    return rows.map((r) => r['product_id'] as String).toList();
  }

  @override
  Future<void> add(String productId) async {
    await _requireUid();
    try {
      await _db.from('favourites').insert({'product_id': productId});
    } on PostgrestException catch (e) {
      // 23505 = unique_violation (already in favourites) -> treat as success
      if (e.code != '23505') rethrow;
    }
  }

  @override
  Future<void> remove(String productId) async {
    await _db.from('favourites').delete().eq('user_id', _uid()).eq('product_id', productId);
  }
}

// ---------------------------------------------------------------------------
// Profile + avatar storage
// ---------------------------------------------------------------------------
class ProfileRepository {
  static const _bucket = 'avatars';

  Future<CustomerProfile> fetchOrCreate() async {
    final uid = await _requireUid();
    final meta = _db.auth.currentUser?.userMetadata ?? const {};
    final metaName = _nonEmpty(meta['full_name'] ?? meta['name']);
    final metaPhone = _nonEmpty(meta['phone']);
    final metaAvatar = _nonEmpty(meta['avatar_url'] ?? meta['picture']);

    final row = await _db.from('profiles').select().eq('id', uid).maybeSingle();
    if (row != null) {
      final existing = CustomerProfile.fromMap(row);
      // Only backfill missing fields from OAuth/signup metadata; never overwrite user edits.
      final updates = <String, dynamic>{};
      if ((existing.fullName ?? '').isEmpty && metaName != null) {
        updates['full_name'] = metaName;
      }
      if ((existing.phone ?? '').isEmpty && metaPhone != null) {
        updates['phone'] = metaPhone;
      }
      if ((existing.avatarPath ?? '').isEmpty && metaAvatar != null) {
        updates['avatar_path'] = metaAvatar;
      }
      if (updates.isNotEmpty) {
        final updated = await _db.from('profiles').update(updates).eq('id', uid).select().single();
        return CustomerProfile.fromMap(updated);
      }
      return existing;
    }

    // Normally created by the on_auth_user_created trigger; create defensively.
    final inserted = await _db
        .from('profiles')
        .insert({
          'id': uid,
          if (metaName != null) 'full_name': metaName,
          if (metaPhone != null) 'phone': metaPhone,
          if (metaAvatar != null) 'avatar_path': metaAvatar,
        })
        .select()
        .single();
    return CustomerProfile.fromMap(inserted);
  }

  static String? _nonEmpty(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  Future<CustomerProfile> save(CustomerProfile profile) async {
    final uid = _uid();
    final rows = await _db.from('profiles').update(profile.toEditableMap()).eq('id', uid).select();
    if (rows.isEmpty) {
      final inserted = await _db.from('profiles').insert({'id': uid, ...profile.toEditableMap()}).select().single();
      return CustomerProfile.fromMap(inserted);
    }
    return CustomerProfile.fromMap(rows.first);
  }

  /// Uploads to the private bucket under `<uid>/`, returning the object path.
  Future<String> uploadAvatar(XFile file) async {
    final uid = _uid();
    final bytes = await file.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      throw const StorageException('Payload too large', statusCode: '413');
    }
    final name = file.name.toLowerCase();
    final ext = name.endsWith('.png') ? 'png' : (name.endsWith('.webp') ? 'webp' : 'jpg');
    final contentType = switch (ext) { 'png' => 'image/png', 'webp' => 'image/webp', _ => 'image/jpeg' };
    final path = '$uid/avatar-${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage
        .from(_bucket)
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: contentType, upsert: true));
    return path;
  }

  Future<void> deleteAvatar(String path) async {
    if (!path.startsWith('${_uid()}/')) return;
    await _db.storage.from(_bucket).remove([path]);
  }

  Future<String?> signedAvatarUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('https://') || path.startsWith('http://')) {
      return path;
    }
    return _db.storage.from(_bucket).createSignedUrl(path, 60 * 60);
  }
}

// ---------------------------------------------------------------------------
// Reviews
// ---------------------------------------------------------------------------
class ReviewsRepository {
  static const _publicColumns = 'id, product_id, rating, title, body, reviewer_name, '
      'verified_purchase, created_at, moderation_status';

  Future<List<ProductReview>> approvedForProduct(String productId, {int limit = 30}) async {
    final rows = await _db
        .from('reviews')
        .select(_publicColumns)
        .eq('product_id', productId)
        .eq('moderation_status', 'approved')
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(ProductReview.fromMap).toList();
  }

  Future<List<ProductReview>> latestApproved({int limit = 6}) async {
    final rows = await _db
        .from('reviews')
        .select(_publicColumns)
        .eq('moderation_status', 'approved')
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(ProductReview.fromMap).toList();
  }

  Future<ReviewStats> statsForProduct(String productId) async {
    final row = await _db
        .from('product_review_stats')
        .select('review_count, average_rating')
        .eq('product_id', productId)
        .maybeSingle();
    if (row == null) return ReviewStats.empty;
    return ReviewStats(
      count: (row['review_count'] as num).toInt(),
      average: (row['average_rating'] as num).toDouble(),
    );
  }

  Future<List<ProductReview>> mine() async {
    final rows =
        await _db.from('reviews').select(_publicColumns).eq('user_id', _uid()).order('created_at', ascending: false);
    return rows.map(ProductReview.fromMap).toList();
  }

  Future<ProductReview?> mineForProduct(String productId) async {
    final row = await _db
        .from('reviews')
        .select(_publicColumns)
        .eq('user_id', _uid())
        .eq('product_id', productId)
        .maybeSingle();
    return row == null ? null : ProductReview.fromMap(row);
  }

  /// Creates or updates the caller's review. The database forces new/edited
  /// reviews back to `pending` moderation.
  Future<ProductReview> submit({
    required String productId,
    required int rating,
    String? title,
    required String body,
    required String reviewerName,
    String? existingId,
  }) async {
    final payload = {
      'rating': rating,
      'title': (title == null || title.trim().isEmpty) ? null : title.trim(),
      'body': body.trim(),
      'reviewer_name': reviewerName.trim(),
    };
    final uid = await _requireUid();
    Map<String, dynamic> row;
    if (existingId != null) {
      row = await _db
          .from('reviews')
          .update(payload)
          .eq('id', existingId)
          .eq('user_id', uid)
          .select(_publicColumns)
          .single();
    } else {
      try {
        // Omit user_id from insert payload so PostgreSQL uses `default auth.uid()`
        // and matches the column-level GRANT INSERT (product_id, rating, title, body, reviewer_name).
        row = await _db.from('reviews').insert({'product_id': productId, ...payload}).select(_publicColumns).single();
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          // User already reviewed this product; update their existing review row.
          row = await _db
              .from('reviews')
              .update(payload)
              .eq('user_id', uid)
              .eq('product_id', productId)
              .select(_publicColumns)
              .single();
        } else {
          rethrow;
        }
      }
    }
    return ProductReview.fromMap(row);
  }

  Future<void> delete(String reviewId) async {
    await _db.from('reviews').delete().eq('id', reviewId).eq('user_id', _uid());
  }
}

// ---------------------------------------------------------------------------
// Orders
// ---------------------------------------------------------------------------
class OrdersRepository {
  Future<StoreSettings> storeSettings() async {
    final row = await _db.from('store_settings').select('delivery_fee_ksh, payments_enabled').eq('id', 1).maybeSingle();
    return row == null ? const StoreSettings() : StoreSettings.fromMap(row);
  }

  /// Server prices for the given product ids (for pre-checkout verification).
  Future<Map<String, ({double price, double? coverOnly, bool active})>> serverPrices(Iterable<String> ids) async {
    final list = ids.toSet().toList();
    if (list.isEmpty) return {};
    final rows = await _db
        .from('catalogue_products')
        .select('product_id, price_ksh, cover_only_price_ksh, active')
        .inFilter('product_id', list);
    return {
      for (final r in rows)
        r['product_id'] as String: (
          price: (r['price_ksh'] as num).toDouble(),
          coverOnly: (r['cover_only_price_ksh'] as num?)?.toDouble(),
          active: r['active'] == true,
        ),
    };
  }

  Future<CustomerOrder> createPendingOrder({
    required String idempotencyKey,
    required String contactName,
    required String contactEmail,
    required String contactPhone,
    required Map<String, dynamic> deliveryAddress,
    String? notes,
  }) async {
    _uid();
    final row = await _db.rpc('create_pending_order', params: {
      'p_idempotency_key': idempotencyKey,
      'p_contact_name': contactName,
      'p_contact_email': contactEmail,
      'p_contact_phone': contactPhone,
      'p_delivery_address': deliveryAddress,
      'p_notes': notes,
    });
    final map = Map<String, dynamic>.from(row as Map);
    return fetchOrder(map['id'] as String);
  }

  Future<CustomerOrder> fetchOrder(String orderId) async {
    final row = await _db.from('orders').select('*, order_items(*)').eq('id', orderId).single();
    return CustomerOrder.fromMap(row);
  }

  Future<List<CustomerOrder>> myOrders() async {
    final rows = await _db
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', _uid())
        .order('created_at', ascending: false);
    return rows.map(CustomerOrder.fromMap).toList();
  }

  Future<void> cancel(String orderId) async {
    _uid();
    await _db.rpc('cancel_pending_order', params: {'p_order_id': orderId});
  }
}
