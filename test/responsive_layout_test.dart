import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sage_studio/core/routing/app_router.dart';
import 'package:sage_studio/core/services/auth_service.dart';
import 'package:sage_studio/core/theme/app_theme.dart';
import 'package:sage_studio/features/navigation/site_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const routes = <String>[
    '/',
    '/services',
    '/gallery',
    '/shop',
    '/shop?product=ss-bos-002',
    '/founder',
    '/contact',
    '/sign-in',
    '/account',
    '/checkout',
  ];

  const viewports = <String, Size>{
    'phone-small (320px)': Size(320, 800),
    'phone-standard (375px)': Size(375, 812),
    'tablet-portrait (768px)': Size(768, 1024),
    'tablet-landscape (1024px)': Size(1024, 900),
    'pc-laptop (1280px)': Size(1280, 900),
    'pc-desktop (1440px)': Size(1440, 900),
    'pc-wide (1920px)': Size(1920, 1080),
  };

  Future<void> pumpRouteAndResize(
    WidgetTester tester,
    String route,
    Size initialSize, {
    List<Size> resizeSteps = const [],
  }) async {
    tester.view.physicalSize = initialSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: SiteHeader(activeRoute: route, onNavigate: (_) {}),
          body: AppRouter.buildPage(route, (_) {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    for (final nextSize in resizeSteps) {
      tester.view.physicalSize = nextSize;
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(tester.takeException(), isNull);

    // Unmount to stop any repeating animations (e.g., marquee ticker) before test teardown.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('All routes render cleanly across phone, tablet, and PC widths', () {
    for (final route in routes) {
      for (final entry in viewports.entries) {
        testWidgets('$route at ${entry.key}', (tester) async {
          await pumpRouteAndResize(tester, route, entry.value);
        });
      }

      testWidgets('$route handles live width adjustment (phone -> tablet -> PC -> phone)', (tester) async {
        await pumpRouteAndResize(
          tester,
          route,
          const Size(320, 800),
          resizeSteps: const [
            Size(375, 812),
            Size(768, 1024),
            Size(1024, 900),
            Size(1280, 900),
            Size(1440, 900),
            Size(1920, 1080),
            Size(375, 812),
          ],
        );
      });
    }
  });

  group('Signed-in Account & Checkout routes handle live width adjustment', () {
    testWidgets('signed-in /account and /checkout resize cleanly', (tester) async {
      addTearDown(() => AuthService.instance.debugSetState(status: AuthStatus.unconfigured));
      AuthService.instance.debugSetState(
        status: AuthStatus.signedIn,
        user: const User(
          id: '00000000-0000-4000-8000-000000000099',
          appMetadata: {},
          userMetadata: {'full_name': 'Amina Wambui'},
          aud: 'authenticated',
          createdAt: '2026-01-01T00:00:00Z',
          email: 'amina@sagestudio.co.ke',
        ),
      );

      for (final route in ['/account', '/checkout']) {
        await pumpRouteAndResize(
          tester,
          route,
          const Size(320, 800),
          resizeSteps: const [
            Size(768, 1024),
            Size(1440, 900),
            Size(375, 812),
          ],
        );
      }
    });
  });
}
