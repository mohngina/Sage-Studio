import 'package:flutter/material.dart';
import '../../data/product_data.dart';
import '../../models/product_model.dart';
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
  static String clanSlug(ClanCategory clan) {
    final id = clan.id.toLowerCase();
    return id.startsWith('clan-') ? id.substring(5) : id;
  }

  static ClanCategory? findClan(String? raw) {
    final target = raw?.trim().toLowerCase();
    if (target == null || target.isEmpty) return null;
    for (final clan in ProductData.sampleClans) {
      if (clanSlug(clan) == target ||
          clan.id.toLowerCase() == target ||
          clan.name.toLowerCase() == target ||
          clan.code.toLowerCase() == target) {
        return clan;
      }
    }
    return null;
  }

  static Product? findProduct(String? raw) {
    final target = raw?.trim().toLowerCase();
    if (target == null || target.isEmpty) return null;
    for (final p in ProductData.sampleProducts) {
      if (p.id.toLowerCase() == target || p.code.toLowerCase() == target) {
        return p;
      }
    }
    return null;
  }

  static String clanRoute(ClanCategory clan) => '/shop/${clanSlug(clan)}';

  static String clanRouteForProduct(Product product) {
    final clan = findClan(product.clan);
    return clan != null ? clanRoute(clan) : '/shop';
  }

  static String productRoute(Product product, {String? option}) {
    final clan = findClan(product.clan);
    final base = clan != null ? '/shop/${clanSlug(clan)}/${product.id}' : '/shop/product/${product.id}';
    if (option != null && option.isNotEmpty && option != 'Cover & Insert') {
      return '$base?option=${Uri.encodeQueryComponent(option)}';
    }
    return base;
  }

  static String productRouteById(String productId) {
    final product = findProduct(productId);
    return product != null ? productRoute(product) : '/shop/product/$productId';
  }

  static String accountTabRoute(AccountTab tab) => '/account/${tab.name}';

  static Widget buildPage(String route, Function(String) onNavigate) {
    final uri = Uri.tryParse(route);
    final segments = uri?.pathSegments ?? const <String>[];
    final head = segments.isEmpty ? '' : segments.first.toLowerCase();

    switch (head) {
      case '':
        return HomePage(onNavigate: onNavigate);
      case 'services':
        return ServicesPage(onNavigate: onNavigate);
      case 'projects':
      case 'gallery':
        return GalleryPage(onNavigate: onNavigate);
      case 'product':
        return ShopPage(
          onNavigate: onNavigate,
          initialProductId: segments.length >= 2 ? segments[1] : uri?.queryParameters['product'],
          initialOption: uri?.queryParameters['option'],
        );
      case 'shop':
        String? clanParam = uri?.queryParameters['clan'];
        String? productParam = uri?.queryParameters['product'];
        if (segments.length >= 3) {
          if (segments[1].toLowerCase() == 'product') {
            productParam = segments[2];
          } else {
            clanParam = segments[1];
            productParam = segments[2];
          }
        } else if (segments.length == 2) {
          final seg = segments[1];
          if (findProduct(seg) != null) {
            productParam = seg;
          } else {
            clanParam = seg;
          }
        }
        return ShopPage(
          onNavigate: onNavigate,
          initialClanName: clanParam,
          initialProductId: productParam,
          initialOption: uri?.queryParameters['option'],
        );
      case 'founder':
        return FounderPage(onNavigate: onNavigate);
      case 'contact':
        return ContactPage(onNavigate: onNavigate);
      case 'sign-in':
        return SignInPage(
          onNavigate: onNavigate,
          initialMode: authModeFromQuery(uri?.queryParameters['mode']),
          returnRoute: uri?.queryParameters['return'],
        );
      case 'account':
        final tab = segments.length >= 2 ? segments[1] : uri?.queryParameters['tab'];
        return AccountPage(onNavigate: onNavigate, initialTab: tab);
      case 'checkout':
        return CheckoutPage(onNavigate: onNavigate);
      default:
        return HomePage(onNavigate: onNavigate);
    }
  }
}
