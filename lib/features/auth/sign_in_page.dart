import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/sage_button.dart';
import '../../core/widgets/sage_text_field.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/thin_rule.dart';

enum AuthMode { signIn, register, reset, updatePassword }

AuthMode authModeFromQuery(String? value) {
  switch (value) {
    case 'register':
      return AuthMode.register;
    case 'reset':
      return AuthMode.reset;
    case 'update-password':
      return AuthMode.updatePassword;
    default:
      return AuthMode.signIn;
  }
}

/// Sign in / Create account / Forgot password / Set new password.
class SignInPage extends StatefulWidget {
  final Function(String) onNavigate;
  final AuthMode initialMode;

  /// Route to open after a successful sign-in (e.g. the product the visitor
  /// was viewing). Must be an internal path beginning with '/'.
  final String? returnRoute;

  const SignInPage({super.key, required this.onNavigate, this.initialMode = AuthMode.signIn, this.returnRoute});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  late AuthMode _mode = widget.initialMode;
  bool _busy = false;
  bool _googleBusy = false;
  String? _error;
  String? _success;

  String? get _safeReturn {
    final r = widget.returnRoute;
    if (r == null || !r.startsWith('/') || r.startsWith('//') || r.startsWith('/sign-in')) return null;
    return r;
  }

  @override
  void didUpdateWidget(covariant SignInPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) _switchMode(widget.initialMode);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    setState(() {
      _mode = mode;
      _error = null;
      _success = null;
      _password.clear();
      _confirm.clear();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    final auth = AuthService.instance;
    AuthResult result;
    switch (_mode) {
      case AuthMode.signIn:
        await auth.rememberReturnRoute(null);
        result = await auth.signInWithPassword(_email.text, _password.text);
        break;
      case AuthMode.register:
        await auth.rememberReturnRoute(_safeReturn ?? '/account');
        result = await auth.register(
          fullName: _name.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
        );
        break;
      case AuthMode.reset:
        result = await auth.sendPasswordReset(_email.text);
        break;
      case AuthMode.updatePassword:
        result = await auth.updatePassword(_password.text);
        break;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.ok) {
        _success = result.message;
      } else {
        _error = result.message;
      }
    });
    if (!result.ok) return;
    if (_mode == AuthMode.signIn || (_mode == AuthMode.register && auth.isSignedIn)) {
      await auth.rememberReturnRoute(null);
      widget.onNavigate(_safeReturn ?? '/account');
    } else if (_mode == AuthMode.updatePassword) {
      _password.clear();
      _confirm.clear();
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _googleBusy = true;
      _error = null;
      _success = null;
    });
    await AuthService.instance.rememberReturnRoute(_safeReturn ?? '/account');
    final result = await AuthService.instance.signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _googleBusy = false;
      if (!result.ok) _error = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final isDesktop = Breakpoints.isDesktop(context);

    final form = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: ListenableBuilder(
        listenable: AuthService.instance,
        builder: (context, _) => _buildContent(context),
      ),
    );

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
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 4 / 5,
                          child: Image.asset(
                            'assets/images/products/hero_sofa.jpg',
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                            errorBuilder: (_, __, ___) => Container(color: DesignTokens.softBackground),
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.xxxl),
                      Expanded(child: Align(alignment: Alignment.topLeft, child: form)),
                    ],
                  )
                : Center(child: form),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final auth = AuthService.instance;

    if (auth.status == AuthStatus.initialising) {
      return const SageLoadingView(label: 'Preparing your account');
    }

    if (!auth.isConfigured) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CLIENT PORTAL', style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent)),
          const SizedBox(height: DesignTokens.sm),
          Text('Accounts are coming soon', style: AppTypography.sectionTitle().copyWith(fontSize: 34)),
          const SizedBox(height: DesignTokens.lg),
          SageNotice(
            type: SageNoticeType.info,
            message: auth.initError ??
                'Customer accounts are not available yet. You can continue browsing the catalogue and contact the studio directly for orders.',
          ),
          const SizedBox(height: DesignTokens.xl),
          SageButton(
              text: 'BROWSE THE SHOP', style: SageButtonStyle.primary, onTap: () => widget.onNavigate('/shop')),
        ],
      );
    }

    if (auth.isSignedIn && _mode != AuthMode.updatePassword) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CLIENT PORTAL', style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent)),
          const SizedBox(height: DesignTokens.sm),
          Text('You are signed in', style: AppTypography.sectionTitle().copyWith(fontSize: 34)),
          const SizedBox(height: DesignTokens.md),
          Text(auth.user?.email ?? '', style: AppTypography.bodyLarge(color: DesignTokens.textMuted)),
          const SizedBox(height: DesignTokens.xl),
          SageButton(
            text: 'GO TO MY ACCOUNT',
            style: SageButtonStyle.primary,
            fullWidth: true,
            onTap: () => widget.onNavigate(_safeReturn ?? '/account'),
          ),
          const SizedBox(height: DesignTokens.md),
          SageButton(
            text: 'SIGN OUT',
            style: SageButtonStyle.primary,
            fullWidth: true,
            onTap: () => AuthService.instance.signOut(),
          ),
        ],
      );
    }

    final (String kicker, String title, String intro) = switch (_mode) {
      AuthMode.signIn => ('CLIENT PORTAL', 'Sign in', 'Access your saved pieces, cart, reviews and orders.'),
      AuthMode.register => (
          'CLIENT PORTAL',
          'Create an account',
          'Save favourites, keep your cart across devices and review pieces you own.'
        ),
      AuthMode.reset => (
          'ACCOUNT RECOVERY',
          'Reset your password',
          'Enter the email you registered with and we will send you a secure reset link.'
        ),
      AuthMode.updatePassword => (
          'ACCOUNT RECOVERY',
          'Choose a new password',
          auth.isSignedIn
              ? 'Set a new password for ${auth.user?.email ?? 'your account'}.'
              : 'Open the reset link from your email to set a new password.'
        ),
    };

    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(kicker, style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent)),
            const SizedBox(height: DesignTokens.sm),
            Semantics(header: true, child: Text(title, style: AppTypography.sectionTitle().copyWith(fontSize: 34))),
            const SizedBox(height: DesignTokens.sm),
            Text(intro, style: AppTypography.bodyMedium()),
            const SizedBox(height: DesignTokens.xl),
            if (auth.initError != null) ...[
              SageNotice(type: SageNoticeType.error, message: auth.initError!, onDismiss: auth.clearInitError),
              const SizedBox(height: DesignTokens.lg),
            ],
            if (_mode == AuthMode.register) ...[
              SageTextField(
                key: const ValueKey('auth_full_name'),
                label: 'FULL NAME *',
                controller: _name,
                hint: 'e.g. Amina Wambui',
                validator: Validators.fullName,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                enabled: !_busy,
              ),
              const SizedBox(height: DesignTokens.lg),
            ],
            if (_mode != AuthMode.updatePassword) ...[
              SageTextField(
                key: const ValueKey('auth_email'),
                label: 'EMAIL ADDRESS *',
                controller: _email,
                hint: 'yourname@domain.com',
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: _mode == AuthMode.reset ? TextInputAction.done : TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                enabled: !_busy,
                onSubmitted: _mode == AuthMode.reset ? (_) => _submit() : null,
              ),
              const SizedBox(height: DesignTokens.lg),
            ],
            if (_mode == AuthMode.register) ...[
              SageTextField(
                key: const ValueKey('auth_phone'),
                label: 'PHONE NUMBER *',
                controller: _phone,
                hint: '+254 700 000000',
                validator: Validators.requiredPhone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                enabled: !_busy,
              ),
              const SizedBox(height: DesignTokens.lg),
            ],
            if (_mode != AuthMode.reset && !(_mode == AuthMode.updatePassword && !auth.isSignedIn)) ...[
              SageTextField(
                key: const ValueKey('auth_password'),
                label: _mode == AuthMode.signIn ? 'PASSWORD *' : 'NEW PASSWORD *',
                controller: _password,
                obscure: true,
                hint: _mode == AuthMode.signIn ? null : 'At least 8 characters, a letter and a number',
                validator: _mode == AuthMode.signIn ? Validators.passwordPresent : Validators.newPassword,
                textInputAction: _mode == AuthMode.signIn ? TextInputAction.done : TextInputAction.next,
                autofillHints: [_mode == AuthMode.signIn ? AutofillHints.password : AutofillHints.newPassword],
                enabled: !_busy,
                onSubmitted: _mode == AuthMode.signIn ? (_) => _submit() : null,
              ),
              const SizedBox(height: DesignTokens.lg),
            ],
            if (_mode == AuthMode.register || (_mode == AuthMode.updatePassword && auth.isSignedIn)) ...[
              SageTextField(
                key: const ValueKey('auth_confirm_password'),
                label: 'CONFIRM PASSWORD *',
                controller: _confirm,
                obscure: true,
                validator: Validators.confirmPassword(() => _password.text),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_busy,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: DesignTokens.lg),
            ],
            if (_mode == AuthMode.signIn)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : () => _switchMode(AuthMode.reset),
                  child: Text('Forgot password?', style: AppTypography.bodySmall(color: DesignTokens.oliveAccent)),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: DesignTokens.sm),
              SageNotice(type: SageNoticeType.error, message: _error!),
            ],
            if (_success != null) ...[
              const SizedBox(height: DesignTokens.sm),
              SageNotice(type: SageNoticeType.success, message: _success!),
            ],
            const SizedBox(height: DesignTokens.lg),
            if (!(_mode == AuthMode.updatePassword && !auth.isSignedIn))
              SageBusyButton(
                text: switch (_mode) {
                  AuthMode.signIn => 'SIGN IN',
                  AuthMode.register => 'CREATE ACCOUNT',
                  AuthMode.reset => 'SEND RESET LINK',
                  AuthMode.updatePassword => 'UPDATE PASSWORD',
                },
                busyText: 'PLEASE WAIT…',
                busy: _busy,
                onTap: _submit,
              ),
            if (_mode == AuthMode.signIn || _mode == AuthMode.register) ...[
              const SizedBox(height: DesignTokens.lg),
              Row(
                children: [
                  const Expanded(child: ThinRule()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.md),
                    child: Text('OR', style: AppTypography.labelUppercase(color: DesignTokens.textMuted)),
                  ),
                  const Expanded(child: ThinRule()),
                ],
              ),
              const SizedBox(height: DesignTokens.lg),
              _GoogleSignInButton(
                busy: _googleBusy,
                disabled: _busy,
                onTap: _google,
              ),
            ],
            const SizedBox(height: DesignTokens.xl),
            _modeSwitcher(),
          ],
        ),
      ),
    );
  }

  Widget _modeSwitcher() {
    Widget link(String lead, String action, AuthMode target) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(lead, style: AppTypography.bodyMedium()),
          TextButton(
            onPressed: _busy ? null : () => _switchMode(target),
            child: Text(action, style: AppTypography.bodyMedium(color: DesignTokens.burntOrange)),
          ),
        ],
      );
    }

    return switch (_mode) {
      AuthMode.signIn => link('New to Sage Studio?', 'Create an account', AuthMode.register),
      AuthMode.register => link('Already have an account?', 'Sign in', AuthMode.signIn),
      AuthMode.reset => link('Remembered it?', 'Back to sign in', AuthMode.signIn),
      AuthMode.updatePassword => AuthService.instance.isSignedIn
          ? TextButton(
              onPressed: () => widget.onNavigate('/account'),
              child: Text('Go to my account', style: AppTypography.bodyMedium(color: DesignTokens.burntOrange)),
            )
          : link('Need a new link?', 'Request password reset', AuthMode.reset),
    };
  }
}

