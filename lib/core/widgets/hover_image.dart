import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class HoverImage extends StatefulWidget {
  final String imageUrl;
  final double aspectRatio;
  final BoxFit fit;
  final Widget? overlay;

  const HoverImage({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 4 / 5,
    this.fit = BoxFit.cover,
    this.overlay,
  });

  @override
  State<HoverImage> createState() => _HoverImageState();
}

class _HoverImageState extends State<HoverImage> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isNetwork = widget.imageUrl.startsWith('http://') || widget.imageUrl.startsWith('https://');

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: ClipRRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.04 : 1.0,
                duration: DesignTokens.durationEditorial,
                curve: DesignTokens.editorialEase,
                child: isNetwork
                    ? Image.network(
                        widget.imageUrl,
                        fit: widget.fit,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: DesignTokens.softBackground,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.oliveAccent),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: DesignTokens.softBackground,
                            child: const Center(
                              child: Icon(Icons.image_not_supported_outlined, color: DesignTokens.textMuted),
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        widget.imageUrl,
                        fit: widget.fit,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            'assets/${widget.imageUrl}',
                            fit: widget.fit,
                            errorBuilder: (context, err2, stack2) {
                              return Image.network(
                                widget.imageUrl,
                                fit: widget.fit,
                                errorBuilder: (context, err3, stack3) {
                                  return Container(
                                    color: DesignTokens.softBackground,
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported_outlined, color: DesignTokens.textMuted),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
              if (widget.overlay != null) widget.overlay!,
            ],
          ),
        ),
      ),
    );
  }
}
