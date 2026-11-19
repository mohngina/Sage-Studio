import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sage_studio/app.dart';
import 'package:sage_studio/features/navigation/site_header.dart';

void main() {
  testWidgets('SageStudioApp smoke test (desktop)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SageStudioApp());
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SiteHeader), findsOneWidget);
    expect(find.text('SHOP'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Unmount so the home page marquee loop stops before the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));
  });
}
