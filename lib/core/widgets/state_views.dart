import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/typography.dart';
import 'sage_button.dart';

/// Consistent loading / empty / error / notice states for portal features,
/// styled with the existing Sage Studio tokens.

class SageLoadingView extends StatelessWidget {
  final String? label;
  const SageLoadingView({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label ?? 'Loading',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.xxl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: DesignTokens.burntOrange),
              ),
              if (label != null) ...[
                const SizedBox(height: DesignTokens.md),
                Text(label!.toUpperCase(), style: AppTypography.labelUppercase(color: DesignTokens.textMuted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SageEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SageEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.xxl, horizontal: DesignTokens.md),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: DesignTokens.textLight),
            const SizedBox(height: DesignTokens.md),
            Text(title, style: AppTypography.cardTitle(), textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: DesignTokens.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(message!, style: AppTypography.bodyMedium(), textAlign: TextAlign.center),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.lg),
              SageButton(text: actionLabel!, style: SageButtonStyle.primary, onTap: onAction!),
            ],
          ],
        ),
      ),
    );
  }
}

class SageErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const SageErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SageEmptyView(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      message: message,
      actionLabel: onRetry != null ? 'TRY AGAIN' : null,
      onAction: onRetry,
    );
  }
}

enum SageNoticeType { info, success, error, warning }

/// Inline banner used for form feedback and status messages.
class SageNotice extends StatelessWidget {
  final String message;
  final SageNoticeType type;
  final VoidCallback? onDismiss;

  const SageNotice({super.key, required this.message, this.type = SageNoticeType.info, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final (Color accent, IconData icon) = switch (type) {
      SageNoticeType.success => (DesignTokens.oliveAccent, Icons.check_circle_outline),
      SageNoticeType.error => (DesignTokens.galleryAccent, Icons.error_outline),
      SageNoticeType.warning => (DesignTokens.burntOrange, Icons.warning_amber_outlined),
      SageNoticeType.info => (DesignTokens.textPrimary, Icons.info_outline),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.md, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: DesignTokens.sm),
            Expanded(child: Text(message, style: AppTypography.bodyMedium(color: DesignTokens.textPrimary))),
            if (onDismiss != null)
              InkWell(
                onTap: onDismiss,
                child: const Padding(
                  padding: EdgeInsets.only(left: DesignTokens.sm),
                  child: Icon(Icons.close, size: 16, color: DesignTokens.textMuted, semanticLabel: 'Dismiss'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Primary action button with a built-in busy state, wrapping [SageButton]
/// so existing button styling is reused.
class SageBusyButton extends StatelessWidget {
  final String text;
  final String busyText;
  final bool busy;
  final VoidCallback onTap;
  final SageButtonStyle style;
  final IconData? icon;

  const SageBusyButton({
    super.key,
    required this.text,
    required this.busyText,
    required this.busy,
    required this.onTap,
    this.style = SageButtonStyle.burntOrange,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !busy,
      child: Opacity(
        opacity: busy ? 0.7 : 1,
        child: AbsorbPointer(
          absorbing: busy,
          child: SageButton(
            text: busy ? busyText : text,
            style: style,
            fullWidth: true,
            icon: busy ? null : icon,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
