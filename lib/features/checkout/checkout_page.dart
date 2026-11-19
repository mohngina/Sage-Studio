import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/features_helpers.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/backend_errors.dart';
import '../../core/services/order_docx_service.dart';
import '../../core/services/portal_repositories.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/sage_button.dart';
import '../../core/widgets/sage_text_field.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/thin_rule.dart';
import '../../models/portal_models.dart';
import '../auth/sign_in_required_view.dart';
import '../shop/cart_controller.dart';

/// Safe checkout page.
///
/// Since no live payment provider is configured yet, this checkout:
///  1. Requires an authenticated customer.
///  2. Prepopulates contact and delivery details from the customer's profile.
///  3. Displays an itemized summary and any configured delivery charge (never
///     inventing fees).
///  4. Submits the order through `create_pending_order` (server-side total
///     recalculation + idempotency key) with status `pending_payment`.
///  5. Clearly informs the customer that payment has NOT been collected and
///     routes them to Pending Orders rather than Purchase History.
class CheckoutPage extends StatefulWidget {
  final Function(String) onNavigate;

  const CheckoutPage({super.key, required this.onNavigate});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _profileRepo = ProfileRepository();
  final _ordersRepo = OrdersRepository();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _postal = TextEditingController();
  final _country = TextEditingController(text: 'Kenya');
  final _notes = TextEditingController();

