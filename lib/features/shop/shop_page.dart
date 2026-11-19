import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/thin_rule.dart';
import '../../core/widgets/hover_image.dart';
import '../../core/widgets/info_centre_modal.dart';
import '../../core/widgets/sage_button.dart';
import '../../data/product_data.dart';
import '../../models/product_model.dart';
import 'cart_controller.dart';
import 'product_detail_page.dart';
import 'widgets/cart_drawer.dart';
import 'widgets/favourite_button.dart';

class ShopPage extends StatefulWidget {
  final Function(String) onNavigate;
  final String? initialClanName;
  final String? initialProductId;

  const ShopPage({
    super.key,
    required this.onNavigate,
    this.initialClanName,
    this.initialProductId,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String _selectedCategory = 'ALL';
  ClanCategory? _selectedClan;
  Product? _selectedProductForDetail;
  String _selectedOptionForDetail = 'Cover & Insert';

  @override
  void initState() {
    super.initState();
    _applyInitialClan();
  }

  @override
  void didUpdateWidget(covariant ShopPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialClanName != widget.initialClanName || oldWidget.initialProductId != widget.initialProductId) {
      _applyInitialClan();
    }
  }

  void _applyInitialClan() {
    final pid = widget.initialProductId?.trim().toLowerCase();
    if (pid != null && pid.isNotEmpty) {
      for (final p in ProductData.sampleProducts) {
        if (p.id.toLowerCase() == pid) {
          _selectedProductForDetail = p;
          return;
        }
      }
    }
    final target = widget.initialClanName?.trim().toLowerCase();
    if (target == null || target.isEmpty) {
      _selectedClan = null;
      return;
    }
    for (final clan in ProductData.sampleClans) {
      if (clan.name.toLowerCase() == target || clan.id.toLowerCase() == target) {
        _selectedClan = clan;
        _selectedProductForDetail = null;
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Detailed View when a product is selected
    if (_selectedProductForDetail != null) {
      return ProductDetailPage(
        product: _selectedProductForDetail!,
        initialOption: _selectedOptionForDetail,
        onNavigate: (route) {
          if (route == '/shop' || route == 'back') {
            setState(() => _selectedProductForDetail = null);
          } else {
            widget.onNavigate(route);
          }
        },
        onSelectProduct: (product) {
          setState(() {
            _selectedProductForDetail = product;
            _selectedOptionForDetail = 'Cover & Insert';
          });
        },
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isMobile = screenWidth < 768;
    final isCompact = screenWidth < 600;
    const categories = ['ALL', 'SOFAS', 'DINING & SEATING', 'OBJECTS & MIRRORS'];

    // 2. Clan View when a Clan Category is selected
    if (_selectedClan != null) {
      return _buildClanView(context, screenWidth, isMobile);
    }

    // 3. Top-level Shop Catalogue (Categories view - 2 Clans per Row)
    const clans = ProductData.sampleClans;
    final filteredClans = _selectedCategory == 'ALL'
        ? clans
        : clans.where((c) => c.department.toUpperCase().contains(_selectedCategory.split(' ')[0])).toList();

    final horizontalPadding =
        isCompact ? DesignTokens.mobilePadding : (screenWidth < 1100 ? DesignTokens.xl : DesignTokens.desktopPadding);
    final gridSpacing = screenWidth < 900 ? DesignTokens.lg : DesignTokens.xxl;
    // Two clans per row on screens >= 640px; single column on very small mobile screens
    final clanCrossAxisCount = screenWidth < 640 ? 1 : 2;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: isMobile ? DesignTokens.xl : DesignTokens.xxl,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: DesignTokens.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: DesignTokens.md,
                  runSpacing: DesignTokens.md,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? screenWidth - (horizontalPadding * 2) : screenWidth * 0.65,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SOFAS & FURNITURE',
                            style: AppTypography.heroTitle().copyWith(
                              fontSize: isCompact ? 32 : (isMobile ? 40 : 56),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'NAIROBI STUDIO CATALOGUE • CONTEMPORARY AFRICAN PROPORTIONS',
                            style: AppTypography.labelUppercase(),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: DesignTokens.oliveAccent),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => InfoCentreModal.show(context),
                      child: Text(
                        'INFO CENTRE / TERMS',
                        style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.xl),
                const ThinRule(),
                const SizedBox(height: DesignTokens.xl),

                // Category Filter Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: DesignTokens.xl),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat,
                                style: AppTypography.labelUppercase(
                                  color: isSelected ? DesignTokens.burntOrange : DesignTokens.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 2,
                                width: isSelected ? 32 : 0,
                                color: DesignTokens.burntOrange,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: DesignTokens.xxl),

                // Catalogue Grid: 2 Clans per Row
                if (filteredClans.isNotEmpty) ...[
                  Text(
                    'STUDIO CLANS & CATEGORIES',
                    style: AppTypography.labelUppercase(color: DesignTokens.textMuted).copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: DesignTokens.md),
                  _buildResponsiveClanGrid(
                    clans: filteredClans,
                    columns: clanCrossAxisCount,
                    spacing: gridSpacing,
                    screenWidth: screenWidth,
                  ),
                ] else ...[
                  // Upcoming Releases State for categories without clans yet
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DesignTokens.xxl),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F8F6),
                      border: Border.all(color: DesignTokens.borderLight),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.architecture_outlined, size: 48, color: DesignTokens.oliveAccent),
                        const SizedBox(height: DesignTokens.md),
                        Text('STUDIO COMMISSIONS IN PROGRESS', style: AppTypography.subTitle()),
                        const SizedBox(height: DesignTokens.sm),
                        Text(
                          'New collections for $_selectedCategory are currently being handcrafted in our Nairobi studio workshop.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium(),
                        ),
                        const SizedBox(height: DesignTokens.xl),
                        SageButton(
                          text: 'EXPLORE THE BOSIBORI CLAN (SOFAS)',
                          style: SageButtonStyle.burntOrange,
                          onTap: () => setState(() {
                            _selectedCategory = 'SOFAS';
                            _selectedClan = ProductData.bosiboriClan;
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a responsive multi-column layout (2 clans per row) where cards in the
  /// same row match height cleanly and never overflow vertically.
  Widget _buildResponsiveClanGrid({
    required List<ClanCategory> clans,
    required int columns,
    required double spacing,
    required double screenWidth,
  }) {
    final rows = <Widget>[];
    for (int i = 0; i < clans.length; i += columns) {
      final rowItems = clans.sublist(i, (i + columns > clans.length) ? clans.length : i + columns);
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + columns < clans.length ? spacing : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int j = 0; j < columns; j++) ...[
                  if (j > 0) SizedBox(width: spacing),
                  Expanded(
                    child: j < rowItems.length
                        ? _ClanCategoryCard(
                            clan: rowItems[j],
                            screenWidth: screenWidth,
                            onTap: () => setState(() => _selectedClan = rowItems[j]),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  // Clan View: Lists the individual models within the clan, using MediaQuery to adapt to screen size
  Widget _buildClanView(BuildContext context, double screenWidth, bool isMobile) {
    final clan = _selectedClan!;
    final isCompact = screenWidth < 600;
    final horizontalPadding =
        isCompact ? DesignTokens.mobilePadding : (screenWidth < 1100 ? DesignTokens.xl : DesignTokens.desktopPadding);
    final gridSpacing = screenWidth < 900 ? DesignTokens.lg : DesignTokens.xxl;
    final productColumns = screenWidth < 680 ? 1 : (screenWidth >= 1360 && clan.products.length >= 3 ? 3 : 2);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: isMobile ? DesignTokens.xl : DesignTokens.xxl,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: DesignTokens.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumbs & Back
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: DesignTokens.md,
                  runSpacing: DesignTokens.sm,
                  children: [
                    SageButton(
                      text: '← BACK TO CATALOGUE',
                      style: SageButtonStyle.textLink,
                      onTap: () => setState(() => _selectedClan = null),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.info_outline, size: 16, color: DesignTokens.oliveAccent),
                      label: Text(
                        'INFO CENTRE / TERMS',
                        style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent),
                      ),
                      onPressed: () => InfoCentreModal.show(context),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.sm),
                Text(
                  'CATALOGUE / ${clan.department} / ${clan.name.toUpperCase()}',
                  style: AppTypography.labelUppercase(color: DesignTokens.textMuted).copyWith(fontSize: 10),
                ),
                const SizedBox(height: DesignTokens.xl),

                // Clan Header
                Text(
                  clan.name.toUpperCase(),
                  style: AppTypography.heroTitle().copyWith(
                    fontSize: isCompact ? 32 : (isMobile ? 40 : 52),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  clan.subtitle.toUpperCase(),
                  style: AppTypography.labelUppercase(color: DesignTokens.burntOrange),
                ),
                const SizedBox(height: DesignTokens.md),
                Text(
                  clan.description,
                  style: AppTypography.bodyLarge(color: DesignTokens.textPrimary),
                ),
                const SizedBox(height: DesignTokens.xl),
                const ThinRule(),
                const SizedBox(height: DesignTokens.xl),

                // Models Grid using MediaQuery-driven rows to prevent any card overflow
                _buildResponsiveProductsGrid(
                  products: clan.products,
                  columns: productColumns,
                  spacing: gridSpacing,
                  screenWidth: screenWidth,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveProductsGrid({
    required List<Product> products,
    required int columns,
    required double spacing,
    required double screenWidth,
  }) {
    final rows = <Widget>[];
    for (int i = 0; i < products.length; i += columns) {
      final rowItems = products.sublist(i, (i + columns > products.length) ? products.length : i + columns);
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + columns < products.length ? spacing : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int j = 0; j < columns; j++) ...[
                  if (j > 0) SizedBox(width: spacing),
                  Expanded(
                    child: j < rowItems.length
                        ? _SofaModelCard(
                            product: rowItems[j],
                            screenWidth: screenWidth,
                            columns: columns,
                            onNavigate: widget.onNavigate,
                            onTapWithOption: (selectedOpt) => setState(() {
                              _selectedProductForDetail = rowItems[j];
                              _selectedOptionForDetail = selectedOpt;
                            }),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

// Category / Clan Showcase Card on Shop Page (Designed for 2-column grid layout)
class _ClanCategoryCard extends StatefulWidget {
  final ClanCategory clan;
  final double screenWidth;
  final VoidCallback onTap;

  const _ClanCategoryCard({
    required this.clan,
    required this.screenWidth,
    required this.onTap,
  });

  @override
  State<_ClanCategoryCard> createState() => _ClanCategoryCardState();
}

class _ClanCategoryCardState extends State<_ClanCategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final clan = widget.clan;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactCard = screenWidth < 960;
    final pricesKsh = clan.products.map((p) => p.priceKsh).toList();
    final pricesUsd = clan.products.map((p) => p.priceUsd).toList();
    final minPriceKsh = pricesKsh.isEmpty ? 0.0 : pricesKsh.reduce((a, b) => a < b ? a : b);
    final minPriceUsd = pricesUsd.isEmpty ? 0.0 : pricesUsd.reduce((a, b) => a < b ? a : b);
    final modelCount = clan.products.length;

    final cardPadding = isCompactCard ? DesignTokens.lg : DesignTokens.xl;
    final titleFontSize = screenWidth < 640 ? 26.0 : (isCompactCard ? 24.0 : 30.0);
    final imageAspectRatio = screenWidth < 640 ? 16 / 10 : 16 / 10;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF9F8F6) : Colors.white,
            border: Border.all(
              color: _isHovered ? DesignTokens.burntOrange.withValues(alpha: 0.5) : DesignTokens.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HoverImage(imageUrl: clan.heroImage, aspectRatio: imageAspectRatio),
                  Padding(
                    padding: EdgeInsets.fromLTRB(cardPadding, cardPadding, cardPadding, DesignTokens.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          color: DesignTokens.oliveAccent.withValues(alpha: 0.12),
                          child: Text(
                            'CLAN CATEGORY • ${clan.department}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent).copyWith(fontSize: 10),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.sm),
                        Text(
                          clan.name,
                          style: AppTypography.sectionTitle().copyWith(fontSize: titleFontSize),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          clan.subtitle,
                          style: AppTypography.bodyMedium(color: DesignTokens.burntOrange).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isCompactCard ? 13 : 14,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.sm),
                        Text(
                          clan.description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall(color: DesignTokens.textPrimary).copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(cardPadding, 0, cardPadding, cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ThinRule(),
                    const SizedBox(height: DesignTokens.md),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: DesignTokens.sm,
                      runSpacing: DesignTokens.xs,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRICING',
                              style: AppTypography.labelUppercase(color: DesignTokens.textMuted).copyWith(fontSize: 9),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'From KSH ${minPriceKsh.toStringAsFixed(0)} (USD ${minPriceUsd.toStringAsFixed(0)})',
                              style: AppTypography.cardTitle().copyWith(fontSize: isCompactCard ? 14 : 15),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'EXPLORE ($modelCount ${modelCount == 1 ? "MODEL" : "MODELS"})',
                              style:
                                  AppTypography.labelUppercase(color: DesignTokens.burntOrange).copyWith(fontSize: 11),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward, color: DesignTokens.burntOrange, size: 15),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Product Model Card inside Clan View — MediaQuery-responsive & overflow-safe
class _SofaModelCard extends StatefulWidget {
  final Product product;
  final double screenWidth;
  final int columns;
  final Function(String) onNavigate;
  final ValueChanged<String> onTapWithOption;

  const _SofaModelCard({
    required this.product,
    required this.screenWidth,
    required this.columns,
    required this.onNavigate,
    required this.onTapWithOption,
  });

  @override
  State<_SofaModelCard> createState() => _SofaModelCardState();
}

class _SofaModelCardState extends State<_SofaModelCard> {
  bool _isHovered = false;
  String _selectedOption = 'Cover & Insert';

  @override
  void didUpdateWidget(covariant _SofaModelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _selectedOption = 'Cover & Insert';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final hasPillowOptions = p.coverOnlyPriceKsh != null;
    final activePriceKsh = hasPillowOptions && _selectedOption == 'Cover only' ? p.coverOnlyPriceKsh! : p.priceKsh;
    final mediaSize = MediaQuery.of(context).size;
    final screenWidth = mediaSize.width;
    final isCompactCard = screenWidth < 960 || widget.columns >= 3;
    final cardPadding = isCompactCard ? DesignTokens.md : DesignTokens.lg;
    final titleFontSize = isCompactCard ? 19.0 : 22.0;
    final imageAspectRatio = screenWidth < 680 ? 16 / 11 : 4 / 3;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onTapWithOption(_selectedOption),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _isHovered ? DesignTokens.burntOrange.withValues(alpha: 0.5) : DesignTokens.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      HoverImage(
                        imageUrl: _isHovered ? p.hoverImage : p.mainImage,
                        aspectRatio: imageAspectRatio,
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          color: Colors.black.withValues(alpha: 0.8),
                          child: Text(
                            'CODE: ${p.code}',
                            style: AppTypography.labelUppercase(color: Colors.white).copyWith(fontSize: 10),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: FavouriteButton(
                          productId: p.id,
                          productTitle: p.title,
                          returnRoute: '/shop?product=${p.id}',
                          onNavigate: widget.onNavigate,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(cardPadding, cardPadding, cardPadding, DesignTokens.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.title,
                                    style: AppTypography.cardTitle().copyWith(fontSize: titleFontSize),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.subtitle,
                                    style: AppTypography.bodyMedium(color: DesignTokens.oliveAccent).copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: DesignTokens.sm),
                            Flexible(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'KSH ${p.priceKshLabel ?? p.priceKsh.toStringAsFixed(0)}',
                                      maxLines: 1,
                                      textAlign: TextAlign.end,
                                      style: AppTypography.cardTitle(color: DesignTokens.burntOrange).copyWith(
                                        fontSize: (p.priceKshLabel != null && p.priceKshLabel!.length > 15)
                                            ? 12
                                            : (isCompactCard ? 16 : 18),
                                      ),
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      p.priceUsdLabel != null
                                          ? (p.priceUsdLabel!.startsWith('Sale') ||
                                                  p.priceUsdLabel!.startsWith('Discount')
                                              ? p.priceUsdLabel!
                                              : 'USD ${p.priceUsdLabel}')
                                          : 'USD ${p.priceUsd.toStringAsFixed(0)}',
                                      maxLines: 1,
                                      textAlign: TextAlign.end,
                                      style: AppTypography.bodySmall(color: DesignTokens.textMuted).copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: p.priceUsdLabel != null ? 10 : 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (hasPillowOptions) ...[
                          const SizedBox(height: DesignTokens.sm),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F8F6),
                                    border: Border.all(color: DesignTokens.burntOrange.withValues(alpha: 0.5)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedOption,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down,
                                          size: 18, color: DesignTokens.burntOrange),
                                      style: AppTypography.bodySmall(color: DesignTokens.textPrimary).copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'Cover & Insert',
                                          child: Text(
                                            'Cover & Insert — KSH ${p.priceKsh.toStringAsFixed(0)}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Cover only',
                                          child: Text(
                                            'Cover only — KSH ${p.coverOnlyPriceKsh!.toStringAsFixed(0)}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedOption = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: DesignTokens.sm),
                              ListenableBuilder(
                                listenable: CartController.instance,
                                builder: (context, _) {
                                  final cartItem = p.withPillowOption(_selectedOption);
                                  final inCart = CartController.instance.contains(cartItem.id);
                                  return InkWell(
                                    onTap: () {
                                      if (inCart) {
                                        CartController.instance.removeFromCart(cartItem.id);
                                      } else {
                                        CartController.instance.addToCart(cartItem, quantity: 1);
                                      }
                                    },
                                    child: Container(
                                      height: 36,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      color: inCart ? DesignTokens.oliveAccent : DesignTokens.burntOrange,
                                      alignment: Alignment.center,
                                      child: Text(
                                        inCart ? 'ADDED TO CART' : 'ADD • KSH ${activePriceKsh.toStringAsFixed(0)}',
                                        style: AppTypography.labelUppercase(color: Colors.white).copyWith(fontSize: 10),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: DesignTokens.md),
                        const ThinRule(),
                        const SizedBox(height: DesignTokens.sm),
                        if (p.makers.isNotEmpty) ...[
                          Text(
                            'The Makers: ${p.makers.map((m) => m.split(' - ')[0]).join(', ')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall(color: DesignTokens.textMuted),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          'Materials: ${p.materials.join(', ')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall(color: DesignTokens.textMuted),
                        ),
                        if (p.woodType.isNotEmpty || p.dimensions.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (p.woodType.isNotEmpty) 'Wood: ${p.woodType}',
                              if (p.dimensions.isNotEmpty) 'Size: ${p.dimensions.replaceAll('\n', ' | ')}',
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall(color: DesignTokens.oliveAccent).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(cardPadding, 0, cardPadding, cardPadding),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: DesignTokens.sm,
                  runSpacing: 4,
                  children: [
                    Text(
                      p.availability,
                      style: AppTypography.bodySmall(color: DesignTokens.oliveAccent).copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!hasPillowOptions) ...[
                          ListenableBuilder(
                            listenable: CartController.instance,
                            builder: (context, _) {
                              final inCart = CartController.instance.contains(p.id);
                              return InkWell(
                                onTap: () {
                                  if (inCart) {
                                    CartController.instance.removeFromCart(p.id);
                                  } else {
                                    CartController.instance.addToCart(p, quantity: 1);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  color: inCart ? DesignTokens.oliveAccent : DesignTokens.burntOrange,
                                  child: Text(
                                    inCart ? 'ADDED TO CART' : 'ADD TO CART',
                                    style: AppTypography.labelUppercase(color: Colors.white).copyWith(fontSize: 9),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: DesignTokens.md),
                        ],
                        Text(
                          'VIEW SPECS',
                          style: AppTypography.labelUppercase(color: DesignTokens.burntOrange).copyWith(fontSize: 10),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 10, color: DesignTokens.burntOrange),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
