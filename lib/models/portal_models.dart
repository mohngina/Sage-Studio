// Data classes for client-portal records stored in Supabase.
// Product details are never stored here; they are resolved from the
// existing catalogue via `CatalogueLookup`.

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
double _num(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
double? _numOrNull(dynamic v) => v == null ? null : _num(v);
String? _str(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

class CustomerProfile {
  final String id;
  final String? fullName;
  final String? phone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? region;
  final String? postalCode;
  final String? country;
  final String? avatarPath;

  const CustomerProfile({
    required this.id,
    this.fullName,
    this.phone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.region,
    this.postalCode,
    this.country,
    this.avatarPath,
  });

  factory CustomerProfile.fromMap(Map<String, dynamic> m) => CustomerProfile(
        id: m['id'] as String,
        fullName: _str(m['full_name']),
        phone: _str(m['phone']),
        addressLine1: _str(m['address_line1']),
        addressLine2: _str(m['address_line2']),
        city: _str(m['city']),
        region: _str(m['region']),
        postalCode: _str(m['postal_code']),
        country: _str(m['country']),
        avatarPath: _str(m['avatar_path']),
      );

  /// Only fields customers are permitted to edit (never `role`).
  Map<String, dynamic> toEditableMap() => {
        'full_name': fullName,
        'phone': phone,
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'region': region,
        'postal_code': postalCode,
        'country': country,
        'avatar_path': avatarPath,
      };

  bool get hasDeliveryAddress => (addressLine1 ?? '').isNotEmpty && (city ?? '').isNotEmpty;
}

enum ModerationStatus { pending, approved, rejected }

class ProductReview {
  final String id;
  final String productId;
  final int rating;
  final String? title;
  final String body;
  final String reviewerName;
  final ModerationStatus status;
  final bool verifiedPurchase;
  final DateTime? createdAt;

  const ProductReview({
    required this.id,
    required this.productId,
    required this.rating,
    this.title,
    required this.body,
    required this.reviewerName,
    required this.status,
    required this.verifiedPurchase,
    this.createdAt,
  });

  factory ProductReview.fromMap(Map<String, dynamic> m) => ProductReview(
        id: m['id'] as String,
        productId: m['product_id'] as String,
        rating: (m['rating'] as num).toInt(),
        title: _str(m['title']),
        body: (m['body'] ?? '').toString(),
        reviewerName: (m['reviewer_name'] ?? '').toString(),
        status: ModerationStatus.values.firstWhere(
          (s) => s.name == m['moderation_status'],
          orElse: () => ModerationStatus.pending,
        ),
        verifiedPurchase: m['verified_purchase'] == true,
        createdAt: _date(m['created_at']),
      );
}

class ReviewStats {
  final int count;
  final double average;
  const ReviewStats({required this.count, required this.average});
  static const empty = ReviewStats(count: 0, average: 0);
}

enum OrderStatus { pendingPayment, paid, failed, cancelled, fulfilled }

OrderStatus _orderStatus(String? s) => switch (s) {
      'paid' => OrderStatus.paid,
      'failed' => OrderStatus.failed,
      'cancelled' => OrderStatus.cancelled,
      'fulfilled' => OrderStatus.fulfilled,
      _ => OrderStatus.pendingPayment,
    };

class OrderLine {
  final String productId;
  final String variant;
  final String productCode;
  final String title;
  final String subtitle;
  final String imagePath;
  final double unitPriceKsh;
  final int quantity;
  final double lineTotalKsh;

  const OrderLine({
    required this.productId,
    required this.variant,
    required this.productCode,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.unitPriceKsh,
    required this.quantity,
    required this.lineTotalKsh,
  });

  factory OrderLine.fromMap(Map<String, dynamic> m) => OrderLine(
        productId: m['product_id'] as String,
        variant: (m['variant'] ?? 'standard').toString(),
        productCode: (m['product_code'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        subtitle: (m['subtitle'] ?? '').toString(),
        imagePath: (m['image_path'] ?? '').toString(),
        unitPriceKsh: _num(m['unit_price_ksh']),
        quantity: (m['quantity'] as num).toInt(),
        lineTotalKsh: _num(m['line_total_ksh']),
      );
}

class CustomerOrder {
  final String id;
  final String orderRef;
  final OrderStatus status;
  final double subtotalKsh;
  final double? deliveryFeeKsh;
  final double totalKsh;
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final Map<String, dynamic> deliveryAddress;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final List<OrderLine> lines;

  const CustomerOrder({
    required this.id,
    required this.orderRef,
    required this.status,
    required this.subtotalKsh,
    required this.deliveryFeeKsh,
    required this.totalKsh,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.deliveryAddress,
    this.notes,
    this.createdAt,
    this.paidAt,
    this.lines = const [],
  });

  /// Completed purchases are only those with server-verified payment.
  bool get isCompletedPurchase => status == OrderStatus.paid || status == OrderStatus.fulfilled;

  factory CustomerOrder.fromMap(Map<String, dynamic> m) => CustomerOrder(
        id: m['id'] as String,
        orderRef: (m['order_ref'] ?? '').toString(),
        status: _orderStatus(m['status'] as String?),
        subtotalKsh: _num(m['subtotal_ksh']),
        deliveryFeeKsh: _numOrNull(m['delivery_fee_ksh']),
        totalKsh: _num(m['total_ksh']),
        contactName: (m['contact_name'] ?? '').toString(),
        contactEmail: (m['contact_email'] ?? '').toString(),
        contactPhone: (m['contact_phone'] ?? '').toString(),
        deliveryAddress: (m['delivery_address'] is Map)
            ? Map<String, dynamic>.from(m['delivery_address'] as Map)
            : const <String, dynamic>{},
        notes: _str(m['notes']),
        createdAt: _date(m['created_at']),
        paidAt: _date(m['paid_at']),
        lines: ((m['order_items'] as List?) ?? const [])
            .map((e) => OrderLine.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class StoreSettings {
  final double? deliveryFeeKsh;
  final bool paymentsEnabled;
  const StoreSettings({this.deliveryFeeKsh, this.paymentsEnabled = false});

  factory StoreSettings.fromMap(Map<String, dynamic> m) => StoreSettings(
        deliveryFeeKsh: _numOrNull(m['delivery_fee_ksh']),
        paymentsEnabled: m['payments_enabled'] == true,
      );
}

/// Formats Kenyan Shilling amounts consistently with the existing site
/// (e.g. `KSH 111,360`).
String formatKsh(double amount) {
  final whole = amount.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
    buf.write(whole[i]);
  }
  return 'KSH $buf';
}

String formatDate(DateTime? d) {
  if (d == null) return '';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
