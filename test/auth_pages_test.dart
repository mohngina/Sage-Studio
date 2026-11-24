import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sage_studio/core/services/auth_service.dart';
import 'package:sage_studio/features/account/account_page.dart';
import 'package:sage_studio/features/auth/sign_in_page.dart';

Future<void> _pump(WidgetTester tester, Widget child, {Size size = const Size(1440, 1400)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pump();
}

void main() {
  tearDown(() => AuthService.instance.debugSetState(status: AuthStatus.unconfigured));

  group('when Supabase is not configured', () {
    testWidgets('sign-in page shows a graceful notice', (tester) async {
      AuthService.instance.debugSetState(status: AuthStatus.unconfigured);
      await _pump(tester, SignInPage(onNavigate: (_) {}));
      expect(find.text('Accounts are coming soon'), findsOneWidget);
      expect(find.text('BROWSE THE SHOP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('account page does not expose private UI', (tester) async {
      AuthService.instance.debugSetState(status: AuthStatus.unconfigured);
      await _pump(tester, AccountPage(onNavigate: (_) {}));
      expect(find.text('SIGN OUT'), findsNothing);
      expect(find.text('Accounts are coming soon'), findsOneWidget);
    });
  });

  group('when configured but signed out', () {
    setUp(() => AuthService.instance.debugSetState(status: AuthStatus.signedOut));

    testWidgets('empty sign-in shows validation errors without calling the backend', (tester) async {
      await _pump(tester, SignInPage(onNavigate: (_) {}));
      await tester.tap(find.text('SIGN IN'));
      await tester.pump();
      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('register validates name, phone, password strength and confirmation', (tester) async {
      await _pump(tester, SignInPage(onNavigate: (_) {}, initialMode: AuthMode.register));
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(5));
      await tester.enterText(fields.at(1), 'client@example.com');
      await tester.enterText(fields.at(3), 'short');
      await tester.enterText(fields.at(4), 'different');
      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pump();
      expect(find.text('Please enter your full name.'), findsOneWidget);
      expect(find.text('Please enter your phone number.'), findsOneWidget);
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('can switch between sign in, register and reset without obscuring email', (tester) async {
      await _pump(tester, SignInPage(onNavigate: (_) {}));
      expect(find.text('Continue with Google'), findsOneWidget);
      EditableText emailEditable() => tester.widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('auth_email')),
              matching: find.byType(EditableText),
            ),
          );
      expect(emailEditable().obscureText, isFalse);

      await tester.tap(find.text('Create an account'));
      await tester.pump();
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
      expect(emailEditable().obscureText, isFalse);

      await tester.tap(find.text('Sign in').last);
      await tester.pump();
      expect(emailEditable().obscureText, isFalse);

      await tester.tap(find.text('Forgot password?'));
      await tester.pump();
      expect(find.text('SEND RESET LINK'), findsOneWidget);
      expect(find.text('Continue with Google'), findsNothing);
      expect(emailEditable().obscureText, isFalse);
    });

    testWidgets('account page prompts sign-in and preserves return route', (tester) async {
      String? navigated;
      await _pump(tester, AccountPage(onNavigate: (r) => navigated = r, initialTab: 'favourites'));
      expect(find.text('Sign in to continue'), findsOneWidget);
      await tester.tap(find.text('SIGN IN'));
      expect(navigated, '/sign-in?return=${Uri.encodeComponent('/account/favourites')}');
    });

    testWidgets('sign-in page fits on mobile', (tester) async {
      await _pump(tester, SignInPage(onNavigate: (_) {}, initialMode: AuthMode.register), size: const Size(375, 1400));
      expect(tester.takeException(), isNull);
    });
  });
}
