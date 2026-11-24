import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/routing/app_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/backend_errors.dart';
import '../../core/services/catalogue_lookup.dart';
import '../../core/services/portal_repositories.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/sage_button.dart';
import '../../core/widgets/sage_text_field.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/thin_rule.dart';
import '../../models/portal_models.dart';
import '../../models/product_model.dart';
import '../auth/sign_in_required_view.dart';
import '../shop/cart_controller.dart';
import '../shop/favourites_controller.dart';
import '../shop/widgets/cart_drawer.dart';

enum AccountTab { profile, cart, favourites, history, pending, reviews }

AccountTab accountTabFromQuery(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'cart':
      return AccountTab.cart;
    case 'favourites':
    case 'favorites':
      return AccountTab.favourites;
    case 'history':
    case 'orders':
      return AccountTab.history;
    case 'pending':
      return AccountTab.pending;
    case 'reviews':
      return AccountTab.reviews;
    default:
      return AccountTab.profile;
  }
}

/// Customer account portal with tabs for Profile, Cart, Favourites,
/// Purchase History (verified paid orders only), Pending Orders, and Reviews.
class AccountPage extends StatefulWidget {
  final Function(String) onNavigate;
  final String? initialTab;

  const AccountPage({super.key, required this.onNavigate, this.initialTab});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late AccountTab _tab = accountTabFromQuery(widget.initialTab);

