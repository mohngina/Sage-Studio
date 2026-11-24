import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/thin_rule.dart';
import '../../core/widgets/sage_button.dart';
import '../../core/widgets/hover_image.dart';
import '../../core/widgets/info_centre_modal.dart';
import '../../models/product_model.dart';
import '../../data/product_data.dart';
import 'cart_controller.dart';
import 'widgets/cart_drawer.dart';
import 'widgets/favourite_button.dart';
import 'widgets/product_reviews_section.dart';
import '../home/widgets/footer_section.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final String initialOption;
  final Function(String) onNavigate;
  final Function(Product)? onSelectProduct;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.initialOption = 'Cover & Insert',
    required this.onNavigate,
    this.onSelectProduct,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  late String _selectedPillowOption = widget.initialOption;

  @override
  void didUpdateWidget(covariant ProductDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _quantity = 1;
      _selectedPillowOption = widget.initialOption;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = Breakpoints.isMobile(context);
    final isCompact = screenWidth < 600;
    final product = widget.product;
    final otherProductsInClan =
        ProductData.sampleProducts.where((p) => p.id != product.id && p.clan == product.clan).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact
                  ? DesignTokens.mobilePadding
                  : (screenWidth < 1100 ? DesignTokens.xl : DesignTokens.desktopPadding),
              vertical: isMobile ? DesignTokens.xl : DesignTokens.xxl,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: DesignTokens.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Top Navigation Row
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: DesignTokens.md,
                  runSpacing: DesignTokens.sm,
                  children: [
                    SageButton(
                      text: '← BACK TO ${product.clan.toUpperCase()}',
                      style: SageButtonStyle.textLink,
                      onTap: () => widget.onNavigate('/shop'),
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
                const SizedBox(height: DesignTokens.md),
                Text(
                  'CATALOGUE / ${product.clan.toUpperCase()} / ${product.title.toUpperCase()} (${product.subtitle.toUpperCase()})',
                  style: AppTypography.labelUppercase(color: DesignTokens.textMuted).copyWith(fontSize: 10),
                ),
                const SizedBox(height: DesignTokens.xl),

                // Responsive Product Content
                ResponsiveLayout(
                  mobile: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProductImageSection(
                        product: product,
                        otherProducts: otherProductsInClan,
                        onSelectProduct: widget.onSelectProduct,
                      ),
                      const SizedBox(height: DesignTokens.xxl),
                      _ProductInfo(
                        product: product,
                        quantity: _quantity,
                        selectedOption: _selectedPillowOption,
                        onOptionChanged: (opt) => setState(() => _selectedPillowOption = opt),
                        onQuantityChanged: (q) => setState(() => _quantity = q),
                        onAddToCart: () {
                          final cartProduct = product.withPillowOption(_selectedPillowOption);
                          CartController.instance.addToCart(cartProduct, quantity: _quantity);
                        },
                        onNavigate: widget.onNavigate,
                        otherProducts: otherProductsInClan,
                        onSelectProduct: widget.onSelectProduct,
                      ),
                    ],
                  ),
                  desktop: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _ProductImageSection(
                          product: product,
                          otherProducts: otherProductsInClan,
                          onSelectProduct: widget.onSelectProduct,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.xxxl),
                      Expanded(
                        flex: 5,
                        child: _ProductInfo(
                          product: product,
                          quantity: _quantity,
                          selectedOption: _selectedPillowOption,
                          onOptionChanged: (opt) => setState(() => _selectedPillowOption = opt),
                          onQuantityChanged: (q) => setState(() => _quantity = q),
                          onAddToCart: () {
                            final cartProduct = product.withPillowOption(_selectedPillowOption);
                            CartController.instance.addToCart(cartProduct, quantity: _quantity);
                          },
                          onNavigate: widget.onNavigate,
                          otherProducts: otherProductsInClan,
                          onSelectProduct: widget.onSelectProduct,
                        ),
                      ),
                    ],
                  ),
                ),
                ProductReviewsSection(
                  product: product,
                  onNavigate: widget.onNavigate,
                ),
              ],
            ),
          ),
        ),
      ),
          const SizedBox(height: DesignTokens.xxl),
          FooterSection(onNavigate: widget.onNavigate),
        ],
      ),
    );
  }
}

class _ProductImageSection extends StatelessWidget {
  final Product product;
  final List<Product> otherProducts;
  final Function(Product)? onSelectProduct;