  final String _idempotencyKey = _generateUuidV4();
  StoreSettings _settings = const StoreSettings();
  CustomerOrder? _createdOrder;
  bool _createdViaDocxOrder = false;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) CartController.instance.revalidateAgainstCatalogue();
    });
    _loadContext();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _region.dispose();
    _postal.dispose();
    _country.dispose();
    _notes.dispose();
    super.dispose();
  }

  static String _generateUuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<void> _loadContext() async {
    final auth = AuthService.instance;
    if (!auth.isSignedIn) {
      setState(() => _loading = false);
      return;
    }
    _email.text = auth.user?.email ?? '';
    _name.text = auth.displayName == 'Account' ? '' : auth.displayName;
    if (!auth.isClientReady) {
      setState(() => _loading = false);
      return;
    }
    try {
      final profileFuture = _profileRepo.fetchOrCreate();
      final settingsFuture = _ordersRepo.storeSettings();
      final profile = await profileFuture;
      final settings = await settingsFuture;
      if (!mounted) return;
      if ((profile.fullName ?? '').isNotEmpty) _name.text = profile.fullName!;
      if ((profile.phone ?? '').isNotEmpty) _phone.text = profile.phone!;
      if ((profile.addressLine1 ?? '').isNotEmpty) _line1.text = profile.addressLine1!;
      if ((profile.addressLine2 ?? '').isNotEmpty) _line2.text = profile.addressLine2!;
      if ((profile.city ?? '').isNotEmpty) _city.text = profile.city!;
      if ((profile.region ?? '').isNotEmpty) _region.text = profile.region!;
      if ((profile.postalCode ?? '').isNotEmpty) _postal.text = profile.postalCode!;
      if ((profile.country ?? '').isNotEmpty) _country.text = profile.country!;
      setState(() {
        _settings = settings;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _submitPendingOrder() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cart = CartController.instance;
    if (cart.items.isEmpty) {
      setState(() => _error = 'Your cart is empty.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final cartSnapshot = List<CartItem>.from(cart.items);
    final studioItems = cartSnapshot.where((i) => !isSageSelectProduct(i.product)).toList();
    final deliveryAddress = <String, dynamic>{
      'line1': _line1.text.trim(),
      if (_line2.text.trim().isNotEmpty) 'line2': _line2.text.trim(),
      'city': _city.text.trim(),
      if (_region.text.trim().isNotEmpty) 'region': _region.text.trim(),
      if (_postal.text.trim().isNotEmpty) 'postal_code': _postal.text.trim(),
      'country': _country.text.trim().isEmpty ? 'Kenya' : _country.text.trim(),
    };
    final contactName = _name.text.trim();
    final contactEmail = _email.text.trim();
    final contactPhone = _phone.text.trim();
    final notesText = _notes.text.trim().isEmpty ? null : _notes.text.trim();

    try {
      final order = await _ordersRepo.createPendingOrder(
        idempotencyKey: _idempotencyKey,
        contactName: contactName,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        deliveryAddress: deliveryAddress,
        notes: notesText,
      );

      if (studioItems.isNotEmpty) {
        final studioTotal = studioItems.fold<double>(0.0, (sum, item) => sum + item.lineTotal);
        await OrderDocxService.processAndDispatchOrder(
          orderRef: order.orderRef,
          fullName: contactName,
          email: contactEmail,
          phone: contactPhone,
          deliveryAddress: deliveryAddress,
          notes: notesText,
          items: studioItems,
          totalKsh: studioTotal,
        );
      }

      cart.clearLocalAfterOrder();
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _createdOrder = order;
        _createdViaDocxOrder = studioItems.isNotEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = BackendErrors.message(e, fallback: 'Could not place your order.');
      });
    }
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
              listenable: Listenable.merge([AuthService.instance, CartController.instance]),
              builder: (context, _) {
                final auth = AuthService.instance;
                if (!auth.isSignedIn) {
                  return SignInRequiredView(
                    onNavigate: widget.onNavigate,
                    returnRoute: '/checkout',
                    title: 'Sign in to check out',
                    message: 'Please sign in or create an account so we can link your order to your client profile.',
                  );
                }
                if (_createdOrder != null) {
                  return _PendingOrderConfirmation(
                    order: _createdOrder!,
                    sentToStudio: _createdViaDocxOrder,
                    onNavigate: widget.onNavigate,
                  );
                }
                if (_loading) return const SageLoadingView(label: 'Preparing checkout');
                final cart = CartController.instance;
                if (cart.items.isEmpty) {
                  return SageEmptyView(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Your cart is empty',
                    message: 'Add pieces from the Sage Studio catalogue before checking out.',
                    actionLabel: 'RETURN TO SHOP',
                    onAction: () => widget.onNavigate('/shop'),
                  );
                }

                final hasStudioItems = cart.items.any((i) => !isSageSelectProduct(i.product));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SageButton(
                      text: '← BACK TO SHOP',
                      style: SageButtonStyle.textLink,
                      onTap: () => widget.onNavigate('/shop'),
                    ),
                    const SizedBox(height: DesignTokens.md),
                    Text('CHECKOUT', style: AppTypography.sectionTitle()),
                    if (!hasStudioItems) ...[
                      const SizedBox(height: DesignTokens.sm),
                      const SageNotice(
                        type: SageNoticeType.warning,
                        message:
                            'Test / Pending Checkout Mode: An online payment provider for Sage Select has not been enabled yet. Confirming below records a PENDING order request — no payment is collected online.',
                      ),
                    ],
                    const SizedBox(height: DesignTokens.xl),
                    ResponsiveLayout(
                      mobile: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummary(cart),
                          const SizedBox(height: DesignTokens.xxl),
                          _buildForm(hasStudioItems: hasStudioItems),
                        ],
                      ),
                      desktop: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: _buildForm(hasStudioItems: hasStudioItems)),
                          const SizedBox(width: DesignTokens.xxxl),
                          Expanded(flex: 5, child: _buildSummary(cart)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm({required bool hasStudioItems}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('1. CONTACT INFORMATION', style: AppTypography.subTitle()),
          const SizedBox(height: DesignTokens.lg),
          SageTextField(
            label: 'FULL NAME *',
            controller: _name,
            validator: Validators.fullName,
            enabled: !_submitting,
          ),
          const SizedBox(height: DesignTokens.lg),
          SageTextField(
            label: 'EMAIL ADDRESS *',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            enabled: !_submitting,
          ),
          const SizedBox(height: DesignTokens.lg),
          SageTextField(
            label: 'PHONE NUMBER *',
            controller: _phone,
            hint: '+254 700 000000',
            keyboardType: TextInputType.phone,
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return 'Please enter a contact phone number.';
              return Validators.optionalPhone(v);
            },
            enabled: !_submitting,
          ),
          const SizedBox(height: DesignTokens.xxl),
          Text('2. DELIVERY ADDRESS', style: AppTypography.subTitle()),
          const SizedBox(height: DesignTokens.lg),
          SageTextField(
            label: 'STREET / ESTATE / BUILDING *',
            controller: _line1,
            hint: 'e.g. Karen Road, House 14',
            validator: Validators.maxLength(200, required: true, field: 'Delivery address'),
            enabled: !_submitting,
          ),
          const SizedBox(height: DesignTokens.lg),
          SageTextField(
            label: 'APARTMENT / LANDMARK (OPTIONAL)',
            controller: _line2,
            validator: Validators.maxLength(200, field: 'Address line 2'),
            enabled: !_submitting,
          ),
          const SizedBox(height: DesignTokens.lg),
          Row(
            children: [
              Expanded(
                child: SageTextField(
                  label: 'CITY / TOWN *',
                  controller: _city,
                  hint: 'Nairobi',
                  validator: Validators.maxLength(100, required: true, field: 'City'),
                  enabled: !_submitting,
                ),
              ),
              const SizedBox(width: DesignTokens.lg),
              Expanded(
                child: SageTextField(
                  label: 'COUNTY / REGION',
                  controller: _region,
                  validator: Validators.maxLength(100, field: 'Region'),
                  enabled: !_submitting,
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
                  validator: Validators.maxLength(20, field: 'Postal code'),
                  enabled: !_submitting,
                ),
              ),
              const SizedBox(width: DesignTokens.lg),
              Expanded(
                child: SageTextField(
                  label: 'COUNTRY *',
                  controller: _country,
                  validator: Validators.maxLength(100, required: true, field: 'Country'),
                  enabled: !_submitting,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.lg),
          SageTextField(
            label: 'ORDER / FINISH NOTES (OPTIONAL)',
            controller: _notes,
            maxLines: 3,
            hint: 'Timber finish preference, upholstery notes or delivery instructions...',
            validator: Validators.maxLength(1000, field: 'Notes'),
            enabled: !_submitting,
          ),
          if (_error != null) ...[
            const SizedBox(height: DesignTokens.lg),
            SageNotice(type: SageNoticeType.error, message: _error!),
          ],
          const SizedBox(height: DesignTokens.xl),
          SageBusyButton(
            text: hasStudioItems ? 'PLACE ORDER' : 'PLACE PENDING ORDER (NO PAYMENT COLLECTED)',
            busyText: 'SUBMITTING ORDER…',
            busy: _submitting,
            onTap: _submitPendingOrder,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(CartController cart) {
    final subtotal = cart.totalPrice;
    final fee = _settings.deliveryFeeKsh;
    final total = subtotal + (fee ?? 0);

    return Container(
      padding: const EdgeInsets.all(DesignTokens.xl),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F2),
        border: Border.all(color: DesignTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ORDER SUMMARY', style: AppTypography.subTitle()),
          const SizedBox(height: DesignTokens.md),
          const ThinRule(),
          const SizedBox(height: DesignTokens.md),
          ...cart.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      item.product.mainImage,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(width: 56, height: 56, color: DesignTokens.softBackground),
                    ),
                    const SizedBox(width: DesignTokens.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.title,
                              style: AppTypography.bodyMedium(color: DesignTokens.textPrimary)
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text('${item.product.subtitle} • Qty ${item.quantity}', style: AppTypography.bodySmall()),
                          Text('Unit: ${formatKsh(item.product.priceKsh)}', style: AppTypography.bodySmall()),
                        ],
                      ),
                    ),
                    Text(
                      formatKsh(item.lineTotal),
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
              Text('Subtotal', style: AppTypography.bodyMedium()),
              Text(formatKsh(subtotal), style: AppTypography.bodyMedium(color: DesignTokens.textPrimary)),
            ],
          ),
          const SizedBox(height: DesignTokens.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery', style: AppTypography.bodyMedium()),
              Text(
                fee != null ? formatKsh(fee) : 'Confirmed by studio',
                style: AppTypography.bodySmall(color: DesignTokens.oliveAccent),
              ),
            ],
          ),
          const ThinRule(verticalMargin: DesignTokens.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL', style: AppTypography.labelUppercase()),
              Text(formatKsh(total), style: AppTypography.subTitle(color: DesignTokens.burntOrange)),
            ],
          ),
          const SizedBox(height: DesignTokens.sm),
          Text(
            'Final amount is recalculated on the server from official Sage Studio catalogue prices.',
            style: AppTypography.bodySmall(),
          ),
        ],
      ),
    );
  }
}

