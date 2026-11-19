import 'package:flutter/material.dart';
import '../../features/home/home_page.dart';
import '../../features/services/services_page.dart';
import '../../features/gallery/gallery_page.dart';
import '../../features/shop/shop_page.dart';
import '../../features/founder/founder_page.dart';
import '../../features/contact/contact_page.dart';
import '../../features/auth/sign_in_page.dart';
import '../../features/account/account_page.dart';
import '../../features/checkout/checkout_page.dart';

class AppRouter {
  static Widget buildPage(String route, Function(String) onNavigate) {
    final uri = Uri.tryParse(route);
    final path = uri?.path ?? route;

    switch (path) {
      case '/':
        return HomePage(onNavigate: onNavigate);
      case '/services':
        return ServicesPage(onNavigate: onNavigate);
      case '/projects':
      case '/gallery':
        return GalleryPage(onNavigate: onNavigate);
      case '/shop':
        return ShopPage(
          onNavigate: onNavigate,
          initialClanName: uri?.queryParameters['clan'],
          initialProductId: uri?.queryParameters['product'],
        );
      case '/founder':
        return FounderPage(onNavigate: onNavigate);
      case '/contact':
        return ContactPage(onNavigate: onNavigate);
      case '/sign-in':
        return SignInPage(
          onNavigate: onNavigate,
          initialMode: authModeFromQuery(uri?.queryParameters['mode']),
          returnRoute: uri?.queryParameters['return'],
        );
      case '/account':
        return AccountPage(onNavigate: onNavigate, initialTab: uri?.queryParameters['tab']);
      case '/checkout':
        return CheckoutPage(onNavigate: onNavigate);
      default:
        return HomePage(onNavigate: onNavigate);
    }
  }
}
