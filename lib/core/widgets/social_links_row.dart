import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/design_tokens.dart';

enum SocialPlatform { tiktok, instagram, facebook, youtube }

class SocialLinkItem {
  final SocialPlatform platform;
  final String label;
  final String url;

  const SocialLinkItem({
    required this.platform,
    required this.label,
    required this.url,
  });
}

/// Official Sage Studio social media links.
const List<SocialLinkItem> kSageSocialLinks = [
  SocialLinkItem(
    platform: SocialPlatform.tiktok,
    label: 'TikTok',
    url: 'https://www.tiktok.com/@sagestudio.ke?_r=1&_t=ZS-9BfWeylJHGB',
  ),
  SocialLinkItem(
    platform: SocialPlatform.instagram,
    label: 'Instagram',
    url: 'https://www.instagram.com/sagestudio.ke?gwpx=aWpueTY2MGZpMGQ4',
  ),
  SocialLinkItem(
    platform: SocialPlatform.facebook,
    label: 'Facebook',
    url: 'https://www.facebook.com/sagestudio.ke',
  ),
  SocialLinkItem(
    platform: SocialPlatform.youtube,
    label: 'YouTube',
    url: 'https://www.youtube.com/@sagestudio.254',
  ),
];

/// A row of icon buttons linking to Sage Studio's social media pages.
class SocialLinksRow extends StatelessWidget {
  final bool isDark;
  final WrapAlignment alignment;
  final double spacing;

  const SocialLinksRow({
    super.key,
    this.isDark = false,
    this.alignment = WrapAlignment.start,
    this.spacing = DesignTokens.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment,
      spacing: spacing,
      runSpacing: spacing,
      children: kSageSocialLinks
          .map((item) => _SocialIconButton(item: item, isDark: isDark))
          .toList(),
    );
  }
}

class _SocialIconButton extends StatefulWidget {
  final SocialLinkItem item;
  final bool isDark;

  const _SocialIconButton({
    required this.item,
    required this.isDark,
  });

  @override
  State<_SocialIconButton> createState() => _SocialIconButtonState();
}

class _SocialIconButtonState extends State<_SocialIconButton> {
  bool _isHovered = false;

  Future<void> _openLink() async {
    final uri = Uri.parse(widget.item.url);
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseBorderColor =
        widget.isDark ? DesignTokens.darkBorder : DesignTokens.borderLight;
    final hoverBorderColor =
        widget.isDark ? DesignTokens.sageAccent : DesignTokens.burntOrange;
    final baseIconColor =
        widget.isDark ? Colors.white70 : DesignTokens.oliveAccent;
    final hoverIconColor =
        widget.isDark ? Colors.white : DesignTokens.burntOrange;
    final baseBgColor =
        widget.isDark ? Colors.transparent : DesignTokens.softBackground;
    final hoverBgColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : DesignTokens.burntOrange.withValues(alpha: 0.08);

    return Tooltip(
      message: widget.item.label,
      child: Semantics(
        button: true,
        label: 'Visit Sage Studio on ${widget.item.label}',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: _openLink,
            child: AnimatedContainer(
              duration: DesignTokens.durationMicro,
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _isHovered ? hoverBgColor : baseBgColor,
                border: Border.all(
                  color: _isHovered ? hoverBorderColor : baseBorderColor,
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CustomPaint(
                    painter: _SocialIconPainter(
                      platform: widget.item.platform,
                      color: _isHovered ? hoverIconColor : baseIconColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialIconPainter extends CustomPainter {
  final SocialPlatform platform;
  final Color color;

  const _SocialIconPainter({
    required this.platform,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.save();
    canvas.scale(s, s);

    switch (platform) {
      case SocialPlatform.tiktok:
        _paintTikTok(canvas);
        break;
      case SocialPlatform.instagram:
        _paintInstagram(canvas);
        break;
      case SocialPlatform.facebook:
        _paintFacebook(canvas);
        break;
      case SocialPlatform.youtube:
        _paintYouTube(canvas);
        break;
    }

    canvas.restore();
  }

  void _paintTikTok(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(19.59, 6.69)
      ..cubicTo(17.98, 6.69, 16.51, 5.95, 15.55, 4.79)
      ..cubicTo(15.05, 4.19, 14.72, 3.45, 14.63, 2.65)
      ..lineTo(14.63, 2.0)
      ..lineTo(11.35, 2.0)
      ..lineTo(11.35, 15.67)
      ..cubicTo(11.35, 17.28, 10.04, 18.59, 8.43, 18.59)
      ..cubicTo(6.82, 18.59, 5.51, 17.28, 5.51, 15.67)
      ..cubicTo(5.51, 14.06, 6.82, 12.75, 8.43, 12.75)
      ..cubicTo(8.75, 12.75, 9.06, 12.81, 9.35, 12.91)
      ..lineTo(9.35, 9.56)
      ..cubicTo(9.05, 9.51, 8.74, 9.48, 8.43, 9.48)
      ..cubicTo(5.01, 9.48, 2.24, 12.25, 2.24, 15.67)
      ..cubicTo(2.24, 19.09, 5.01, 21.86, 8.43, 21.86)
      ..cubicTo(11.85, 21.86, 14.62, 19.09, 14.62, 15.67)
      ..lineTo(14.62, 8.69)
      ..cubicTo(15.96, 9.65, 17.61, 10.21, 19.39, 10.21)
      ..lineTo(19.59, 10.21)
      ..lineTo(19.59, 6.69)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _paintInstagram(Canvas canvas) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2.5, 2.5, 19.0, 19.0),
      const Radius.circular(5.2),
    );
    canvas.drawRRect(rect, strokePaint);
    canvas.drawCircle(const Offset(12.0, 12.0), 4.2, strokePaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(17.4, 6.6), 1.25, dotPaint);
  }

  void _paintFacebook(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(14.5, 13.5)
      ..lineTo(17.0, 13.5)
      ..lineTo(17.6, 9.8)
      ..lineTo(14.5, 9.8)
      ..lineTo(14.5, 7.6)
      ..cubicTo(14.5, 6.5, 14.9, 5.8, 16.4, 5.8)
      ..lineTo(17.8, 5.8)
      ..lineTo(17.8, 2.5)
      ..cubicTo(17.1, 2.4, 16.0, 2.3, 14.9, 2.3)
      ..cubicTo(12.1, 2.3, 10.3, 4.0, 10.3, 7.2)
      ..lineTo(10.3, 9.8)
      ..lineTo(7.2, 9.8)
      ..lineTo(7.2, 13.5)
      ..lineTo(10.3, 13.5)
      ..lineTo(10.3, 21.8)
      ..lineTo(14.5, 21.8)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _paintYouTube(Canvas canvas) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeJoin = StrokeJoin.round;

    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2.0, 4.8, 20.0, 14.4),
      const Radius.circular(4.2),
    );
    canvas.drawRRect(rect, strokePaint);

    final playPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final play = Path()
      ..moveTo(10.0, 8.8)
      ..lineTo(16.0, 12.0)
      ..lineTo(10.0, 15.2)
      ..close();
    canvas.drawPath(play, playPaint);
  }

  @override
  bool shouldRepaint(covariant _SocialIconPainter oldDelegate) {
    return oldDelegate.platform != platform || oldDelegate.color != color;
  }
}
