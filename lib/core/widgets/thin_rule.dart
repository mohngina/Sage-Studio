import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class ThinRule extends StatelessWidget {
  final Color color;
  final double height;
  final double verticalMargin;

  const ThinRule({
    super.key,
    this.color = DesignTokens.borderLight,
    this.height = 1.0,
    this.verticalMargin = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: verticalMargin),
      height: height,
      color: color,
    );
  }
}