  const _ProductImageSection({
    required this.product,
    required this.otherProducts,
    this.onSelectProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            HoverImage(imageUrl: product.mainImage, aspectRatio: 4 / 3),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: DesignTokens.textPrimary.withOpacity(0.85),
                child: Text(
                  'CODE: ${product.code}',
                  style: AppTypography.labelUppercase(color: Colors.white).copyWith(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
        if (otherProducts.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.lg),
          Text(
            'OTHER MODELS IN ${product.clan.toUpperCase()}',
            style: AppTypography.labelUppercase(color: DesignTokens.textMuted).copyWith(fontSize: 10),
          ),
          const SizedBox(height: DesignTokens.sm),
          Wrap(
            spacing: DesignTokens.md,
            runSpacing: DesignTokens.sm,
            children: otherProducts.map((other) {
              return InkWell(
                onTap: () => onSelectProduct?.call(other),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: DesignTokens.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 45,
                        child: HoverImage(imageUrl: other.mainImage, aspectRatio: 4 / 3),
                      ),
                      const SizedBox(width: DesignTokens.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(other.subtitle, style: AppTypography.bodySmall().copyWith(fontWeight: FontWeight.bold)),
                          Text('KSH ${other.priceKshLabel ?? other.priceKsh.toStringAsFixed(0)}',
                              style: AppTypography.bodySmall(color: DesignTokens.burntOrange)),
                        ],
                      ),
                      const SizedBox(width: DesignTokens.sm),
                      const Icon(Icons.arrow_forward_ios, size: 10, color: DesignTokens.textMuted),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final Product product;
  final int quantity;
  final String selectedOption;
  final Function(String) onOptionChanged;
  final Function(int) onQuantityChanged;
  final VoidCallback onAddToCart;
  final Function(String) onNavigate;
  final List<Product> otherProducts;
  final Function(Product)? onSelectProduct;

  const _ProductInfo({
    required this.product,
    required this.quantity,
    required this.selectedOption,
    required this.onOptionChanged,
    required this.onQuantityChanged,
    required this.onAddToCart,
    required this.onNavigate,
    required this.otherProducts,
    this.onSelectProduct,
  });

  @override
  Widget build(BuildContext context) {
    final hasPillowOptions = product.coverOnlyPriceKsh != null;
    final activePriceKsh =
        hasPillowOptions && selectedOption == 'Cover only' ? product.coverOnlyPriceKsh! : product.priceKsh;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clan tag
        Text(
          '${product.clan.toUpperCase()} • ${product.category}',
          style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent),
        ),
        const SizedBox(height: DesignTokens.xs),

        // Product Title
        Text(product.title, style: AppTypography.heroTitle().copyWith(fontSize: 40)),
        const SizedBox(height: DesignTokens.xs),

        // Subtitle / Variant
        Text(
          product.subtitle,
          style: AppTypography.subTitle(color: DesignTokens.burntOrange).copyWith(fontSize: 22),
        ),
        const SizedBox(height: DesignTokens.lg),

        // Pricing Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.lg),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F5F2),
            border: Border.all(color: DesignTokens.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PRICE', style: AppTypography.labelUppercase(color: DesignTokens.textMuted)),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'KSH ${product.priceKshLabel ?? product.priceKsh.toStringAsFixed(0)}',
                    maxLines: 1,
                    style: AppTypography.heroTitle(color: DesignTokens.burntOrange).copyWith(
                      fontSize: (product.priceKshLabel != null && product.priceKshLabel!.length > 15) ? 20 : 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    product.priceUsdLabel != null
                        ? (product.priceUsdLabel!.startsWith('Sale') || product.priceUsdLabel!.startsWith('Discount')
                            ? product.priceUsdLabel!
                            : 'USD ${product.priceUsdLabel}')
                        : 'USD ${product.priceUsd.toStringAsFixed(0)}',
                    maxLines: 1,
                    style: AppTypography.cardTitle(color: DesignTokens.textPrimary).copyWith(
                      fontSize: (product.priceUsdLabel != null && product.priceUsdLabel!.length > 15) ? 15 : 18,
                    ),
                  ),
                ),
              ),
              if (hasPillowOptions) ...[
                const SizedBox(height: DesignTokens.md),
                Text(
                  'SELECT OPTION',
                  style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent).copyWith(fontSize: 10),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: DesignTokens.burntOrange.withValues(alpha: 0.6)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedOption,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: DesignTokens.burntOrange),
                      style: AppTypography.bodyMedium(color: DesignTokens.textPrimary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'Cover & Insert',
                          child: Text(
                            'Cover & Insert — KSH ${product.priceKsh.toStringAsFixed(0)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Cover only',
                          child: Text(
                            'Cover only — KSH ${product.coverOnlyPriceKsh!.toStringAsFixed(0)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) onOptionChanged(val);
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'CODE: ${product.code}',
                style: AppTypography.bodySmall(color: DesignTokens.textPrimary).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: DesignTokens.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: DesignTokens.sageAccent.withOpacity(0.2),
                  border: Border.all(color: DesignTokens.sageAccent.withOpacity(0.5)),
                ),
                child: Text(
                  product.availability,
                  style: AppTypography.bodySmall(color: DesignTokens.oliveAccent).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: DesignTokens.lg),

        if (product.makers.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.lg),
          const ThinRule(),
          const SizedBox(height: DesignTokens.lg),

          // The Makers section
          Text('The Makers', style: AppTypography.cardTitle().copyWith(fontSize: 20)),
          const SizedBox(height: DesignTokens.sm),
          ...product.makers.map((maker) {
            final parts = maker.split(' - ');
            final name = parts[0];
            final role = parts.length > 1 ? parts[1] : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.handyman_outlined, size: 16, color: DesignTokens.burntOrange),
                  ),
                  const SizedBox(width: DesignTokens.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodyMedium(color: DesignTokens.textPrimary),
                        children: [
                          TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (role.isNotEmpty) ...[
                            const TextSpan(text: ' - ', style: TextStyle(color: DesignTokens.textMuted)),
                            TextSpan(text: role, style: const TextStyle(color: DesignTokens.oliveAccent)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        const SizedBox(height: DesignTokens.lg),
        const ThinRule(),
        const SizedBox(height: DesignTokens.lg),

        // Materials section
        Text('Materials', style: AppTypography.cardTitle().copyWith(fontSize: 20)),
        const SizedBox(height: DesignTokens.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: product.materials.map((material) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F0ED),
                border: Border.all(color: DesignTokens.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 14, color: DesignTokens.burntOrange),
                  const SizedBox(width: 6),
                  Text(material, style: AppTypography.bodyMedium(color: DesignTokens.textPrimary)),
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: DesignTokens.lg),
        const ThinRule(),
        const SizedBox(height: DesignTokens.lg),

        if (product.woodType.isNotEmpty || product.dimensions.isNotEmpty) ...[
          Wrap(
            spacing: DesignTokens.xxl,
            runSpacing: DesignTokens.md,
            children: [
              if (product.woodType.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wood Type', style: AppTypography.cardTitle().copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      product.woodType,
                      style: AppTypography.bodyMedium(color: DesignTokens.oliveAccent)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              if (product.dimensions.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Size / Colour', style: AppTypography.cardTitle().copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      product.dimensions,
                      style: AppTypography.bodyMedium(color: DesignTokens.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.lg),
          const ThinRule(),
          const SizedBox(height: DesignTokens.lg),
        ],

        if (product.details.isNotEmpty) ...[
          Text('Specifications & Pricing Breakdown', style: AppTypography.cardTitle().copyWith(fontSize: 20)),
          const SizedBox(height: DesignTokens.sm),
          ...product.details.map((detail) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 6, color: DesignTokens.burntOrange),
                  ),
                  const SizedBox(width: DesignTokens.sm),
                  Expanded(
                    child: Text(
                      detail,
                      style: AppTypography.bodyMedium(color: DesignTokens.textPrimary),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: DesignTokens.lg),
          const ThinRule(),
          const SizedBox(height: DesignTokens.lg),
        ],

        // Add to Cart Section
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: DesignTokens.borderLight),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: () => onQuantityChanged(quantity > 1 ? quantity - 1 : 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.md),
                    child: Text('$quantity', style: AppTypography.bodyLarge()),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => onQuantityChanged(quantity + 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.xl),
            Expanded(
              child: ListenableBuilder(
                listenable: CartController.instance,
                builder: (context, _) {
                  final cartId = product.withPillowOption(selectedOption).id;
                  final inCart = CartController.instance.contains(cartId);
                  return SageButton(
                    text: inCart
                        ? 'ADDED TO CART'
                        : (hasPillowOptions
                            ? 'ADD TO CART • KSH ${(activePriceKsh * quantity).toStringAsFixed(0)}'
                            : 'ADD TO CART'),
                    style: inCart ? SageButtonStyle.secondary : SageButtonStyle.burntOrange,
                    fullWidth: true,
                    onTap: () {
                      if (inCart) {
                        CartController.instance.removeFromCart(cartId);
                      } else {
                        onAddToCart();
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: DesignTokens.sm),
            FavouriteButton(
              productId: product.id,
              productTitle: product.title,
              returnRoute: '/shop?product=${product.id}',
              onNavigate: onNavigate,
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.md),
        Text(
          'Each piece is made to order in our Nairobi studio. Custom dimensions, timber finishes, and upholstery textures available upon commission.',
          style: AppTypography.bodySmall(color: DesignTokens.textMuted),
        ),
      ],
    );
  }
}
