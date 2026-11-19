import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import '../favourites_controller.dart';

/// Heart-shaped toggle to save/remove a product from the customer's favourites.
///
/// If the visitor is not signed in, clicking prompts them to sign in or create
/// an account and remembers [returnRoute] so they return after authentication.
class FavouriteButton extends StatelessWidget {
  final String productId;
  final String productTitle;
  final String returnRoute;
  final Function(String)? onNavigate;
  final bool showLabel;
  final Color? backgroundColor;

  const FavouriteButton({
    super.key,
    required this.productId,
    required this.productTitle,
    this.returnRoute = '/shop',
    this.onNavigate,
    this.showLabel = false,
    this.backgroundColor,
  });

  Future<void> _handleTap(BuildContext context, bool currentlyFav) async {
    final auth = AuthService.instance;
    if (!auth.isSignedIn) {
      await auth.rememberReturnRoute(returnRoute);
      if (!context.mounted) return;
      final encoded = Uri.encodeComponent(returnRoute);
      if (onNavigate != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: DesignTokens.textPrimary,
              content: Text(
                'Sign in or create an account to save "$productTitle" to your favourites.',
                style: AppTypography.bodySmall(color: Colors.white),
              ),
              action: SnackBarAction(
                label: 'SIGN IN',
                textColor: DesignTokens.sageAccent,
                onPressed: () => onNavigate!('/sign-in?return=$encoded'),
              ),
            ),
          );
      }
      return;
    }

    final err = await FavouritesController.instance.toggle(productId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: err != null ? DesignTokens.galleryAccent : DesignTokens.oliveAccent,
          duration: const Duration(seconds: 2),
          content: Text(
            err ?? (currentlyFav ? 'Removed "$productTitle" from favourites.' : 'Saved "$productTitle" to favourites.'),
            style: AppTypography.bodySmall(color: Colors.white),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([FavouritesController.instance, AuthService.instance]),
      builder: (context, _) {
        final isFav = FavouritesController.instance.isFavourite(productId);
        final icon = Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          size: showLabel ? 18 : 20,
          color: isFav ? DesignTokens.burntOrange : DesignTokens.textPrimary,
          semanticLabel: isFav ? 'Remove from favourites' : 'Save to favourites',
        );

        if (showLabel) {
          return OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: backgroundColor ?? Colors.white,
              side: BorderSide(
                color: isFav ? DesignTokens.burntOrange : DesignTokens.borderLight,
              ),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onPressed: () => _handleTap(context, isFav),
            icon: icon,
            label: Text(
              isFav ? 'SAVED TO FAVOURITES' : 'SAVE TO FAVOURITES',
              style: AppTypography.labelUppercase(
                color: isFav ? DesignTokens.burntOrange : DesignTokens.textPrimary,
              ).copyWith(fontSize: 10),
            ),
          );
        }

        return Semantics(
          button: true,
          toggled: isFav,
          label: isFav ? 'Remove $productTitle from favourites' : 'Save $productTitle to favourites',
          child: Material(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.92),
            child: InkWell(
              onTap: () => _handleTap(context, isFav),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: icon,
              ),
            ),
          ),
        );
      },
    );
  }
}
