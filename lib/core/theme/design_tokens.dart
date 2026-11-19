import 'package:flutter/material.dart';

class DesignTokens {
  // Color Palette from Mood Boards
  static const Color primaryBackground = Color(0xFFFFFFFF); // #FFFFFF
  static const Color softBackground = Color(0xFFE6E3E2); // #E6E3E2
  static const Color sageAccent = Color(0xFFCFD9A3); // #CFD9A3
  static const Color oliveAccent = Color(0xFF725D24); // #725D24
  static const Color burntOrange = Color(0xFFCC5600); // #CC5600
  static const Color galleryAccent = Color(0xFF690400); // #690400
  static const Color textPrimary = Color(0xFF111111); // #111111
  static const Color textMuted = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color footerBackground = Color(0xFF111111);
  static const Color borderLight = Color(0xFFE0DEDC);
  static const Color darkBorder = Color(0xFF333333);

  // Watermark script color
  static const Color watermarkText = Color(0xFFDCD8D5);

  // Spacing Scale
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 40.0;
  static const double xxl = 64.0;
  static const double xxxl = 96.0;
  static const double xxxxl = 144.0;

  // Layout Constraints
  static const double maxContentWidth = 1440.0;
  static const double desktopPadding = 64.0;
  static const double tabletPadding = 32.0;
  static const double mobilePadding = 20.0;

  // Animation Durations
  static const Duration durationMicro = Duration(milliseconds: 150);
  static const Duration durationStandard = Duration(milliseconds: 350);
  static const Duration durationEditorial = Duration(milliseconds: 700);

  // Curves
  static const Curve editorialEase = Curves.easeInOutCubic;
}
