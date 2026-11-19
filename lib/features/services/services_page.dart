import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/thin_rule.dart';
import '../../core/widgets/sage_button.dart';
import '../../core/widgets/hover_image.dart';
import '../../data/content_data.dart';
import '../../models/service_model.dart';

class ServicesPage extends StatelessWidget {
  final Function(String) onNavigate;

  const ServicesPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    const services = ContentData.services;

    return SingleChildScrollView(
      child: Padding(
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
                Text('Services', style: AppTypography.heroTitle().copyWith(fontSize: isMobile ? 40 : 64)),
                const SizedBox(height: DesignTokens.sm),
                Text('STUDIO COMMISSIONS, CURATION & CREATIVE DIRECTION', style: AppTypography.labelUppercase()),
                const SizedBox(height: DesignTokens.xl),
                const ThinRule(),
                const SizedBox(height: DesignTokens.xxxl),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: DesignTokens.xxxl),
                    child: ThinRule(),
                  ),
                  itemBuilder: (context, index) {
                    return _ServiceEditorialRow(service: services[index], onNavigate: onNavigate);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceEditorialRow extends StatelessWidget {
  final StudioService service;
  final Function(String) onNavigate;

  const _ServiceEditorialRow({required this.service, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HoverImage(imageUrl: service.image, aspectRatio: 16 / 10),
          const SizedBox(height: DesignTokens.xl),
          _ServiceDetails(service: service, onNavigate: onNavigate),
        ],
      ),
      desktop: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: HoverImage(imageUrl: service.image, aspectRatio: 4 / 3),
          ),
          const SizedBox(width: DesignTokens.xxxl),
          Expanded(
            flex: 6,
            child: _ServiceDetails(service: service, onNavigate: onNavigate),
          ),
        ],
      ),
    );
  }
}

class _ServiceDetails extends StatelessWidget {
  final StudioService service;
  final Function(String) onNavigate;

  const _ServiceDetails({required this.service, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(service.category, style: AppTypography.labelUppercase(color: DesignTokens.burntOrange)),
        const SizedBox(height: DesignTokens.sm),
        Text(
          service.title,
          style: AppTypography.subTitle().copyWith(
            fontSize: isMobile ? 28 : 36,
          ),
        ),
        const SizedBox(height: DesignTokens.sm),
        Text(
          service.subtitle,
          style: AppTypography.bodyLarge().copyWith(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: DesignTokens.md),
        Text(service.description, style: AppTypography.bodyLarge()),
        const SizedBox(height: DesignTokens.xl),
        Text('DELIVERABLES & SCOPE', style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent)),
        const SizedBox(height: DesignTokens.sm),
        ...service.deliverables.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.check, size: 14, color: DesignTokens.burntOrange),
                  ),
                  const SizedBox(width: DesignTokens.sm),
                  Expanded(
                    child: Text(d, style: AppTypography.bodyMedium()),
                  ),
                ],
              ),
            )),
        const SizedBox(height: DesignTokens.xxl),
        SageButton(
          text: 'START A PROJECT WITH THIS SERVICE',
          style: SageButtonStyle.primary,
          onTap: () => onNavigate('/contact'),
        ),
      ],
    );
  }
}
