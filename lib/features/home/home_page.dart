import 'package:flutter/material.dart';
import 'widgets/hero_section.dart';
import 'widgets/brand_intro_section.dart';
import 'widgets/collections_section.dart';
import 'widgets/story_section.dart';
import 'widgets/reviews_section.dart';
import 'widgets/footer_section.dart';

class HomePage extends StatelessWidget {
  final Function(String) onNavigate;

  const HomePage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const HeroSection(),
          const BrandIntroSection(),
          CollectionsSection(onNavigate: onNavigate),
          StorySection(onNavigate: onNavigate),
          ReviewsSection(onNavigate: onNavigate),
          FooterSection(onNavigate: onNavigate),
        ],
      ),
    );
  }
}