class _PendingOrderConfirmation extends StatelessWidget {
  final CustomerOrder order;
  final bool sentToStudio;
  final Function(String) onNavigate;

  const _PendingOrderConfirmation({
    required this.order,
    required this.sentToStudio,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.xxl),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: DesignTokens.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: DesignTokens.burntOrange.withValues(alpha: 0.12),
              child: Text(
                'STATUS: PENDING — PAYMENT NOT COLLECTED',
                style: AppTypography.labelUppercase(color: DesignTokens.burntOrange).copyWith(fontSize: 10),
              ),
            ),
            const SizedBox(height: DesignTokens.md),
            Text(sentToStudio ? 'Order sent to Sage Studio' : 'Order request recorded',
                style: AppTypography.sectionTitle()),
            const SizedBox(height: DesignTokens.sm),
            Text(
              'Reference: ${order.orderRef} • Total: ${formatKsh(order.totalKsh)}',
              style: AppTypography.cardTitle(color: DesignTokens.oliveAccent),
            ),
            const SizedBox(height: DesignTokens.md),
            Text(
              sentToStudio
                  ? 'Your order has been received and recorded under Pending Orders in your account. Our Nairobi studio will be in touch shortly to confirm your finishes and delivery.'
                  : 'Your order details have been saved under your account as a pending order. Because online payment collection is not yet activated, no charge has been made and this order has not been added to your completed Purchase History.',
              style: AppTypography.bodyMedium(color: DesignTokens.textPrimary),
            ),
            const SizedBox(height: DesignTokens.xl),
            Wrap(
              spacing: DesignTokens.md,
              runSpacing: DesignTokens.sm,
              children: [
                SageButton(
                  text: 'VIEW PENDING ORDERS',
                  style: SageButtonStyle.primary,
                  onTap: () => onNavigate('/account?tab=pending'),
                ),
                SageButton(
                  text: 'CONTINUE SHOPPING',
                  style: SageButtonStyle.primary,
                  onTap: () => onNavigate('/shop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
