import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/typography.dart';

enum SageButtonStyle { primary, secondary, textLink, burntOrange }

class SageButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final SageButtonStyle style;
  final IconData? icon;
  final bool fullWidth;

  const SageButton({
    super.key,
    required this.text,
    required this.onTap,
    this.style = SageButtonStyle.primary,
    this.icon,
    this.fullWidth = false,
  });

  @override
  State<SageButton> createState() => _SageButtonState();
}

class _SageButtonState extends State<SageButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (widget.style) {
      case SageButtonStyle.primary:
        bg = _isHovered ? DesignTokens.oliveAccent : DesignTokens.textPrimary;
        fg = DesignTokens.primaryBackground;
        border = bg;
        break;
      case SageButtonStyle.secondary:
        bg = _isHovered ? const Color(0xFF5C4A1C) : DesignTokens.oliveAccent;
        fg = DesignTokens.primaryBackground;
        border = bg;
        break;
      case SageButtonStyle.burntOrange:
        bg = _isHovered ? const Color(0xFFA64600) : DesignTokens.burntOrange;
        fg = DesignTokens.primaryBackground;
        border = bg;
        break;
      case SageButtonStyle.textLink:
        bg = Colors.transparent;
        fg = _isHovered ? DesignTokens.burntOrange : DesignTokens.textPrimary;
        border = Colors.transparent;
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: AppTypography.navLink(color: fg),
          ),
        ),
        if (widget.icon != null) ...[
          const SizedBox(width: DesignTokens.sm),
          Icon(widget.icon, size: 14, color: fg),
        ],
      ],
    );

    if (widget.style == SageButtonStyle.textLink) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              content,
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: DesignTokens.durationMicro,
                height: 1,
                width: _isHovered ? 80 : 40,
                color: fg,
              ),
            ],
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DesignTokens.durationStandard,
          curve: DesignTokens.editorialEase,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.xl,
            vertical: DesignTokens.md,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 1.0),
            borderRadius: BorderRadius.zero,
          ),
          child: content,
        ),
      ),
    );
  }
}
