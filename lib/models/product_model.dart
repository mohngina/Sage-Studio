class Product {
  final String id;
  final String code;
  final String title;
  final String subtitle;
  final double priceKsh;
  final double? customPriceUsd;
  final double? coverOnlyPriceKsh;
  final double? coverOnlyPriceUsd;
  final String? priceKshLabel;
  final String? priceUsdLabel;
  final String mainImage;
  final String hoverImage;
  final String category;
  final String clan;
  final String description;
  final String size;
  final String length;
  final String cushionType;
  final String craftedIn;
  final List<String> makers;
  final List<String> materials;
  final String woodType;
  final String dimensions;
  final String availability;
  final List<String> details;
  final bool isNew;

  const Product({
    required this.id,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.priceKsh,
    this.customPriceUsd,
    this.coverOnlyPriceKsh,
    this.coverOnlyPriceUsd,
    this.priceKshLabel,
    this.priceUsdLabel,
    required this.mainImage,
    required this.hoverImage,
    required this.category,
    this.clan = 'The Bosibori Clan',
    this.description = '',
    this.size = 'Standard',
    this.length = 'Custom',
    this.cushionType = 'Pocket springs & density foam',
    this.craftedIn = '',
    this.makers = const [],
    this.materials = const [],
    this.woodType = '',
    this.dimensions = '',
    this.availability = 'Made to order. Custom finishes available.',
    this.details = const [],
    this.isNew = false,
  });

  double get price => priceKsh;
  double get priceUsd => customPriceUsd ?? (priceKsh / 130.0);

  Product withPillowOption(String option) {
    if (coverOnlyPriceKsh == null) return this;
    final isCoverOnly = option == 'Cover only';
    final selectedKsh = isCoverOnly ? coverOnlyPriceKsh! : priceKsh;
    final selectedUsd = isCoverOnly ? (coverOnlyPriceUsd ?? (coverOnlyPriceKsh! / 130.0).roundToDouble()) : priceUsd;
    return Product(
      id: '$id-${isCoverOnly ? "cover-only" : "cover-insert"}',
      code: code,
      title: title,
      subtitle: '$subtitle ($option)',
      priceKsh: selectedKsh,
      customPriceUsd: selectedUsd,
      coverOnlyPriceKsh: coverOnlyPriceKsh,
      coverOnlyPriceUsd: coverOnlyPriceUsd,
      mainImage: mainImage,
      hoverImage: hoverImage,
      category: category,
      clan: clan,
      description: description,
      size: size,
      length: length,
      cushionType: cushionType,
      craftedIn: craftedIn,
      makers: makers,
      materials: materials,
      woodType: woodType,
      dimensions: dimensions,
      availability: availability,
      details: details,
      isNew: isNew,
    );
  }
}

class ClanCategory {
  final String id;
  final String name;
  final String code;
  final String department;
  final String subtitle;
  final String description;
  final String heroImage;
  final List<Product> products;

  const ClanCategory({
    required this.id,
    required this.name,
    required this.code,
    required this.department,
    required this.subtitle,
    required this.description,
    required this.heroImage,
    required this.products,
  });
}
