import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/widgets/hover_image.dart';
import '../../../core/widgets/marquee_ticker.dart';
import '../../../data/content_data.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? DesignTokens.mobilePadding : DesignTokens.desktopPadding,
            vertical: isMobile ? DesignTokens.xl : DesignTokens.xxl,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: DesignTokens.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'FURNITURE DESIGN STUDIO',
                        style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent),
                      ),
                      const SizedBox(width: DesignTokens.sm),
                      Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(color: DesignTokens.burntOrange, shape: BoxShape.circle)),
                      const SizedBox(width: DesignTokens.sm),
                      Text(
                        'NAIROBI, KENYA',
                        style: AppTypography.labelUppercase(color: DesignTokens.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.md),
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        ContentData.studioTagline,
                        maxLines: 1,
                        softWrap: false,
                        style: AppTypography.heroTitle(),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.xl),
                  HoverImage(
                    imageUrl: 'assets/images/products/hero_sofa.jpg',
                    aspectRatio: isMobile ? 16 / 10 : 21 / 9,
                  ),
                ],
              ),
            ),
          ),
        ),
        const MarqueeTicker(items: ContentData.newsTickerItems),
      ],
    );
  }
}
