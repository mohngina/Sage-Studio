import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sage_studio/core/services/auth_service.dart';
import 'package:sage_studio/features/navigation/site_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The header is the shared chrome on every page, so it must fit on all
/// device widths (mobile, tablet, desktop, wide desktop).
void main() {
  const widths = <double>[320, 360, 414, 768, 800, 1024, 1100, 1279, 1280, 1366, 1440, 1920];

  Future<String?> pumpHeader(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    String? navigated;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: SiteHeader(activeRoute: '/', onNavigate: (r) => navigated = r),
        body: const SizedBox.shrink(),
      ),
    ));
    await tester.pump();
    return navigated;
  }

  for (final w in widths) {
    testWidgets('header fits at ${w.toInt()}px', (tester) async {
      await pumpHeader(tester, w);
      expect(tester.takeException(), isNull);
      // Account entry point is always reachable.
      expect(find.byTooltip('Sign in'), findsOneWidget);
      if (w >= SiteHeader.fullNavMinWidth) {
        expect(find.text('SHOP'), findsOneWidget);
      } else {
        expect(find.byIcon(Icons.menu), findsOneWidget);
      }
    });
  }

  testWidgets('signed-out account icon routes to /sign-in and hides favourites', (tester) async {
    String? navigated;
    AuthService.instance.debugSetState(status: AuthStatus.signedOut);
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: SiteHeader(activeRoute: '/', onNavigate: (r) => navigated = r),
        body: const SizedBox.shrink(),
      ),
    ));
    expect(AuthService.instance.isSignedIn, isFalse);
    expect(find.byTooltip('Favourites'), findsNothing);
    await tester.tap(find.byTooltip('Sign in'));
    expect(navigated, '/sign-in');
  });

  testWidgets('signed-in header shows favourites button and routes to favourites tab', (tester) async {
    String? navigated;
    addTearDown(() => AuthService.instance.debugSetState(status: AuthStatus.unconfigured));
    AuthService.instance.debugSetState(
      status: AuthStatus.signedIn,
      user: const User(
        id: '00000000-0000-4000-8000-000000000099',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'amina@sagestudio.co.ke',
      ),
    );
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: SiteHeader(activeRoute: '/', onNavigate: (r) => navigated = r),
        body: const SizedBox.shrink(),
      ),
    ));
    expect(find.byTooltip('Favourites'), findsOneWidget);
    await tester.tap(find.byTooltip('Favourites'));
    expect(navigated, '/account?tab=favourites');
  });
}
