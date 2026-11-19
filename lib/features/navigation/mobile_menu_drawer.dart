import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/signature_watermark.dart';
import '../../core/widgets/thin_rule.dart';
import '../../core/services/auth_service.dart';

class MobileMenuDrawer extends StatelessWidget {
  final String activeRoute;
  final Function(String) onNavigate;

  const MobileMenuDrawer({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
  });

  static void show(BuildContext context, {required String activeRoute, required Function(String) onNavigate}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Navigation',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: DesignTokens.durationStandard,
      pageBuilder: (context, anim1, anim2) {
        return FadeTransition(
          opacity: anim1,
          child: MobileMenuDrawer(activeRoute: activeRoute, onNavigate: onNavigate),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'title': 'Home', 'route': '/'},
      {'title': 'Services', 'route': '/services'},
      {'title': 'Shop', 'route': '/shop'},
      {'title': 'Projects', 'route': '/projects'},
      {'title': 'Founder', 'route': '/founder'},
      {'title': 'Contacts', 'route': '/contact'},
      if (AuthService.instance.isSignedIn)
        {'title': 'My Account', 'route': '/account'}
      else
        {'title': 'Sign In', 'route': '/sign-in'},
    ];

    return Scaffold(
      backgroundColor: DesignTokens.primaryBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Watermark Logo
            const Positioned(
              right: -10,
              bottom: 20,
              child: SignatureWatermark(fontSize: 100),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(DesignTokens.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Headers',
                        style: AppTypography.heroTitle(color: DesignTokens.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 28, color: DesignTokens.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.xl),
                  const ThinRule(),
                  const SizedBox(height: DesignTokens.xxl),

                  // Menu Items matching Mood Board 1
                  Expanded(
                    child: ListView.builder(
                      itemCount: navItems.length,
                      itemBuilder: (context, index) {
                        final item = navItems[index];
                        final isActive = activeRoute == item['route'];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: DesignTokens.md),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              onNavigate(item['route']!);
                            },
                            child: Row(
                              children: [
                                Text(
                                  item['title']!,
                                  style: AppTypography.heroTitle(
                                    color: isActive ? DesignTokens.burntOrange : DesignTokens.textPrimary,
                                  ).copyWith(fontSize: 36),
                                ),
                                if (isActive) ...[
                                  const SizedBox(width: DesignTokens.md),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: DesignTokens.burntOrange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
