import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/widgets/info_centre_modal.dart';
import '../../core/services/auth_service.dart';
import '../shop/cart_controller.dart';
import '../shop/favourites_controller.dart';
import '../shop/widgets/cart_drawer.dart';
import 'mobile_menu_drawer.dart';

class SiteHeader extends StatelessWidget implements PreferredSizeWidget {
  final String activeRoute;
  final Function(String) onNavigate;

  const SiteHeader({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
  });

  @override
  Size get preferredSize => const Size.fromHeight(84.0);

  /// Width below which the full inline navigation no longer fits (six links,
  /// iNfo Centre, account and cart); narrower screens use the menu drawer.
  static const double fullNavMinWidth = 1280.0;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final useCompactNav = MediaQuery.sizeOf(context).width < fullNavMinWidth;

    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        color: DesignTokens.primaryBackground,
        border: Border(bottom: BorderSide(color: DesignTokens.borderLight, width: 1.0)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? DesignTokens.mobilePadding : DesignTokens.desktopPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: DesignTokens.maxContentWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Official Sage Studio Logo Asset
              Semantics(
                button: true,
                label: 'Sage Studio Home',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onNavigate('/'),
                    child: Image.asset(
                      'assets/images/logo/sage_studio_logo.png',
                      height: 56,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Sage Studio',
                                  style: AppTypography.subTitle(color: DesignTokens.textPrimary).copyWith(fontSize: 22),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: DesignTokens.burntOrange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'CRAFTED IN KENYA',
                              style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent).copyWith(fontSize: 9),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              if (!useCompactNav)
                Row(
                  children: [
                    _NavLink(title: 'HOME', route: '/', activeRoute: activeRoute, onTap: () => onNavigate('/')),
                    const SizedBox(width: DesignTokens.lg),
                    _NavLink(
                        title: 'SERVICES',
                        route: '/services',
                        activeRoute: activeRoute,
                        onTap: () => onNavigate('/services')),
                    const SizedBox(width: DesignTokens.lg),
                    _NavLink(title: 'SHOP', route: '/shop', activeRoute: activeRoute, onTap: () => onNavigate('/shop')),
                    const SizedBox(width: DesignTokens.lg),
                    _NavLink(
                        title: 'PROJECTS',
                        route: '/projects',
                        activeRoute: activeRoute,
                        onTap: () => onNavigate('/projects')),
                    const SizedBox(width: DesignTokens.lg),
                    _NavLink(
                        title: 'OUR STORY',
                        route: '/founder',
                        activeRoute: activeRoute,
                        onTap: () => onNavigate('/founder')),
                    const SizedBox(width: DesignTokens.lg),
                    _NavLink(
                        title: 'CONTACT',
                        route: '/contact',
                        activeRoute: activeRoute,
                        onTap: () => onNavigate('/contact')),
                    const SizedBox(width: DesignTokens.lg),

                    // Info Centre Action
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: DesignTokens.oliveAccent, width: 1.0),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () => InfoCentreModal.show(context),
                      child: Text('iNfo Centre', style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent)),
                    ),
                    const SizedBox(width: DesignTokens.md),
                    _FavouritesIconButton(onNavigate: onNavigate),
                    _AccountIconButton(onNavigate: onNavigate),
                    _CartIconButton(onNavigate: onNavigate),
                  ],
                )
              else
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: DesignTokens.oliveAccent, size: 22),
                      onPressed: () => InfoCentreModal.show(context),
                    ),
                    _FavouritesIconButton(onNavigate: onNavigate),
                    _AccountIconButton(onNavigate: onNavigate),
                    _CartIconButton(onNavigate: onNavigate),
                    const SizedBox(width: DesignTokens.sm),
                    IconButton(
                      icon: const Icon(Icons.menu, color: DesignTokens.textPrimary, size: 24),
                      onPressed: () => MobileMenuDrawer.show(
                        context,
                        activeRoute: activeRoute,
                        onNavigate: onNavigate,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String title;
  final String route;
  final String activeRoute;
  final VoidCallback onTap;

  const _NavLink({
    required this.title,
    required this.route,
    required this.activeRoute,
    required this.onTap,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.activeRoute == widget.route ||
        (widget.route != '/' && widget.activeRoute.startsWith('${widget.route}?'));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: AppTypography.navLink(
                color: _isHovered || isActive ? DesignTokens.burntOrange : DesignTokens.textPrimary,
                isActive: isActive,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: DesignTokens.durationMicro,
              height: 1.5,
              width: isActive || _isHovered ? 24 : 0,
              color: DesignTokens.burntOrange,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountIconButton extends StatelessWidget {
  final Function(String) onNavigate;
  const _AccountIconButton({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final signedIn = AuthService.instance.isSignedIn;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: signedIn ? 'My account' : 'Sign in',
              icon: Icon(
                signedIn ? Icons.person : Icons.person_outline,
                color: DesignTokens.textPrimary,
                size: 22,
                semanticLabel: signedIn ? 'My account' : 'Sign in',
              ),
              onPressed: () => onNavigate(signedIn ? '/account' : '/sign-in'),
            ),
            if (signedIn)
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: DesignTokens.oliveAccent, shape: BoxShape.circle),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FavouritesIconButton extends StatelessWidget {
  final Function(String) onNavigate;
  const _FavouritesIconButton({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([FavouritesController.instance, AuthService.instance]),
      builder: (context, _) {
        if (!AuthService.instance.isSignedIn) {
          return const SizedBox.shrink();
        }
        final count = FavouritesController.instance.count;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Favourites',
              icon: Icon(
                count > 0 ? Icons.favorite : Icons.favorite_border,
                color: count > 0 ? DesignTokens.burntOrange : DesignTokens.textPrimary,
                size: 21,
                semanticLabel: 'Favourites',
              ),
              onPressed: () => onNavigate('/account?tab=favourites'),
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: DesignTokens.burntOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CartIconButton extends StatelessWidget {
  final Function(String) onNavigate;
  const _CartIconButton({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartController.instance,
      builder: (context, _) {
        final count = CartController.instance.totalItemCount;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Shopping cart',
              icon: const Icon(Icons.shopping_bag_outlined, color: DesignTokens.textPrimary, size: 22),
              onPressed: () => CartDrawer.show(context, onNavigate: onNavigate),
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: DesignTokens.burntOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
