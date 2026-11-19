import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/typography.dart';
import 'thin_rule.dart';

class SectionHeading extends StatelessWidget {
  final String title;
  final String? label;
  final Widget? action;

  const SectionHeading({
    super.key,
    required this.title,
    this.label,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent),
          ),
          const SizedBox(height: DesignTokens.sm),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.sectionTitle(),
              ),
            ),
            if (action != null) action!,
          ],
        ),
        const SizedBox(height: DesignTokens.md),
        const ThinRule(),
      ],
    );
  }
}
