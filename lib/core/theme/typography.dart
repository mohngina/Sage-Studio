import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// AppTypography implements the design specifications:
/// - Headlines Font: French Sage aesthetic (high-contrast editorial serif using Playfair Display / Cormorant Garamond)
/// - Content / Body Font: Glacial Indifference aesthetic (clean geometric sans-serif using Montserrat / Plus Jakarta Sans)
class AppTypography {
  // French Sage - Luxury High-Contrast Serif Headlines
  static TextStyle heroTitle({Color color = DesignTokens.textPrimary}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 56.0,
      fontWeight: FontWeight.w500,
      height: 1.05,
      letterSpacing: -0.5,
      color: color,
    );
  }

  static TextStyle sectionTitle({Color color = DesignTokens.textPrimary}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 42.0,
      fontWeight: FontWeight.w500,
      height: 1.1,
      letterSpacing: -0.5,
      color: color,
    );
  }

  static TextStyle subTitle({Color color = DesignTokens.textPrimary}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 28.0,
      fontWeight: FontWeight.w500,
      height: 1.2,
      letterSpacing: 0.0,
      color: color,
    );
  }

  static TextStyle cardTitle({Color color = DesignTokens.textPrimary}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 22.0,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0.2,
      color: color,
    );
  }

  // Glacial Indifference - Clean Geometric Sans-Serif Body & UI Copy
  static TextStyle bodyLarge({Color color = DesignTokens.textPrimary}) {
    return GoogleFonts.montserrat(
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      height: 1.6,
      letterSpacing: 0.3,
      color: color,
    );
  }

  static TextStyle bodyMedium({Color color = DesignTokens.textMuted}) {
    return GoogleFonts.montserrat(
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      height: 1.6,
      letterSpacing: 0.2,
      color: color,
    );
  }

  static TextStyle bodySmall({Color color = DesignTokens.textMuted}) {
    return GoogleFonts.montserrat(
      fontSize: 12.0,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.3,
      color: color,
    );
  }

  // Uppercase Category & Kicker Labels (Glacial Indifference Wide Tracking)
  static TextStyle labelUppercase({Color color = DesignTokens.textPrimary}) {
    return GoogleFonts.montserrat(
      fontSize: 11.0,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: 2.5,
      color: color,
    );
  }

  // Navigation Links
  static TextStyle navLink({Color color = DesignTokens.textPrimary, bool isActive = false}) {
    return GoogleFonts.montserrat(
      fontSize: 13.0,
      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: 1.8,
      color: color,
    );
  }

  // Watermark Cursive Script Font
  static TextStyle watermarkScript({Color color = DesignTokens.watermarkText}) {
    return GoogleFonts.alexBrush(
      fontSize: 84.0,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }
}
