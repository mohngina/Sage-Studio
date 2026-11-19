import '../../models/product_model.dart';

/// Shared helper to distinguish Sage Select products (which will use a live
/// payment provider checkout) from studio/bespoke clan products (which use the
/// Word `.docx` order dispatch flow).
bool isSageSelectProduct(Product product) =>
    product.clan.trim().toLowerCase() == 'sage select' || product.id.toLowerCase().startsWith('ss-sel-');
