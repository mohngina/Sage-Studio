import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/sage_button.dart';
import '../../core/widgets/state_views.dart';

/// Shown in place of private content when the visitor is signed out or the
/// portal is not configured. Remembers [returnRoute] so the visitor comes back
/// after signing in.
class SignInRequiredView extends StatelessWidget {
  final String title;
  final String message;
  final String returnRoute;
  final Function(String) onNavigate;

  const SignInRequiredView({
    super.key,
    required this.onNavigate,
    required this.returnRoute,
    this.title = 'Sign in to continue',
    this.message = 'Create an account or sign in to access your client portal.',
  });

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    if (auth.status == AuthStatus.initialising) return const SageLoadingView();
    if (!auth.isConfigured) {
      return SageEmptyView(
        icon: Icons.lock_outline,
        title: 'Accounts are coming soon',
        message: 'Customer accounts are not available yet. You can keep browsing the catalogue in the meantime.',
        actionLabel: 'BROWSE THE SHOP',
        onAction: () => onNavigate('/shop'),
      );
    }
    final encoded = Uri.encodeComponent(returnRoute);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.xxl, horizontal: DesignTokens.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, size: 44, color: DesignTokens.textLight),
              const SizedBox(height: DesignTokens.md),
              Text(title, style: AppTypography.cardTitle(), textAlign: TextAlign.center),
              const SizedBox(height: DesignTokens.sm),
              Text(message, style: AppTypography.bodyMedium(), textAlign: TextAlign.center),
              const SizedBox(height: DesignTokens.lg),
              SageButton(
                text: 'SIGN IN',
                style: SageButtonStyle.primary,
                fullWidth: true,
                onTap: () => onNavigate('/sign-in?return=$encoded'),
              ),
              const SizedBox(height: DesignTokens.md),
              SageButton(
                text: 'CREATE AN ACCOUNT',
                style: SageButtonStyle.primary,
                fullWidth: true,
                onTap: () => onNavigate('/sign-in?mode=register&return=$encoded'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
