import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../core/widgets/hover_image.dart';
import '../../../data/product_data.dart';
import '../../../models/product_model.dart';
import '../../../core/widgets/sage_button.dart';

class CollectionsSection extends StatelessWidget {
  final Function(String) onNavigate;
  const CollectionsSection({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    const featuredProducts = [
      ProductData.sageSelectPillowBrownDiamond,
      ProductData.zola1Seater,
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? DesignTokens.mobilePadding : DesignTokens.desktopPadding,
        vertical: isMobile ? DesignTokens.xxl : DesignTokens.xxxl,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: DesignTokens.maxContentWidth),
          child: Column(
            children: [
              SectionHeading(
                title: 'CHECK NEW COLLECTION',
                label: 'DYNAMIC RELEASES • STUDIO CLANS',
                action: SageButton(
                  text: 'VIEW ALL SHOP',
                  style: SageButtonStyle.textLink,
                  onTap: () => onNavigate('/shop'),
                ),
              ),
              const SizedBox(height: DesignTokens.xxl),
              if (!isMobile)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ProductCardLarge(
                          product: featuredProducts[0],
                          onNavigate: onNavigate,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.xl),
                      Expanded(
                        child: _ProductCardLarge(
                          product: featuredProducts[1],
                          onNavigate: onNavigate,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.xl),
                      child: _ProductCardLarge(product: featuredProducts[0], onNavigate: onNavigate),
                    ),
                    _ProductCardLarge(product: featuredProducts[1], onNavigate: onNavigate),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCardLarge extends StatelessWidget {
  final Product product;
  final Function(String) onNavigate;

  const _ProductCardLarge({required this.product, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onNavigate('/shop?clan=${Uri.encodeComponent(product.clan)}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HoverImage(
            imageUrl: product.mainImage,
            aspectRatio: 4 / 3,
          ),
          const SizedBox(height: DesignTokens.md),
          Text(
            product.clan,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.subTitle(),
          ),
          const SizedBox(height: 4),
          Text(
            product.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium(color: DesignTokens.oliveAccent),
          ),
          const SizedBox(height: 8),
          Text(
            'KSH ${product.priceKsh.toStringAsFixed(0)} • USD ${product.priceUsd.toStringAsFixed(0)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle(color: DesignTokens.burntOrange).copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
