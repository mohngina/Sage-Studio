import 'package:flutter/material.dart';
import '../theme/typography.dart';
import '../theme/design_tokens.dart';

class EditorialTitle extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign textAlign;

  const EditorialTitle(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: style ?? AppTypography.heroTitle(color: color ?? DesignTokens.textPrimary),
    );
  }
}

class EditorialLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const EditorialLabel(
    this.text, {
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.labelUppercase(color: color ?? DesignTokens.oliveAccent),
    );
  }
}
