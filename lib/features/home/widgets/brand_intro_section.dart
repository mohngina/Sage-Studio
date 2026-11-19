import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/widgets/hover_image.dart';

class BrandIntroSection extends StatelessWidget {
  const BrandIntroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Container(
      color: const Color(0xFFE6E3E2), // Soft surface background from Mood Board 4
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? DesignTokens.mobilePadding : DesignTokens.desktopPadding,
        vertical: isMobile ? DesignTokens.xxl : DesignTokens.xxxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: DesignTokens.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Column: Asymmetric Visual Collage with descriptors
                    const Expanded(
                      flex: 6,
                      child: _VisualCollageGrid(),
                    ),
                    const SizedBox(width: DesignTokens.xxxl),
                    // Right Column: Headline & Nairobi African Proportions Box
                    const Expanded(
                      flex: 5,
                      child: _BrandIntroTextContent(),
                    ),
                  ],
                )
              else
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _BrandIntroTextContent(),
                    SizedBox(height: DesignTokens.xxl),
                    _VisualCollageGrid(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandIntroTextContent extends StatelessWidget {
  const _BrandIntroTextContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'WE ARE',
          textAlign: TextAlign.center,
          style: AppTypography.labelUppercase(color: DesignTokens.textPrimary).copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 3.5,
          ),
        ),
        const SizedBox(height: DesignTokens.sm),
        Text(
          'Sage\nStudio',
          textAlign: TextAlign.center,
          style: AppTypography.heroTitle().copyWith(
            fontSize: 60,
            height: 0.95,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF725D24),
            shadows: const [
              Shadow(
                color: Color(0xFF3C280D),
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.xxl),

        // Tan Box from Catalogue / Mood Board 4
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.xl,
            vertical: DesignTokens.xxl,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFD4B98B), // Warm camel beige surface
            border: Border.all(color: const Color(0xFF725D24), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF432D14), // Dark espresso drop shadow block
                offset: Offset(12, 12),
              ),
            ],
          ),
          child: Text(
            'We are a furniture design studio\nbased in\nNairobi, Kenya.\nOur designs are inspired by\ncontemporary African proportions.',
            textAlign: TextAlign.center,
            style: AppTypography.subTitle(color: DesignTokens.textPrimary).copyWith(
              height: 1.45,
              fontSize: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _VisualCollageGrid extends StatelessWidget {
  const _VisualCollageGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strip 1: alluring (Top image 4:3 -> alluring box 1:1 -> Bottom image 3:4)
        Expanded(
          child: Column(
            children: [
              _FramedCollageImage(
                imageUrl: 'assets/images/products/brand_intro_1.jpg',
                aspectRatio: 4 / 3,
              ),
              const SizedBox(height: DesignTokens.sm),
              _DescriptorBox('alluring', color: const Color(0xFFD4B98B)),
              const SizedBox(height: DesignTokens.sm),
              _FramedCollageImage(
                imageUrl: 'assets/images/products/brand_intro_2.jpg',
                aspectRatio: 3 / 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.md),
        // Strip 2: exquisite (Top image 3:4 -> exquisite box 1:1 -> Bottom image 4:3)
        Expanded(
          child: Column(
            children: [
              _FramedCollageImage(
                imageUrl: 'assets/images/products/brand_intro_3.jpg',
                aspectRatio: 3 / 4,
              ),
              const SizedBox(height: DesignTokens.sm),
              _DescriptorBox('exquisite', color: const Color(0xFFD4B98B)),
              const SizedBox(height: DesignTokens.sm),
              _FramedCollageImage(
                imageUrl: 'assets/images/products/brand_intro_4.jpg',
                aspectRatio: 4 / 3,
              ),
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.md),
        // Strip 3: functional (Top image 3:4 -> Middle image 4:3 -> functional box 1:1)
        Expanded(
          child: Column(
            children: [
              _FramedCollageImage(
                imageUrl: 'assets/images/products/brand_intro_5.jpg',
                aspectRatio: 3 / 4,
              ),
              const SizedBox(height: DesignTokens.sm),
              _FramedCollageImage(
                imageUrl: 'assets/images/products/brand_intro_6.jpg',
                aspectRatio: 4 / 3,
              ),
              const SizedBox(height: DesignTokens.sm),
              _DescriptorBox('functional', color: const Color(0xFFD4B98B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _FramedCollageImage({
    required String imageUrl,
    required double aspectRatio,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: HoverImage(
        imageUrl: imageUrl,
        aspectRatio: aspectRatio,
      ),
    );
  }

  Widget _DescriptorBox(String text, {required Color color}) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.cardTitle().copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: DesignTokens.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