class _GoogleSignInButton extends StatefulWidget {
  final bool busy;
  final bool disabled;
  final VoidCallback onTap;

  const _GoogleSignInButton({
    required this.busy,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.busy || widget.disabled;
    return MouseRegion(
      cursor: isLocked ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Opacity(
        opacity: isLocked ? 0.65 : 1,
        child: InkWell(
          onTap: isLocked ? null : widget.onTap,
          child: AnimatedContainer(
            duration: DesignTokens.durationStandard,
            curve: DesignTokens.editorialEase,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.xl,
              vertical: DesignTokens.md,
            ),
            decoration: BoxDecoration(
              color: _hovered && !isLocked ? DesignTokens.softBackground : Colors.white,
              border: Border.all(color: DesignTokens.textPrimary, width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 1.8, color: DesignTokens.textPrimary),
                  )
                else
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CustomPaint(painter: _GoogleLogoPainter()),
                  ),
                const SizedBox(width: DesignTokens.md),
                Flexible(
                  child: Text(
                    widget.busy ? 'Connecting to Google…' : 'Continue with Google',
                    textAlign: TextAlign.center,
                    style: AppTypography.navLink(color: DesignTokens.textPrimary).copyWith(
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    final stroke = size.width * 0.19;
    final rect = Rect.fromCircle(center: c, radius: r);

    Paint arcPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Red top arc
    canvas.drawArc(rect, -2.55, 1.9, false, arcPaint(const Color(0xFFEA4335)));
    // Yellow left arc
    canvas.drawArc(rect, 2.35, 1.4, false, arcPaint(const Color(0xFFFBBC05)));
    // Green bottom arc
    canvas.drawArc(rect, 0.78, 1.6, false, arcPaint(const Color(0xFF34A853)));
    // Blue right arc
    canvas.drawArc(rect, -0.05, 0.9, false, arcPaint(const Color(0xFF4285F4)));

    // Blue horizontal bar of the 'G'
    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + r + stroke * 0.42, c.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
