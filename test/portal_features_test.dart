import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sage_studio/core/services/auth_service.dart';
import 'package:sage_studio/core/services/catalogue_lookup.dart';
import 'package:sage_studio/core/services/order_docx_service.dart';
import 'package:sage_studio/core/services/portal_repositories.dart';
import 'package:sage_studio/data/product_data.dart';
import 'package:sage_studio/features/account/account_page.dart';
import 'package:sage_studio/features/checkout/checkout_page.dart';
import 'package:sage_studio/features/shop/cart_controller.dart';
import 'package:sage_studio/features/shop/favourites_controller.dart';
import 'package:sage_studio/features/shop/product_detail_page.dart';
import 'package:sage_studio/features/shop/widgets/favourite_button.dart';
import 'package:sage_studio/features/shop/widgets/product_reviews_section.dart';
import 'package:sage_studio/models/portal_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeCartBackend implements CartBackend {
  final Map<String, RemoteCartLine> lines = {};

  String _key(String p, String v) => '$p::$v';

  @override
  Future<List<RemoteCartLine>> fetch() async => lines.values.toList();

  @override
  Future<void> upsert(String productId, String variant, int quantity) async {
    lines[_key(productId, variant)] = RemoteCartLine(productId, variant, quantity);
  }

  @override
  Future<void> remove(String productId, String variant) async {
    lines.remove(_key(productId, variant));
  }

  @override
  Future<void> clear() async => lines.clear();
}

class _FakeFavouritesBackend implements FavouritesBackend {
  final Set<String> saved = {};
  bool shouldFail = false;

  @override
  Future<List<String>> fetch() async => saved.toList();

  @override
  Future<void> add(String productId) async {
    if (shouldFail) throw Exception('network');
    saved.add(productId);
  }

  @override
  Future<void> remove(String productId) async {
    if (shouldFail) throw Exception('network');
    saved.remove(productId);
  }
}

