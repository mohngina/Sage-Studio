import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/signature_watermark.dart';
import '../../core/widgets/thin_rule.dart';
import '../../core/widgets/image_frame.dart';
import '../../data/gallery_data.dart';
import '../../models/gallery_model.dart';
import '../home/widgets/footer_section.dart';

class GalleryPage extends StatelessWidget {
  final Function(String) onNavigate;

  const GalleryPage({super.key, required this.onNavigate});

  void _showItemModal(BuildContext context, GalleryItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: DesignTokens.primaryBackground,
          insetPadding: const EdgeInsets.all(DesignTokens.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.xxl),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.category, style: AppTypography.labelUppercase(color: DesignTokens.burntOrange)),
                        IconButton(
                          icon: const Icon(Icons.close, color: DesignTokens.textPrimary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.sm),
                    Text(item.title, style: AppTypography.heroTitle(color: DesignTokens.textPrimary)),
                    const SizedBox(height: DesignTokens.md),
                    const ThinRule(),
                    const SizedBox(height: DesignTokens.xl),
                    ClipRRect(
                      child: Image.network(item.image, fit: BoxFit.cover, height: 400, width: double.infinity),
                    ),
                    const SizedBox(height: DesignTokens.xl),
                    Text(item.storyDetails, style: AppTypography.bodyLarge()),
                    const SizedBox(height: DesignTokens.xl),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('RELEASE YEAR: ${item.year}', style: AppTypography.bodySmall()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final items = GalleryData.items;

    return SingleChildScrollView(
      child: Column(
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
                child: Stack(
                  children: [
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: SignatureWatermark(fontSize: 140),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Projects Page', style: AppTypography.heroTitle().copyWith(fontSize: isMobile ? 40 : 64)),
                    const SizedBox(height: DesignTokens.sm),
                    Text('CURATED EDITORIAL ARCHIVE & BOTANICAL STUDIES', style: AppTypography.labelUppercase()),
                    const SizedBox(height: DesignTokens.xl),
                    const ThinRule(),
                    const SizedBox(height: DesignTokens.xxxl),
                    if (!isMobile) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _GallerySurfaceBlock(
                          item: items[0],
                          accentColor: const Color(0xFF690400),
                          backgroundColor: DesignTokens.softBackground,
                          onTap: () => _showItemModal(context, items[0]),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.xxxl),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _GallerySurfaceBlock(
                          item: items[1],
                          accentColor: const Color(0xFFCC5600),
                          backgroundColor: DesignTokens.sageAccent,
                          onTap: () => _showItemModal(context, items[1]),
                        ),
                      ),
                    ] else ...[
                      _GallerySurfaceBlock(
                        item: items[0],
                        accentColor: const Color(0xFF690400),
                        backgroundColor: DesignTokens.softBackground,
                        onTap: () => _showItemModal(context, items[0]),
                      ),
                      const SizedBox(height: DesignTokens.xxl),
                      _GallerySurfaceBlock(
                        item: items[1],
                        accentColor: const Color(0xFFCC5600),
                        backgroundColor: DesignTokens.sageAccent,
                        onTap: () => _showItemModal(context, items[1]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
          const SizedBox(height: DesignTokens.xxl),
          FooterSection(onNavigate: onNavigate),
        ],
      ),
    );
  }
}

class _GallerySurfaceBlock extends StatelessWidget {
  final GalleryItem item;
  final Color accentColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _GallerySurfaceBlock({
    required this.item,
    required this.accentColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isMobile ? double.infinity : 900,
        padding: const EdgeInsets.all(DesignTokens.xxl),
        color: backgroundColor,
        child: Stack(
          children: [
            Positioned(
              left: isMobile ? 0 : 300,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: DesignTokens.borderLight),
            ),
            ResponsiveLayout(
              mobile: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ImageFrameWithAccent(
                      imageUrl: item.image,
                      accentColor: accentColor,
                      width: 240,
                      height: 300,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.xl),
                  Text(item.title, style: AppTypography.labelUppercase(color: DesignTokens.textPrimary)),
                  const SizedBox(height: DesignTokens.md),
                  Text(item.description, style: AppTypography.bodyMedium(color: DesignTokens.textPrimary)),
                ],
              ),
              desktop: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(item.title, style: AppTypography.labelUppercase(color: DesignTokens.textPrimary)),
                        const SizedBox(height: DesignTokens.lg),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium(color: DesignTokens.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DesignTokens.xxl),
                  ImageFrameWithAccent(
                    imageUrl: item.image,
                    accentColor: accentColor,
                    width: 320,
                    height: 400,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
