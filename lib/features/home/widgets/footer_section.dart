import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/widgets/social_links_row.dart';
import '../../../core/widgets/thin_rule.dart';

class FooterSection extends StatelessWidget {
  final Function(String) onNavigate;

  const FooterSection({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Container(
      color: DesignTokens.footerBackground,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? DesignTokens.mobilePadding : DesignTokens.desktopPadding,
        vertical: isMobile ? DesignTokens.xxl : DesignTokens.xxxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: DesignTokens.maxContentWidth),
          child: Column(
            children: [
              if (!isMobile)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FooterColumn(
                        title: 'STUDIO & STORE',
                        links: const [
                          'Services',
                          'Opening Hours: 09:00 - 17:00 EAT',
                          'Kamakis, Ruiru (HQ)',
                        ],
                        onNavigate: onNavigate,
                      ),
                    ),
                    Expanded(
                      child: _FooterColumn(
                        title: 'DIRECT CONTACT',
                        links: const [
                          'sagestudio.ke@gmail.com',
                          '+254 794 001715',
                          'Project Enquiry Form',
                        ],
                        onNavigate: onNavigate,
                      ),
                    ),
                    Expanded(
                      child: _FooterColumn(
                        title: 'PHILOSOPHY',
                        links: const [
                          'Our Story',
                          'Contemporary African Proportions',
                          'Crafted in Kenya',
                        ],
                        onNavigate: onNavigate,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FooterColumn(
                      title: 'STUDIO & STORE',
                      links: const [
                        'Services',
                        'Opening Hours: 09:00 - 17:00 EAT',
                        'Kamakis, Ruiru (HQ)',
                      ],
                      onNavigate: onNavigate,
                    ),
                    const SizedBox(height: DesignTokens.xl),
                    _FooterColumn(
                      title: 'DIRECT CONTACT',
                      links: const [
                        'sagestudio.ke@gmail.com',
                        '+254 794 001715',
                        'Project Enquiry Form',
                      ],
                      onNavigate: onNavigate,
                    ),
                    const SizedBox(height: DesignTokens.xl),
                    _FooterColumn(
                      title: 'PHILOSOPHY',
                      links: const [
                        'Our Story',
                        'Contemporary African Proportions',
                        'Crafted in Kenya',
                      ],
                      onNavigate: onNavigate,
                    ),
                  ],
                ),
              const SizedBox(height: DesignTokens.xxxl),
              const ThinRule(color: DesignTokens.darkBorder),
              const SizedBox(height: DesignTokens.xxl),
              Text(
                'Sage Studio',
                style: AppTypography.heroTitle(color: Colors.white).copyWith(fontSize: 32),
              ),
              const SizedBox(height: DesignTokens.md),
              const SocialLinksRow(
                isDark: true,
                alignment: WrapAlignment.center,
              ),
              const SizedBox(height: DesignTokens.lg),
              Text(
                '© 2025 SAGE STUDIO • KAMAKIS, RUIRU • CRAFTED IN KENYA',
                style: AppTypography.labelUppercase(color: DesignTokens.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> links;
  final Function(String) onNavigate;

  const _FooterColumn({
    required this.title,
    required this.links,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelUppercase(color: Colors.white),
        ),
        const SizedBox(height: DesignTokens.md),
        ...links.map((link) {
          return Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.sm),
            child: GestureDetector(
              onTap: () {
                if (link.contains('Services')) onNavigate('/services');
                if (link.contains('Our Story')) onNavigate('/founder');
                if (link.contains('Enquiry') ||
                    link.contains('Kamakis') ||
                    link.contains('gmail') ||
                    link.contains('+254')) {
                  onNavigate('/contact');
                }
              },
              child: Text(
                link,
                style: AppTypography.bodySmall(color: DesignTokens.textMuted),
              ),
            ),
          );
        }),
      ],
    );
  }
}
