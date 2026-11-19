import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/widgets/hover_image.dart';
import '../../../core/widgets/sage_button.dart';
import '../../../data/content_data.dart';

class StorySection extends StatelessWidget {
  final Function(String) onNavigate;
  const StorySection({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Container(
      color: DesignTokens.softBackground,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? DesignTokens.mobilePadding : DesignTokens.desktopPadding,
        vertical: isMobile ? DesignTokens.xxl : DesignTokens.xxxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: DesignTokens.maxContentWidth),
          child: ResponsiveLayout(
            mobile: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HoverImage(
                  imageUrl: ContentData.founderImage,
                  aspectRatio: 3 / 4,
                ),
                const SizedBox(height: DesignTokens.xl),
                _StoryTextContent(onNavigate: onNavigate),
              ],
            ),
            desktop: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  flex: 5,
                  child: HoverImage(
                    imageUrl: ContentData.founderImage,
                    aspectRatio: 4 / 5,
                  ),
                ),
                const SizedBox(width: DesignTokens.xxxl),
                Expanded(
                  flex: 6,
                  child: _StoryTextContent(onNavigate: onNavigate),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryTextContent extends StatelessWidget {
  final Function(String) onNavigate;
  const _StoryTextContent({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OUR STORY',
          style: AppTypography.heroTitle().copyWith(fontSize: 48),
        ),
        const SizedBox(height: DesignTokens.lg),
        Text(
          ContentData.founderBioFull,
          style: AppTypography.bodyLarge(color: DesignTokens.textPrimary),
        ),
        const SizedBox(height: DesignTokens.xxl),
        SageButton(
          text: 'DISCOVER MORE ABOUT BOSIBORI',
          style: SageButtonStyle.primary,
          onTap: () => onNavigate('/founder'),
        ),
      ],
    );
  }
}
