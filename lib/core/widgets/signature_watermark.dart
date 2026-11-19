import 'package:flutter/material.dart';

class SignatureWatermark extends StatelessWidget {
  final double fontSize;
  final Color color;

  const SignatureWatermark({
    super.key,
    this.fontSize = 72.0,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.12,
        child: Image.asset(
          'assets/images/logo/sage_studio_logo.png',
          height: fontSize * 2.2,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
