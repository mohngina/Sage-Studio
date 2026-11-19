import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: DesignTokens.primaryBackground,
      colorScheme: const ColorScheme.light(
        primary: DesignTokens.textPrimary,
        secondary: DesignTokens.oliveAccent,
        surface: DesignTokens.primaryBackground,
        tertiary: DesignTokens.burntOrange,
      ),
      dividerTheme: const DividerThemeData(
        color: DesignTokens.borderLight,
        thickness: 1.0,
        space: 1.0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: DesignTokens.primaryBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.subTitle(),
        iconTheme: const IconThemeData(color: DesignTokens.textPrimary),
      ),
    );
  }
}
