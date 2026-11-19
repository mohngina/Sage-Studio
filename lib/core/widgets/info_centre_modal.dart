import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/typography.dart';
import '../widgets/thin_rule.dart';
import '../../data/content_data.dart';

class InfoCentreModal extends StatelessWidget {
  const InfoCentreModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const InfoCentreModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ContentData.infoCentreItems;

    return Dialog(
      backgroundColor: DesignTokens.primaryBackground,
      insetPadding: const EdgeInsets.all(DesignTokens.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.xxl),
          color: const Color(0xFFE5E2DC), // Soft beige surface from Mood Board 2
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'iNfo Centre',
                      style: AppTypography.heroTitle(color: DesignTokens.textPrimary).copyWith(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: DesignTokens.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.sm),
                Text('ORDERING GUIDELINES & TERMS OF CRAFT',
                    style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent)),
                const SizedBox(height: DesignTokens.md),
                const ThinRule(color: DesignTokens.oliveAccent),
                const SizedBox(height: DesignTokens.xl),
                ...items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final text = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: DesignTokens.oliveAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$idx',
                            style: AppTypography.bodySmall(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.md),
                        Expanded(
                          child: Text(
                            text,
                            style: AppTypography.bodyLarge(color: DesignTokens.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