User _fakeUser() => const User(
      id: '00000000-0000-4000-8000-000000000099',
      appMetadata: {},
      userMetadata: {'full_name': 'Amina Wambui'},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
      email: 'amina@sagestudio.co.ke',
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.instance.debugSetState(status: AuthStatus.unconfigured);
    CartController.instance.debugConfigure(backend: _FakeCartBackend());
    FavouritesController.instance.debugConfigure(backend: _FakeFavouritesBackend());
  });

  group('Existing catalogue integrity & CatalogueLookup', () {
    test('all 55 existing products resolve intact with unmodified prices', () {
      expect(ProductData.sampleProducts.length, 55);
      for (final p in ProductData.sampleProducts) {
        final lookedUp = CatalogueLookup.byId(p.id);
        expect(lookedUp, isNotNull);
        expect(lookedUp!.priceKsh, p.priceKsh);
        expect(lookedUp.code, p.code);
      }
    });

    test('pillow variants resolve cover-insert and cover-only prices accurately', () {
      const pillow = ProductData.sageSelectPillowBrownDiamond;
      final coverOnly = pillow.withPillowOption('Cover only');
      final parsed = CatalogueLookup.parseLineId(coverOnly.id);
      expect(parsed.productId, pillow.id);
      expect(parsed.variant, CatalogueLookup.coverOnly);

      final resolved = CatalogueLookup.resolve(parsed.productId, parsed.variant);
      expect(resolved, isNotNull);
      expect(resolved!.priceKsh, pillow.coverOnlyPriceKsh);
    });
  });

  group('CartController persistence & calculations', () {
    test('adds, updates, calculates totals, and clears cart', () {
      final cart = CartController.instance;
      cart.addToCart(ProductData.bosibori3Seater, quantity: 2);
      expect(cart.totalItemCount, 2);
      expect(cart.totalPrice, ProductData.bosibori3Seater.priceKsh * 2);

      cart.updateQuantity(ProductData.bosibori3Seater.id, 1);
      expect(cart.totalItemCount, 1);
      expect(cart.totalPrice, ProductData.bosibori3Seater.priceKsh);

      cart.removeFromCart(ProductData.bosibori3Seater.id);
      expect(cart.items, isEmpty);
    });
  });

  group('FavouritesController', () {
    test('requires sign-in to toggle favourites', () async {
      final err = await FavouritesController.instance.toggle('ss-bos-002');
      expect(err, isNotNull);
      expect(FavouritesController.instance.isFavourite('ss-bos-002'), isFalse);
    });

    test('signed-in user can add and remove favourites and rolls back on backend error', () async {
      final fake = _FakeFavouritesBackend();
      FavouritesController.instance.debugConfigure(backend: fake);
      AuthService.instance.debugSetState(status: AuthStatus.signedIn, user: _fakeUser());

      final err1 = await FavouritesController.instance.toggle('ss-bos-002');
      expect(err1, isNull);
      expect(FavouritesController.instance.isFavourite('ss-bos-002'), isTrue);
      expect(fake.saved.contains('ss-bos-002'), isTrue);

      // Simulate backend failure -> rolls back optimistic state
      fake.shouldFail = true;
      final err2 = await FavouritesController.instance.toggle('ss-bos-002');
      expect(err2, isNotNull);
      expect(FavouritesController.instance.isFavourite('ss-bos-002'), isTrue);
    });
  });

  group('Order status & formatting rules', () {
    test('pending_payment orders are never marked as completed purchases', () {
      final pending = CustomerOrder.fromMap({
        'id': 'ord-1',
        'order_ref': 'SS-261119-ABC123',
        'status': 'pending_payment',
        'subtotal_ksh': 111360,
        'total_ksh': 111360,
        'contact_name': 'Amina',
        'contact_email': 'amina@example.com',
        'contact_phone': '+254700000000',
        'delivery_address': {'line1': 'Karen', 'city': 'Nairobi'},
      });
      expect(pending.isCompletedPurchase, isFalse);

      final paid = CustomerOrder.fromMap({
        'id': 'ord-2',
        'order_ref': 'SS-261119-PAID99',
        'status': 'paid',
        'subtotal_ksh': 111360,
        'total_ksh': 111360,
        'contact_name': 'Amina',
        'contact_email': 'amina@example.com',
        'contact_phone': '+254700000000',
        'delivery_address': {'line1': 'Karen', 'city': 'Nairobi'},
      });
      expect(paid.isCompletedPurchase, isTrue);
      expect(formatKsh(111360), 'KSH 111,360');
    });
  });

  group('Portal widgets (FavouriteButton, AccountPage tabs, CheckoutPage)', () {
    testWidgets('signed-out visitor tapping FavouriteButton gets sign-in prompt with return route', (tester) async {
      AuthService.instance.debugSetState(status: AuthStatus.signedOut);
      String? navigated;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FavouriteButton(
            productId: 'ss-bos-002',
            productTitle: 'the BOSIBORI sofa',
            returnRoute: '/shop?product=ss-bos-002',
            onNavigate: (r) => navigated = r,
          ),
        ),
      ));
      await tester.tap(find.byType(FavouriteButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sign in or create an account'), findsOneWidget);
      await tester.tap(find.text('SIGN IN'));
      await tester.pumpAndSettle();
      expect(navigated, '/sign-in?return=${Uri.encodeComponent('/shop?product=ss-bos-002')}');
    });

    testWidgets('signed-in AccountPage switches cleanly between Profile, Cart, Favourites, History & Pending tabs',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      AuthService.instance.debugSetState(status: AuthStatus.signedIn, user: _fakeUser());
      FavouritesController.instance.debugConfigure(
        backend: _FakeFavouritesBackend(),
        seedIds: ['ss-bos-002'],
      );
      CartController.instance.addToCart(ProductData.bosibori3Seater, quantity: 1);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AccountPage(onNavigate: (_) {})),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Welcome, Amina Wambui'), findsOneWidget);
      expect(find.text('PERSONAL DETAILS'), findsOneWidget);

      await tester.tap(find.text('CART (1)'));
      await tester.pumpAndSettle();
      expect(find.text('YOUR SHOPPING CART (1)'), findsOneWidget);

      await tester.tap(find.text('FAVOURITES (1)'));
      await tester.pumpAndSettle();
      expect(find.text('SAVED PIECES (1)'), findsOneWidget);
      expect(find.text('the BOSIBORI sofa'), findsOneWidget);

      await tester.tap(find.text('HISTORY'));
      await tester.pumpAndSettle();
      expect(find.text('PURCHASE HISTORY'), findsOneWidget);

      await tester.tap(find.text('PENDING ORDERS'));
      await tester.pumpAndSettle();
      expect(find.text('PENDING & UNPAID ORDERS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CheckoutPage shows Place Order for studio clan products and validates required fields',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      AuthService.instance.debugSetState(status: AuthStatus.signedIn, user: _fakeUser());
      CartController.instance.addToCart(ProductData.bosibori3Seater, quantity: 1);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CheckoutPage(onNavigate: (_) {})),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Word (.docx)'), findsNothing);
      expect(find.text('ORDER SUMMARY'), findsOneWidget);
      expect(find.text('KSH 111,360'), findsWidgets);

      await tester.tap(find.text('PLACE ORDER'));
      await tester.pump();
      expect(find.text('Please enter a contact phone number.'), findsOneWidget);
      expect(find.text('Delivery address is required.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CheckoutPage shows M-Pesa notice and MAKE PAYMENT button for Sage Select-only cart', (tester) async {
      tester.view.physicalSize = const Size(1440, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      AuthService.instance.debugSetState(status: AuthStatus.signedIn, user: _fakeUser());
      CartController.instance.addToCart(
        ProductData.sageSelectPillowBrownDiamond.withPillowOption('Cover & Insert'),
        quantity: 1,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CheckoutPage(onNavigate: (_) {})),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Payment is via M-Pesa only'), findsOneWidget);
      expect(find.text('MAKE PAYMENT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CheckoutPage keeps Place Order when cart mixes studio clan and Sage Select items', (tester) async {
      tester.view.physicalSize = const Size(1440, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      AuthService.instance.debugSetState(status: AuthStatus.signedIn, user: _fakeUser());
      CartController.instance.addToCart(ProductData.bosibori3Seater, quantity: 1);
      CartController.instance.addToCart(
        ProductData.sageSelectPillowBrownDiamond.withPillowOption('Cover & Insert'),
        quantity: 1,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CheckoutPage(onNavigate: (_) {})),
      ));
      await tester.pumpAndSettle();

      expect(find.text('PLACE ORDER'), findsOneWidget);
      expect(find.text('MAKE PAYMENT'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    test('OrderDocxService generates valid .docx containing order ref, customer details, and products', () {
      final bytes = OrderDocxService.generateOrderDocx(
        orderRef: 'SS-261119-ORDER1',
        fullName: 'Morris Muriithi',
        email: 'morrismuriithi3@gmail.com',
        phone: '+254707971371',
        deliveryAddress: {'line1': 'Collimore Lane', 'city': 'Nairobi', 'country': 'Kenya'},
        notes: 'Natural oak finish',
        items: [CartItem(product: ProductData.bosibori3Seater, quantity: 1)],
        totalKsh: ProductData.bosibori3Seater.priceKsh,
        timestamp: DateTime(2026, 11, 19, 14, 15),
      );

      final archive = ZipDecoder().decodeBytes(bytes);
      final docXmlFile = archive.findFile('word/document.xml');
      expect(docXmlFile, isNotNull);
      final xmlText = utf8.decode(docXmlFile!.content as List<int>);
      expect(xmlText, contains('SS-261119-ORDER1'));
      expect(xmlText, contains('Morris Muriithi'));
      expect(xmlText, contains('the BOSIBORI sofa'));
      expect(xmlText, contains('sagestudio.ke@gmail.com'));
    });

    testWidgets('ProductReviewsSection starts with 5 blank stars and fills stars when clicked', (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      AuthService.instance.debugSetState(status: AuthStatus.signedIn, user: _fakeUser());

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProductReviewsSection(
              product: ProductData.bosibori3Seater,
              onNavigate: (_) {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Initially all 5 stars in the header are blank (star_border)
      expect(find.byIcon(Icons.star_border), findsNWidgets(5));
      expect(find.byIcon(Icons.star), findsNothing);

      // Open the review form: all 5 form stars also start blank
      await tester.tap(find.text('WRITE A REVIEW'));
      await tester.pumpAndSettle();
      expect(find.text('Click a star to rate (1–5)'), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsNWidgets(10)); // 5 in header + 5 in form

      // Click the 4th star in the form -> 4 stars fill in form (and header reflects 4)
      final blankStars = find.byIcon(Icons.star_border);
      await tester.tap(blankStars.at(8)); // index 5..9 are the form stars; 8 is the 4th star
      await tester.pump();
      expect(find.text('4 of 5 stars selected'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNWidgets(8)); // 4 filled in header + 4 filled in form
    });

    testWidgets('ProductDetailPage Add to Cart button toggles to Added to cart and removes on second tap',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProductDetailPage(
            product: ProductData.bosibori3Seater,
            onNavigate: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('ADD TO CART'), findsOneWidget);
      expect(CartController.instance.contains(ProductData.bosibori3Seater.id), isFalse);

      await tester.tap(find.text('ADD TO CART'));
      await tester.pump();
      expect(find.text('ADDED TO CART'), findsOneWidget);
      expect(CartController.instance.contains(ProductData.bosibori3Seater.id), isTrue);

      await tester.tap(find.text('ADDED TO CART'));
      await tester.pump();
      expect(find.text('ADD TO CART'), findsOneWidget);
      expect(CartController.instance.contains(ProductData.bosibori3Seater.id), isFalse);
    });
  });
}