  @override
  void didUpdateWidget(covariant AccountPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab && widget.initialTab != null) {
      setState(() => _tab = accountTabFromQuery(widget.initialTab));
    }
  }

  void _selectTab(AccountTab tab) {
    setState(() => _tab = tab);
    widget.onNavigate(AppRouter.accountTabRoute(tab));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? DesignTokens.mobilePadding : DesignTokens.desktopPadding,
          vertical: isMobile ? DesignTokens.xl : DesignTokens.xxl,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: DesignTokens.maxContentWidth),
            child: ListenableBuilder(
              listenable: AuthService.instance,
              builder: (context, _) {
                final auth = AuthService.instance;
                if (!auth.isSignedIn) {
                  return SignInRequiredView(
                    onNavigate: widget.onNavigate,
                    returnRoute: _tab == AccountTab.profile ? '/account' : AppRouter.accountTabRoute(_tab),
                    message: 'Sign in to manage your profile, cart, favourites, reviews and orders.',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MY ACCOUNT', style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent)),
                    const SizedBox(height: DesignTokens.sm),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: DesignTokens.lg,
                      runSpacing: DesignTokens.md,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                'Welcome, ${auth.displayName}',
                                style: AppTypography.sectionTitle().copyWith(fontSize: isMobile ? 28 : 38),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(auth.user?.email ?? '', style: AppTypography.bodyMedium()),
                          ],
                        ),
                        Wrap(
                          spacing: DesignTokens.md,
                          runSpacing: DesignTokens.sm,
                          children: [
                            SageButton(
                              text: 'CONTINUE SHOPPING',
                              style: SageButtonStyle.primary,
                              onTap: () => widget.onNavigate('/shop'),
                            ),
                            SageButton(
                              text: 'SIGN OUT',
                              style: SageButtonStyle.primary,
                              icon: Icons.logout,
                              onTap: () async {
                                await AuthService.instance.signOut();
                                widget.onNavigate('/');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.xl),
                    _TabBar(active: _tab, onSelect: _selectTab),
                    const ThinRule(),
                    const SizedBox(height: DesignTokens.xl),
                    switch (_tab) {
                      AccountTab.profile => _ProfileTab(onNavigate: widget.onNavigate),
                      AccountTab.cart => _CartTab(onNavigate: widget.onNavigate),
                      AccountTab.favourites => _FavouritesTab(onNavigate: widget.onNavigate),
                      AccountTab.history => _OrdersTab(
                          completedOnly: true,
                          onNavigate: widget.onNavigate,
                          onSwitchToPending: () => _selectTab(AccountTab.pending),
                        ),
                      AccountTab.pending => _OrdersTab(
                          completedOnly: false,
                          onNavigate: widget.onNavigate,
                          onSwitchToPending: () {},
                        ),
                      AccountTab.reviews => _MyReviewsTab(onNavigate: widget.onNavigate),
                    },
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final AccountTab active;
  final ValueChanged<AccountTab> onSelect;

  const _TabBar({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([CartController.instance, FavouritesController.instance]),
      builder: (context, _) {
        final cartCount = CartController.instance.totalItemCount;
        final favCount = FavouritesController.instance.count;
        final items = <(AccountTab, String, IconData)>[
          (AccountTab.profile, 'MY PROFILE', Icons.person_outline),
          (AccountTab.cart, 'CART ($cartCount)', Icons.shopping_bag_outlined),
          (AccountTab.favourites, 'FAVOURITES ($favCount)', Icons.favorite_border),
          (AccountTab.history, 'HISTORY', Icons.receipt_long_outlined),
          (AccountTab.pending, 'PENDING ORDERS', Icons.hourglass_bottom_outlined),
          (AccountTab.reviews, 'MY REVIEWS', Icons.rate_review_outlined),
        ];

        return Wrap(
          spacing: DesignTokens.sm,
          runSpacing: DesignTokens.xs,
          children: items.map((entry) {
            final isSelected = entry.$1 == active;
            return InkWell(
              onTap: () => onSelect(entry.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? DesignTokens.textPrimary : const Color(0xFFF7F5F2),
                  border: Border.all(
                    color: isSelected ? DesignTokens.textPrimary : DesignTokens.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      entry.$3,
                      size: 16,
                      color: isSelected ? Colors.white : DesignTokens.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.$2,
                      style: AppTypography.labelUppercase(
                        color: isSelected ? Colors.white : DesignTokens.textPrimary,
                      ).copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Profile Tab
// ---------------------------------------------------------------------------
class _ProfileTab extends StatefulWidget {
  final Function(String) onNavigate;
  const _ProfileTab({required this.onNavigate});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _repo = ProfileRepository();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _postal = TextEditingController();
  final _country = TextEditingController();

  CustomerProfile? _profile;
  String? _avatarUrl;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _region.dispose();
    _postal.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final user = AuthService.instance.user;
    if (!AuthService.instance.isClientReady || user == null) {
      _name.text = AuthService.instance.displayName;
      _country.text = 'Kenya';
      setState(() => _loading = false);
      return;
    }
    try {
      final profile = await _repo.fetchOrCreate();
      final signedUrl = await _repo.signedAvatarUrl(profile.avatarPath);
      if (!mounted) return;
      _applyProfile(profile, signedUrl);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = BackendErrors.message(e, fallback: 'Could not load your profile.');
      });
    }
  }

  void _applyProfile(CustomerProfile p, String? signedUrl) {
    final fallbackName = AuthService.instance.displayName;
    _name.text = p.fullName ?? (fallbackName == 'Account' ? '' : fallbackName);
    _phone.text = p.phone ?? '';
    _line1.text = p.addressLine1 ?? '';
    _line2.text = p.addressLine2 ?? '';
    _city.text = p.city ?? '';
    _region.text = p.region ?? '';
    _postal.text = p.postalCode ?? '';
    _country.text = p.country ?? 'Kenya';
    setState(() {
      _profile = p;
      _avatarUrl = signedUrl;
      _loading = false;
    });
  }

  String? _trimOrNull(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final uid = AuthService.instance.user?.id;
    if (uid == null) return;
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    final updated = CustomerProfile(
      id: uid,
      fullName: _trimOrNull(_name),
      phone: _trimOrNull(_phone),
      addressLine1: _trimOrNull(_line1),
      addressLine2: _trimOrNull(_line2),
      city: _trimOrNull(_city),
      region: _trimOrNull(_region),
      postalCode: _trimOrNull(_postal),
      country: _trimOrNull(_country),
      avatarPath: _profile?.avatarPath,
    );
    try {
      final saved = await _repo.save(updated);
      if (!mounted) return;
      setState(() {
        _profile = saved;
        _saving = false;
        _success = 'Your profile has been saved.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = BackendErrors.message(e, fallback: 'Could not save your profile.');
      });
    }
  }

  Future<void> _pickAvatar() async {
    setState(() {
      _error = null;
      _success = null;
    });
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _uploadingAvatar = true);
      final oldPath = _profile?.avatarPath;
      final newPath = await _repo.uploadAvatar(picked);
      final uid = AuthService.instance.user!.id;
      final current = _profile ?? CustomerProfile(id: uid);
      final saved = await _repo.save(CustomerProfile(
        id: uid,
        fullName: current.fullName ?? _trimOrNull(_name),
        phone: current.phone ?? _trimOrNull(_phone),
        addressLine1: current.addressLine1 ?? _trimOrNull(_line1),
        addressLine2: current.addressLine2 ?? _trimOrNull(_line2),
        city: current.city ?? _trimOrNull(_city),
        region: current.region ?? _trimOrNull(_region),
        postalCode: current.postalCode ?? _trimOrNull(_postal),
        country: current.country ?? _trimOrNull(_country),
        avatarPath: newPath,
      ));
      if (oldPath != null && oldPath != newPath) {
        await _repo.deleteAvatar(oldPath);
      }
      final url = await _repo.signedAvatarUrl(newPath);
      if (!mounted) return;
      setState(() {
        _profile = saved;
        _avatarUrl = url;
        _uploadingAvatar = false;
        _success = 'Profile photo updated.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingAvatar = false;
        _error = BackendErrors.message(e, fallback: 'Could not update profile photo.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SageLoadingView(label: 'Loading your profile');
    final email = AuthService.instance.user?.email ?? '';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PERSONAL DETAILS', style: AppTypography.subTitle()),
            const SizedBox(height: DesignTokens.xs),
            Text(
              'Keep your contact and delivery address up to date for seamless studio commissions and deliveries.',
              style: AppTypography.bodyMedium(),
            ),
            const SizedBox(height: DesignTokens.xl),
            // Optional profile photo
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: DesignTokens.softBackground,
                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null
                      ? const Icon(Icons.person_outline, size: 32, color: DesignTokens.oliveAccent)
                      : null,
                ),
                const SizedBox(width: DesignTokens.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PROFILE PHOTO (OPTIONAL)', style: AppTypography.labelUppercase()),
                      const SizedBox(height: 4),
                      Text('JPG, PNG or WEBP up to 2 MB.', style: AppTypography.bodySmall()),
                      const SizedBox(height: DesignTokens.sm),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: DesignTokens.textPrimary),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: _uploadingAvatar ? null : _pickAvatar,
                        child: Text(
                          _uploadingAvatar ? 'UPLOADING…' : 'UPLOAD PHOTO',
                          style: AppTypography.labelUppercase().copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.xl),
            SageTextField(
              label: 'FULL NAME *',
              controller: _name,
              hint: 'e.g. Amina Wambui',
              validator: Validators.fullName,
              autofillHints: const [AutofillHints.name],
              enabled: !_saving,
            ),
            const SizedBox(height: DesignTokens.lg),
            Text('EMAIL ADDRESS (FROM ACCOUNT)', style: AppTypography.labelUppercase()),
            const SizedBox(height: DesignTokens.xs),
            Text(email, style: AppTypography.bodyLarge(color: DesignTokens.textMuted)),
            const SizedBox(height: DesignTokens.lg),
            SageTextField(
              label: 'PHONE NUMBER',
              controller: _phone,
              hint: '+254 700 000000',
              keyboardType: TextInputType.phone,
              validator: Validators.optionalPhone,
              autofillHints: const [AutofillHints.telephoneNumber],
              enabled: !_saving,
            ),
            const SizedBox(height: DesignTokens.xxl),
            Text('DELIVERY & CONTACT ADDRESS', style: AppTypography.subTitle()),
            const SizedBox(height: DesignTokens.lg),
            SageTextField(
              label: 'ADDRESS LINE 1 (STREET / ESTATE / BUILDING)',
              controller: _line1,
              hint: 'e.g. Karen Road, House 14',
              validator: Validators.maxLength(200, field: 'Address line 1'),
              autofillHints: const [AutofillHints.streetAddressLine1],
              enabled: !_saving,
            ),
            const SizedBox(height: DesignTokens.lg),
            SageTextField(
              label: 'ADDRESS LINE 2 (APARTMENT / LANDMARK — OPTIONAL)',
              controller: _line2,
              hint: 'e.g. Near Karen Blixen Museum',
              validator: Validators.maxLength(200, field: 'Address line 2'),
              autofillHints: const [AutofillHints.streetAddressLine2],
              enabled: !_saving,
            ),
            const SizedBox(height: DesignTokens.lg),
            Row(
              children: [
                Expanded(
                  child: SageTextField(
                    label: 'CITY / TOWN',
                    controller: _city,
                    hint: 'e.g. Nairobi',
                    validator: Validators.maxLength(100, field: 'City'),
                    autofillHints: const [AutofillHints.addressCity],
                    enabled: !_saving,
                  ),
                ),
                const SizedBox(width: DesignTokens.lg),
                Expanded(
                  child: SageTextField(
                    label: 'COUNTY / REGION',
                    controller: _region,
                    hint: 'e.g. Nairobi County',
                    validator: Validators.maxLength(100, field: 'Region'),
                    autofillHints: const [AutofillHints.addressState],
                    enabled: !_saving,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.lg),
            Row(
              children: [
                Expanded(
                  child: SageTextField(
                    label: 'POSTAL CODE (OPTIONAL)',
                    controller: _postal,
                    hint: '00502',
                    validator: Validators.maxLength(20, field: 'Postal code'),
                    autofillHints: const [AutofillHints.postalCode],
                    enabled: !_saving,
                  ),
                ),
                const SizedBox(width: DesignTokens.lg),
                Expanded(
                  child: SageTextField(
                    label: 'COUNTRY',
                    controller: _country,
                    hint: 'Kenya',
                    validator: Validators.maxLength(100, field: 'Country'),
                    autofillHints: const [AutofillHints.countryName],
                    enabled: !_saving,
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: DesignTokens.lg),
              SageNotice(type: SageNoticeType.error, message: _error!),
            ],
            if (_success != null) ...[
              const SizedBox(height: DesignTokens.lg),
              SageNotice(type: SageNoticeType.success, message: _success!),
            ],
            const SizedBox(height: DesignTokens.xl),
            SageBusyButton(
              text: 'SAVE PROFILE',
              busyText: 'SAVING…',
              busy: _saving,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Cart Tab
// ---------------------------------------------------------------------------
class _CartTab extends StatelessWidget {
  final Function(String) onNavigate;
  const _CartTab({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartController.instance,
      builder: (context, _) {
        final cart = CartController.instance;
        if (cart.isLoading) return const SageLoadingView(label: 'Syncing your cart');
        if (cart.items.isEmpty) {
          return SageEmptyView(
            icon: Icons.shopping_bag_outlined,
            title: 'Your cart is empty',
            message: 'Browse our handcrafted furniture and decorative collections to add pieces.',
            actionLabel: 'EXPLORE CATALOGUE',
            onAction: () => onNavigate('/shop'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cart.syncError != null) ...[
              SageNotice(type: SageNoticeType.warning, message: cart.syncError!),
              const SizedBox(height: DesignTokens.lg),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('YOUR SHOPPING CART (${cart.totalItemCount})', style: AppTypography.subTitle()),
                TextButton(
                  onPressed: cart.clearCart,
                  child: Text('CLEAR CART', style: AppTypography.labelUppercase(color: DesignTokens.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.md),
            ...cart.items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: DesignTokens.md),
                  padding: const EdgeInsets.all(DesignTokens.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: DesignTokens.borderLight),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: DesignTokens.lg,
                    runSpacing: DesignTokens.md,
                    children: [
                      GestureDetector(
                        onTap: () => onNavigate(AppRouter.productRoute(item.product)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              item.product.mainImage,
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(width: 84, height: 84, color: DesignTokens.softBackground),
                            ),
                            const SizedBox(width: DesignTokens.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.title, style: AppTypography.cardTitle()),
                                Text(item.product.subtitle,
                                    style: AppTypography.bodySmall(color: DesignTokens.oliveAccent)),
                                const SizedBox(height: 4),
                                Text('Unit: ${formatKsh(item.product.priceKsh)}', style: AppTypography.bodySmall()),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Decrease quantity',
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: () => cart.updateQuantity(item.product.id, item.quantity - 1),
                          ),
                          Text('${item.quantity}', style: AppTypography.bodyLarge()),
                          IconButton(
                            tooltip: 'Increase quantity',
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () => cart.updateQuantity(item.product.id, item.quantity + 1),
                          ),
                          const SizedBox(width: DesignTokens.lg),
                          Text(
                            formatKsh(item.lineTotal),
                            style: AppTypography.cardTitle(color: DesignTokens.burntOrange),
                          ),
                          IconButton(
                            tooltip: 'Remove item',
                            icon: const Icon(Icons.delete_outline, color: DesignTokens.textMuted),
                            onPressed: () => cart.removeFromCart(item.product.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: DesignTokens.lg),
            Container(
              padding: const EdgeInsets.all(DesignTokens.xl),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5F2),
                border: Border.all(color: DesignTokens.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SUBTOTAL', style: AppTypography.labelUppercase()),
                      Text(formatKsh(cart.totalPrice), style: AppTypography.subTitle(color: DesignTokens.burntOrange)),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.xs),
                  Text(
                    'Delivery charges, if any, are shown on the checkout confirmation step.',
                    style: AppTypography.bodySmall(),
                  ),
                  const SizedBox(height: DesignTokens.lg),
                  SageButton(
                    text: 'PROCEED TO CHECKOUT',
                    style: SageButtonStyle.burntOrange,
                    fullWidth: true,
                    onTap: () => onNavigate('/checkout'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Favourites Tab
// ---------------------------------------------------------------------------
class _FavouritesTab extends StatelessWidget {
  final Function(String) onNavigate;
  const _FavouritesTab({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavouritesController.instance,
      builder: (context, _) {
        final favs = FavouritesController.instance;
        if (favs.isLoading) return const SageLoadingView(label: 'Loading saved pieces');
        if (favs.error != null) {
          return SageErrorView(message: favs.error!, onRetry: favs.load);
        }
        final products = favs.products;
        if (products.isEmpty) {
          return SageEmptyView(
            icon: Icons.favorite_border,
            title: 'No saved pieces yet',
            message:
                'Tap the heart icon on any piece in the shop to save it here for quick comparison or future commissioning.',
            actionLabel: 'BROWSE THE SHOP',
            onAction: () => onNavigate('/shop'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SAVED PIECES (${products.length})', style: AppTypography.subTitle()),
            const SizedBox(height: DesignTokens.lg),
            Wrap(
              spacing: DesignTokens.lg,
              runSpacing: DesignTokens.lg,
              children: products
                  .map((Product p) => _FavouriteProductCard(
                        product: p,
                        onNavigate: onNavigate,
                      ))
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _FavouriteProductCard extends StatelessWidget {
  final Product product;
  final Function(String) onNavigate;

  const _FavouriteProductCard({required this.product, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: DesignTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onNavigate(AppRouter.productRoute(product)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.asset(
                product.mainImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: DesignTokens.softBackground),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.clan.toUpperCase(),
                    style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent).copyWith(fontSize: 10)),
                const SizedBox(height: 4),
                Text(product.title, style: AppTypography.cardTitle()),
                Text(product.subtitle, style: AppTypography.bodySmall(color: DesignTokens.textMuted)),
                const SizedBox(height: DesignTokens.sm),
                Text(
                  'KSH ${product.priceKshLabel ?? product.priceKsh.toStringAsFixed(0)}',
                  style:
                      AppTypography.bodyMedium(color: DesignTokens.burntOrange).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: DesignTokens.md),
                Row(
                  children: [
                    Expanded(
                      child: SageButton(
                        text: 'ADD TO CART',
                        style: SageButtonStyle.burntOrange,
                        fullWidth: true,
                        onTap: () {
                          final item =
                              product.coverOnlyPriceKsh != null ? product.withPillowOption('Cover & Insert') : product;
                          CartController.instance.addToCart(item, quantity: 1);
                          CartDrawer.show(context);
                        },
                      ),
                    ),
                    const SizedBox(width: DesignTokens.sm),
                    IconButton(
                      tooltip: 'Remove from favourites',
                      icon: const Icon(Icons.delete_outline, color: DesignTokens.textMuted),
                      onPressed: () => FavouritesController.instance.toggle(product.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4 & 5. Orders Tabs (History = completed/verified only; Pending = unpaid/other)
// ---------------------------------------------------------------------------
class _OrdersTab extends StatefulWidget {
  final bool completedOnly;
  final Function(String) onNavigate;
  final VoidCallback onSwitchToPending;

  const _OrdersTab({
    required this.completedOnly,
    required this.onNavigate,
    required this.onSwitchToPending,
  });

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  final _repo = OrdersRepository();
  List<CustomerOrder> _orders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _OrdersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completedOnly != widget.completedOnly) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!AuthService.instance.isClientReady) {
      setState(() {
        _loading = false;
        _orders = const [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await _repo.myOrders();
      if (!mounted) return;
      setState(() {
        _orders = all;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = BackendErrors.message(e, fallback: 'Could not load your orders.');
      });
    }
  }

  Future<void> _cancel(String orderId) async {
    try {
      await _repo.cancel(orderId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: DesignTokens.galleryAccent,
          content: Text(BackendErrors.message(e, fallback: 'Could not cancel order.')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SageLoadingView(label: 'Loading orders');
    if (_error != null) return SageErrorView(message: _error!, onRetry: _load);

    final completed = _orders.where((o) => o.isCompletedPurchase).toList();
    final pending = _orders.where((o) => !o.isCompletedPurchase).toList();

    if (widget.completedOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PURCHASE HISTORY', style: AppTypography.subTitle()),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 16, color: DesignTokens.oliveAccent),
                label: Text('REFRESH',
                    style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent).copyWith(fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.xs),
          Text(
            'Completed orders with verified payment appear here.',
            style: AppTypography.bodyMedium(),
          ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.md),
            SageNotice(
              type: SageNoticeType.info,
              message:
                  'You have ${pending.length} pending order ${pending.length == 1 ? 'request' : 'requests'} awaiting payment confirmation. View them in the Pending Orders tab.',
            ),
          ],
          const SizedBox(height: DesignTokens.lg),
          if (completed.isEmpty)
            SageEmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'No completed purchases yet',
              message: 'Orders move to Purchase History only after payment has been confirmed by Sage Studio.',
              actionLabel: pending.isNotEmpty ? 'VIEW PENDING ORDERS' : 'BROWSE THE SHOP',
              onAction: pending.isNotEmpty ? widget.onSwitchToPending : () => widget.onNavigate('/shop'),
            )
          else
            ...completed.map((o) => _OrderCard(order: o, onNavigate: widget.onNavigate)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PENDING & UNPAID ORDERS', style: AppTypography.subTitle()),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 16, color: DesignTokens.oliveAccent),
              label: Text('REFRESH',
                  style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent).copyWith(fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.xs),
        Text(
          'Online payment gateway integration is pending configuration. Orders placed during checkout are saved as Pending (payment not collected) until verified.',
          style: AppTypography.bodyMedium(),
        ),
        const SizedBox(height: DesignTokens.lg),
        if (pending.isEmpty)
          SageEmptyView(
            icon: Icons.hourglass_empty_outlined,
            title: 'No pending orders',
            message: 'You do not have any orders awaiting payment.',
            actionLabel: 'BROWSE THE SHOP',
            onAction: () => widget.onNavigate('/shop'),
          )
        else
          ...pending.map((o) => _OrderCard(
                order: o,
                onNavigate: widget.onNavigate,
                onCancel: o.status == OrderStatus.pendingPayment ? () => _cancel(o.id) : null,
              )),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final CustomerOrder order;
  final Function(String) onNavigate;
  final VoidCallback? onCancel;

  const _OrderCard({required this.order, required this.onNavigate, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final (String badgeText, Color badgeColor) = switch (order.status) {
      OrderStatus.paid => ('PAID & CONFIRMED', DesignTokens.oliveAccent),
      OrderStatus.fulfilled => ('FULFILLED', DesignTokens.oliveAccent),
      OrderStatus.pendingPayment => ('PENDING — PAYMENT NOT COLLECTED', DesignTokens.burntOrange),
      OrderStatus.failed => ('PAYMENT FAILED', DesignTokens.galleryAccent),
      OrderStatus.cancelled => ('CANCELLED', DesignTokens.textMuted),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.lg),
      padding: const EdgeInsets.all(DesignTokens.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: DesignTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: DesignTokens.md,
            runSpacing: DesignTokens.sm,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ORDER ${order.orderRef}', style: AppTypography.cardTitle()),
                  Text(
                    'Placed ${formatDate(order.createdAt)}',
                    style: AppTypography.bodySmall(),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: badgeColor.withValues(alpha: 0.12),
                child: Text(
                  badgeText,
                  style: AppTypography.labelUppercase(color: badgeColor).copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.md),
          const ThinRule(),
          const SizedBox(height: DesignTokens.md),
          ...order.lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => onNavigate(AppRouter.productRouteById(line.productId)),
                        child: Text(
                          '${line.quantity} × ${line.title} — ${line.subtitle} (${line.productCode})',
                          style: AppTypography.bodyMedium(color: DesignTokens.textPrimary).copyWith(
                            decoration: TextDecoration.underline,
                            decorationColor: DesignTokens.borderLight,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      formatKsh(line.lineTotalKsh),
                      style: AppTypography.bodyMedium(color: DesignTokens.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),
          const ThinRule(verticalMargin: DesignTokens.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL', style: AppTypography.labelUppercase()),
              Text(formatKsh(order.totalKsh), style: AppTypography.cardTitle(color: DesignTokens.burntOrange)),
            ],
          ),
          if (onCancel != null) ...[
            const SizedBox(height: DesignTokens.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: Text('CANCEL PENDING ORDER',
                    style: AppTypography.labelUppercase(color: DesignTokens.galleryAccent).copyWith(fontSize: 10)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. My Reviews Tab
// ---------------------------------------------------------------------------
class _MyReviewsTab extends StatefulWidget {
  final Function(String) onNavigate;
  const _MyReviewsTab({required this.onNavigate});

  @override
  State<_MyReviewsTab> createState() => _MyReviewsTabState();
}

class _MyReviewsTabState extends State<_MyReviewsTab> {
  final _repo = ReviewsRepository();
  List<ProductReview> _reviews = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AuthService.instance.isClientReady) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.mine();
      if (!mounted) return;
      setState(() {
        _reviews = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = BackendErrors.message(e, fallback: 'Could not load your reviews.');
      });
    }
  }

  Future<void> _delete(String id) async {
    try {
      await _repo.delete(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: DesignTokens.galleryAccent,
          content: Text(BackendErrors.message(e, fallback: 'Could not delete review.')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SageLoadingView(label: 'Loading your reviews');
    if (_error != null) return SageErrorView(message: _error!, onRetry: _load);
    if (_reviews.isEmpty) {
      return SageEmptyView(
        icon: Icons.rate_review_outlined,
        title: 'You have not submitted any reviews yet',
        message: 'Open any product in the catalogue to rate it and write a review.',
        actionLabel: 'BROWSE THE SHOP',
        onAction: () => widget.onNavigate('/shop'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MY REVIEWS (${_reviews.length})', style: AppTypography.subTitle()),
        const SizedBox(height: DesignTokens.lg),
        ..._reviews.map((r) {
          final product = CatalogueLookup.byId(r.productId);
          final statusLabel = switch (r.status) {
            ModerationStatus.pending => 'PENDING APPROVAL',
            ModerationStatus.approved => 'APPROVED & PUBLIC',
            ModerationStatus.rejected => 'NOT PUBLISHED',
          };
          return Container(
            margin: const EdgeInsets.only(bottom: DesignTokens.md),
            padding: const EdgeInsets.all(DesignTokens.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: DesignTokens.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: DesignTokens.md,
                  children: [
                    Text(
                      product != null ? '${product.title} (${product.subtitle})' : r.productId,
                      style: AppTypography.cardTitle(),
                    ),
                    Text(
                      statusLabel,
                      style: AppTypography.labelUppercase(
                        color:
                            r.status == ModerationStatus.approved ? DesignTokens.oliveAccent : DesignTokens.burntOrange,
                      ).copyWith(fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < r.rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: DesignTokens.burntOrange,
                    ),
                  ),
                ),
                if (r.title != null) ...[
                  const SizedBox(height: 6),
                  Text(r.title!,
                      style: AppTypography.bodyMedium(color: DesignTokens.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 4),
                Text(r.body, style: AppTypography.bodyMedium(color: DesignTokens.textPrimary)),
                const SizedBox(height: DesignTokens.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (product != null)
                      TextButton(
                        onPressed: () => widget.onNavigate(AppRouter.productRoute(product)),
                        child: Text('EDIT ON PRODUCT PAGE',
                            style:
                                AppTypography.labelUppercase(color: DesignTokens.oliveAccent).copyWith(fontSize: 10)),
                      ),
                    TextButton(
                      onPressed: () => _delete(r.id),
                      child: Text('DELETE',
                          style:
                              AppTypography.labelUppercase(color: DesignTokens.galleryAccent).copyWith(fontSize: 10)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
