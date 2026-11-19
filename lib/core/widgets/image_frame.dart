import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'hover_image.dart';

class ImageFrameWithAccent extends StatelessWidget {
  final String imageUrl;
  final Color accentColor;
  final double width;
  final double height;
  final double offsetDx;
  final double offsetDy;
  final double aspectRatio;

  const ImageFrameWithAccent({
    super.key,
    required this.imageUrl,
    this.accentColor = DesignTokens.burntOrange,
    this.width = 300,
    this.height = 380,
    this.offsetDx = 40,
    this.offsetDy = 30,
    this.aspectRatio = 4 / 5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width + offsetDx,
      height: height + offsetDy,
      child: Stack(
        children: [
          // Solid Overlapping Color Block
          Positioned(
            right: 0,
            bottom: 0,
            width: width * 0.85,
            height: height * 0.85,
            child: Container(
              color: accentColor,
            ),
          ),
          // Main Image Frame
          Positioned(
            left: 0,
            top: 0,
            width: width,
            height: height,
            child: HoverImage(
              imageUrl: imageUrl,
              aspectRatio: aspectRatio,
            ),
          ),
        ],
      ),
    );
  }
}
