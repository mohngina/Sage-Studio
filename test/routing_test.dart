import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sage_studio/core/routing/app_router.dart';
import 'package:sage_studio/core/theme/app_theme.dart';
import 'package:sage_studio/data/product_data.dart';
import 'package:sage_studio/features/account/account_page.dart';
import 'package:sage_studio/features/checkout/checkout_page.dart';
import 'package:sage_studio/features/shop/product_detail_page.dart';
import 'package:sage_studio/features/shop/shop_page.dart';

void main() {
  group('AppRouter clan & product routes', () {
    test('every clan in ProductData has a unique slug and resolves via /shop/<slug>', () {
      final slugs = <String>{};
      for (final clan in ProductData.sampleClans) {
        final route = AppRouter.clanRoute(clan);
        expect(route, startsWith('/shop/'));
        final slug = AppRouter.clanSlug(clan);
        expect(slugs.add(slug), isTrue, reason: 'Duplicate clan slug: $slug');
        expect(AppRouter.findClan(slug)?.id, clan.id);
        expect(AppRouter.findClan(clan.id)?.id, clan.id);
        expect(AppRouter.findClan(clan.name)?.id, clan.id);
      }
    });

    test('every product in ProductData resolves to its clan+product route', () {
      for (final product in ProductData.sampleProducts) {
        final route = AppRouter.productRoute(product);
        final clan = AppRouter.findClan(product.clan);
        expect(clan, isNotNull, reason: 'Missing clan for ${product.id}: ${product.clan}');
        expect(route, '/shop/${AppRouter.clanSlug(clan!)}/${product.id}');

        final page = AppRouter.buildPage(route, (_) {});
        expect(page, isA<ShopPage>());
        final shop = page as ShopPage;
        expect(shop.initialProductId, product.id);
        expect(shop.initialClanName, AppRouter.clanSlug(clan));

        final shortPage = AppRouter.buildPage('/product/${product.id}', (_) {}) as ShopPage;
        expect(shortPage.initialProductId, product.id);

        final shopDirectPage = AppRouter.buildPage('/shop/${product.id}', (_) {}) as ShopPage;
        expect(shopDirectPage.initialProductId, product.id);
      }
    });

    test('all client portal tab routes and /checkout resolve cleanly', () {
      for (final tab in AccountTab.values) {
        final route = AppRouter.accountTabRoute(tab);
        expect(route, '/account/${tab.name}');
        final page = AppRouter.buildPage(route, (_) {});
        expect(page, isA<AccountPage>());
        expect(accountTabFromQuery((page as AccountPage).initialTab), tab);
      }

      expect(AppRouter.buildPage('/checkout', (_) {}), isA<CheckoutPage>());
    });

    testWidgets('navigating to a clan route and product route renders ShopPage -> ProductDetailPage', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const sampleProduct = ProductData.bosibori3Seater;
      final route = AppRouter.productRoute(sampleProduct);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: AppRouter.buildPage(route, (_) {})),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ProductDetailPage), findsOneWidget);
      expect(find.text(sampleProduct.title), findsWidgets);
    });
  });
}
