import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sage_studio/core/widgets/social_links_row.dart';
import 'package:sage_studio/features/contact/contact_page.dart';
import 'package:sage_studio/features/founder/founder_page.dart';
import 'package:sage_studio/features/gallery/gallery_page.dart';
import 'package:sage_studio/features/home/widgets/footer_section.dart';
import 'package:sage_studio/features/services/services_page.dart';
import 'package:sage_studio/features/shop/shop_page.dart';

void main() {
  test('kSageSocialLinks contains all 4 required URLs', () {
    final urlsByPlatform = {
      for (final item in kSageSocialLinks) item.platform: item.url,
    };

    expect(
      urlsByPlatform[SocialPlatform.tiktok],
      'https://www.tiktok.com/@sagestudio.ke?_r=1&_t=ZS-9BfWeylJHGB',
    );
    expect(
      urlsByPlatform[SocialPlatform.instagram],
      'https://www.instagram.com/sagestudio.ke?gwpx=aWpueTY2MGZpMGQ4',
    );
    expect(
      urlsByPlatform[SocialPlatform.facebook],
      'https://www.facebook.com/sagestudio.ke',
    );
    expect(
      urlsByPlatform[SocialPlatform.youtube],
      'https://www.youtube.com/@sagestudio.254',
    );
  });

  testWidgets('FooterSection renders all 4 social media icon buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FooterSection(onNavigate: (_) {}),
          ),
        ),
      ),
    );

    expect(find.byType(SocialLinksRow), findsOneWidget);
    expect(find.byTooltip('TikTok'), findsOneWidget);
    expect(find.byTooltip('Instagram'), findsOneWidget);
    expect(find.byTooltip('Facebook'), findsOneWidget);
    expect(find.byTooltip('YouTube'), findsOneWidget);
  });

  testWidgets('ContactPage renders all 4 social media icon buttons and FooterSection', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContactPage(onNavigate: (_) {}),
        ),
      ),
    );

    expect(find.byType(FooterSection), findsOneWidget);
    expect(find.byType(SocialLinksRow), findsNWidgets(2));
    expect(find.byTooltip('TikTok'), findsNWidgets(2));
    expect(find.byTooltip('Instagram'), findsNWidgets(2));
    expect(find.byTooltip('Facebook'), findsNWidgets(2));
    expect(find.byTooltip('YouTube'), findsNWidgets(2));
  });

  testWidgets('Main pages render FooterSection', (tester) async {
    for (final page in [
      ServicesPage(onNavigate: (_) {}),
      GalleryPage(onNavigate: (_) {}),
      FounderPage(onNavigate: (_) {}),
      ShopPage(onNavigate: (_) {}),
    ]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
      expect(find.byType(FooterSection), findsOneWidget);
    }
  });
}
