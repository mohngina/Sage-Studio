import 'package:flutter/material.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/thin_rule.dart';
import '../../../core/widgets/sage_button.dart';
import '../../../models/portal_models.dart';
import '../cart_controller.dart';

class CartDrawer extends StatelessWidget {
  final Function(String)? onNavigate;

  const CartDrawer({super.key, this.onNavigate});

  static void show(BuildContext context, {Function(String)? onNavigate}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cart',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: DesignTokens.durationStandard,
      pageBuilder: (context, anim1, anim2) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: CartDrawer(onNavigate: onNavigate),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final drawerWidth = width < 500 ? width : 440.0;

    return Material(
      color: DesignTokens.primaryBackground,
      child: Container(
        width: drawerWidth,
        height: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.xl),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: DesignTokens.borderLight, width: 1.0)),
        ),
        child: ListenableBuilder(
          listenable: CartController.instance,
          builder: (context, _) {
            final cart = CartController.instance;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'YOUR CART (${cart.totalItemCount})',
                      style: AppTypography.subTitle(),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cart.items.isNotEmpty)
                          TextButton(
                            onPressed: cart.clearCart,
                            child: Text(
                              'CLEAR',
                              style: AppTypography.labelUppercase(color: DesignTokens.textMuted).copyWith(fontSize: 10),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: DesignTokens.textPrimary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.md),
                const ThinRule(),
                const SizedBox(height: DesignTokens.lg),
                Expanded(
                  child: cart.items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shopping_bag_outlined, size: 48, color: DesignTokens.textMuted),
                              const SizedBox(height: DesignTokens.md),
                              Text('Your cart is empty', style: AppTypography.bodyMedium()),
                              const SizedBox(height: DesignTokens.sm),
                              Text('Explore our curated handcrafted collections', style: AppTypography.bodySmall()),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: cart.items.length,
                          separatorBuilder: (_, __) => const ThinRule(verticalMargin: DesignTokens.md),
                          itemBuilder: (context, index) {
                            final item = cart.items[index];
                            return Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    onNavigate?.call(AppRouter.productRoute(item.product));
                                  },
                                  child: ClipRRect(
                                    child: item.product.mainImage.startsWith('http')
                                        ? Image.network(
                                            item.product.mainImage,
                                            width: 70,
                                            height: 85,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            item.product.mainImage,
                                            width: 70,
                                            height: 85,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: DesignTokens.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          onNavigate?.call(AppRouter.productRoute(item.product));
                                        },
                                        child: Text(item.product.title, style: AppTypography.cardTitle()),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(item.product.subtitle,
                                          style: AppTypography.bodySmall(color: DesignTokens.oliveAccent)),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Unit: ${formatKsh(item.product.priceKsh)} • Line: ${formatKsh(item.lineTotal)}',
                                        style: AppTypography.bodySmall(color: DesignTokens.burntOrange)
                                            .copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 14),
                                            onPressed: () => cart.updateQuantity(item.product.id, item.quantity - 1),
                                          ),
                                          Text('${item.quantity}', style: AppTypography.bodyMedium()),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 14),
                                            onPressed: () => cart.updateQuantity(item.product.id, item.quantity + 1),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: DesignTokens.textMuted),
                                  onPressed: () => cart.removeFromCart(item.product.id),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                if (cart.items.isNotEmpty) ...[
                  const ThinRule(verticalMargin: DesignTokens.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal', style: AppTypography.bodyMedium()),
                      Text(formatKsh(cart.totalPrice), style: AppTypography.subTitle(color: DesignTokens.burntOrange)),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.lg),
                  SageButton(
                    text: 'PROCEED TO CHECKOUT',
                    style: SageButtonStyle.burntOrange,
                    fullWidth: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (onNavigate != null) {
                        onNavigate!('/checkout');
                      }
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
