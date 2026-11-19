import '../../data/product_data.dart';
import '../../models/product_model.dart';

/// Read-only lookups over the EXISTING catalogue in `ProductData`.
///
/// Supabase rows store only product ids (+ variant); everything displayed is
/// resolved here so no product data is duplicated or invented.
class CatalogueLookup {
  CatalogueLookup._();

  static const String standard = 'standard';
  static const String coverInsert = 'cover-insert';
  static const String coverOnly = 'cover-only';

  static final Map<String, Product> _byId = {for (final p in ProductData.sampleProducts) p.id: p};

  static Product? byId(String productId) => _byId[productId];

  static bool hasVariants(Product p) => p.coverOnlyPriceKsh != null;

  /// Splits a cart line id produced by `Product.withPillowOption` (e.g.
  /// `ss-sel-001-cover-only`) into its base product id and variant.
  static ({String productId, String variant}) parseLineId(String lineId) {
    for (final v in const [coverOnly, coverInsert]) {
      final suffix = '-$v';
      if (lineId.endsWith(suffix)) {
        final base = lineId.substring(0, lineId.length - suffix.length);
        if (_byId.containsKey(base)) return (productId: base, variant: v);
      }
    }
    return (productId: lineId, variant: standard);
  }

  /// Rebuilds the exact cart [Product] the existing UI would create for a
  /// product id + variant, or null if the product/variant no longer exists.
  static Product? resolve(String productId, String variant) {
    final base = _byId[productId];
    if (base == null) return null;
    if (hasVariants(base)) {
      if (variant == coverOnly) return base.withPillowOption('Cover only');
      if (variant == coverInsert || variant == standard) return base.withPillowOption('Cover & Insert');
      return null;
    }
    return variant == standard ? base : null;
  }

  static Product? resolveLineId(String lineId) {
    final parsed = parseLineId(lineId);
    return resolve(parsed.productId, parsed.variant);
  }

  /// The base (non-variant) product for any cart line id.
  static Product? baseForLineId(String lineId) => _byId[parseLineId(lineId).productId];
}
