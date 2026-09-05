// unified_login_page.dart  —  Saith Commission Shop

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/auth/providers/admin_user_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/customer_provider.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/modules/auth/views/customer_signup_page.dart';

class UnifiedLoginPage extends StatefulWidget {
  const UnifiedLoginPage({super.key});
  @override
  State<UnifiedLoginPage> createState() => _UnifiedLoginPageState();
}

class _UnifiedLoginPageState extends State<UnifiedLoginPage>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool  _showPass     = false;
  bool  _isLoading    = false;
  String? _errorMsg;

  late AnimationController _entranceCtrl;
  late Animation<double>   _cardFade;
  late Animation<Offset>   _cardSlide;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _cardFade  = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut));
    _cardSlide = Tween<Offset>(
            begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)));
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ── Core login logic ──────────────────────────────────────
  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim();
    final pass  = _passwordCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMsg = 'Please enter your email and password');
      return;
    }

    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      final adminProv = context.read<AdminUserProvider>();

      if (!adminProv.isLocked) {
        final adminOk = await adminProv.login(
            email: email, password: pass);

        if (adminOk && mounted) {
          setState(() => _isLoading = false);
          Navigator.pushReplacementNamed(context, '/admin-home');
          return;
        }
      }

      final custProv = context.read<CustomerProvider>();
      final custOk   = await custProv.login(
          identifier: email, password: pass);

      if (!mounted || !context.mounted) return;

      if (custOk) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/customer-home');
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMsg  = adminProv.isLocked
            ? adminProv.lockMessage
            : 'Invalid email or password. Please try again.';
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg  = 'Login failed. Please check your connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProv  = context.watch<AdminUserProvider>();
    final size       = MediaQuery.of(context).size;

    // First-time setup — no admin exists yet
    if (adminProv.isLoaded && adminProv.needsSetup) {
      return _FirstTimeSetupPage();
    }

    return Scaffold(
      body: Stack(children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(gradient: SGradient.primary),
        ),

        // White bottom sheet
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: size.height * 0.68,
            decoration: const BoxDecoration(
              color: SColors.background,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(SRadius.xl)),
            ),
          ),
        ),

        // Header on gradient
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom
                    + SSpacing.xl),
            child: Column(children: [
              // Header on gradient
              SizedBox(
                height: size.height * 0.30,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 86, height: 86,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20, offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(child: Padding(
                        padding: const EdgeInsets.all(SSpacing.md),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.storefront,
                              size: 44, color: SColors.primary),
                        ),
                      )),
                    ),
                    const SizedBox(height: SSpacing.md),
                    Text('Saith Commission Shop',
                        style: SText.headingXl.copyWith(
                            color: Colors.white)),
                    const SizedBox(height: SSpacing.xs),
                    Text('Sign in to continue',
                        style: SText.bodySm.copyWith(
                            color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ),

              // Login card
              FadeTransition(
                opacity: _cardFade,
                child: SlideTransition(
                  position: _cardSlide,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        SSpacing.lg, 0, SSpacing.lg, 0),
                    child: Container(
                      padding: SSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: SColors.surface,
                        borderRadius: SRadius.radiusLg,
                        border: Border.all(
                            color: SColors.border.withOpacity(0.5), width: 0.5),
                        boxShadow: SShadow.neoOut,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back',
                              style: SText.headingMd),
                          const SizedBox(height: SSpacing.xs),
                          Text(
                            'Admin and customers use the same login',
                            style: SText.bodyXs,
                          ),

                          const SizedBox(height: SSpacing.lg),

                          // Error banner
                          if (_errorMsg != null) ...[
                            _ErrorBanner(message: _errorMsg!),
                            const SizedBox(height: SSpacing.md),
                          ],

                          // Lock banner
                          if (adminProv.isLocked) ...[
                            _LockBanner(message: adminProv.lockMessage),
                            const SizedBox(height: SSpacing.md),
                          ],

                          // Email
                          _LoginField(
                            controller: _emailCtrl,
                            label: 'Email Address / Phone Number ',
                            icon: Icons.email_outlined,
                            keyboard: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: SSpacing.md),

                          // Password
                          _LoginField(
                            controller: _passwordCtrl,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscure: !_showPass,
                            onSubmit: (_) => _login(),
                            suffix: IconButton(
                              icon: Icon(
                                _showPass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: SColors.textTertiary, size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _showPass = !_showPass),
                            ),
                          ),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                      const UnifiedForgotPasswordPage())),
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.only(
                                      top: SSpacing.xs)),
                              child: Text('Forgot Password?',
                                  style: SText.labelMd.copyWith(
                                      color: SColors.primary)),
                            ),
                          ),

                          const SizedBox(height: SSpacing.sm),

                          // Sign In button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: SColors.border,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: SRadius.radiusMd),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : Text('Sign In',
                                      style: SText.labelLg.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700)),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: SSpacing.lg),

              // Sign up link (customers only)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("New customer? ",
                    style: SText.bodyXs.copyWith(
                        color: SColors.textSecondary)),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomerSignupPage())),
                  child: Text('Create Account',
                      style: SText.labelMd.copyWith(
                          color: SColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
              ]),

              const SizedBox(height: SSpacing.md),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(SSpacing.md),
    decoration: BoxDecoration(
      color: SColors.errorBg,
      borderRadius: SRadius.radiusMd,
      border: Border.all(
          color: SColors.error.withValues(alpha: 0.3), width: 0.5),
    ),
    child: Row(children: [
      Icon(Icons.error_outline, color: SColors.error, size: 18),
      const SizedBox(width: SSpacing.sm),
      Expanded(child: Text(message,
          style: SText.bodySm.copyWith(color: SColors.error))),
    ]),
  );
}

// ── Lock banner ───────────────────────────────────────────────
class _LockBanner extends StatelessWidget {
  final String message;
  const _LockBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(SSpacing.md),
    decoration: BoxDecoration(
      color: SColors.warningBg,
      borderRadius: SRadius.radiusMd,
      border: Border.all(
          color: SColors.warning.withValues(alpha: 0.4), width: 0.5),
    ),
    child: Row(children: [
      const Icon(Icons.lock_clock_outlined,
          color: SColors.warning, size: 18),
      const SizedBox(width: SSpacing.sm),
      Expanded(child: Text(message,
          style: SText.bodySm.copyWith(color: SColors.warning))),
    ]),
  );
}

// ── Shared login field ────────────────────────────────────────
class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String       label;
  final IconData     icon;
  final TextInputType keyboard;
  final bool         obscure;
  final Widget?      suffix;
  final ValueChanged<String>? onSubmit;

  const _LoginField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.obscure  = false,
    this.suffix,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller:   controller,
    keyboardType: keyboard,
    obscureText:  obscure,
    onSubmitted:  onSubmit,
    style: SText.bodyMd.copyWith(color: SColors.textPrimary),
    decoration: InputDecoration(
      labelText:   label,
      prefixIcon:  Icon(icon, size: 20, color: SColors.textSecondary),
      suffixIcon:  suffix,
      filled:      true,
      fillColor:   SColors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: SSpacing.md,
          vertical: SSpacing.md - SSpacing.xs),
      border: OutlineInputBorder(
          borderRadius: SRadius.radiusMd,
          borderSide: const BorderSide(
              color: SColors.border, width: 0.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: SRadius.radiusMd,
          borderSide: const BorderSide(
              color: SColors.border, width: 0.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: SRadius.radiusMd,
          borderSide: const BorderSide(
              color: SColors.primary, width: 1.5)),
      labelStyle: SText.labelLg.copyWith(color: SColors.textSecondary),
    ),
  );
}

// ═════════════════════════════════════════════════════════════
// UNIFIED FORGOT PASSWORD PAGE
// Works for both admin (Firebase Auth) and customer (Firestore)
// ═════════════════════════════════════════════════════════════

class UnifiedForgotPasswordPage extends StatefulWidget {
  const UnifiedForgotPasswordPage({super.key});
  @override
  State<UnifiedForgotPasswordPage> createState() =>
      _UnifiedForgotPasswordPageState();
}

class _UnifiedForgotPasswordPageState
    extends State<UnifiedForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool   _isLoading = false;
  bool   _sent      = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _reset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Enter a valid email address',
            style: SText.bodyMd.copyWith(color: Colors.white)),
        backgroundColor: SColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: SRadius.radiusMd),
        margin: const EdgeInsets.all(SSpacing.md),
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Works for both admin and customer accounts, since both are real
      // Firebase Auth accounts — Firebase Auth itself doesn't distinguish
      // between them, it just needs a valid email on file.
      await auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) setState(() { _isLoading = false; _sent = true; });
    } on auth.FirebaseAuthException catch (e) {
      // Deliberately vague on "user not found" so this can't be used to
      // probe which emails have accounts — but we still show real errors
      // for things the user can actually act on (e.g. malformed email).
      if (mounted) {
        setState(() => _isLoading = false);
        if (e.code == 'user-not-found') {
          // Pretend it worked — same message as success — to avoid leaking
          // whether an account exists for this email.
          setState(() => _sent = true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message ?? 'Could not send reset email',
                style: SText.bodyMd.copyWith(color: Colors.white)),
            backgroundColor: SColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: SRadius.radiusMd),
            margin: const EdgeInsets.all(SSpacing.md),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e',
              style: SText.bodyMd.copyWith(color: Colors.white)),
          backgroundColor: SColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: SRadius.radiusMd),
          margin: const EdgeInsets.all(SSpacing.md),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Forgot Password',
            style: SText.headingMd.copyWith(color: Colors.white)),
        backgroundColor: SColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: SSpacing.xl),

            // Icon
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: SColors.primaryBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset_outlined,
                    size: 40, color: SColors.primary),
              ),
            ),

            const SizedBox(height: SSpacing.lg),

            Text('Reset your password',
                style: SText.headingLg.copyWith(
                    color: SColors.textPrimary)),
            const SizedBox(height: SSpacing.xs),
            Text(
              _sent
                  ? 'Password reset email sent. Check your inbox (and spam folder).'
                  : 'Enter your email address. We\'ll send you a link to reset your password. Works for both Admin and Customer accounts.',
              style: SText.bodyMd.copyWith(
                  color: SColors.textSecondary, height: 1.6),
            ),

            const SizedBox(height: SSpacing.xl),

            if (!_sent) ...[
              _LoginField(
                controller: _emailCtrl,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
              ),

              const SizedBox(height: SSpacing.lg),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: SRadius.radiusMd),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Send Reset Link',
                          style: SText.labelLg.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ] else ...[
              // Success state
              Container(
                padding: const EdgeInsets.all(SSpacing.lg),
                decoration: BoxDecoration(
                  color: SColors.successBg,
                  borderRadius: SRadius.radiusLg,
                  border: Border.all(
                      color: SColors.success.withValues(alpha: 0.3),
                      width: 0.5),
                ),
                child: Column(children: [
                  const Icon(Icons.mark_email_read_outlined,
                      color: SColors.success, size: 48),
                  const SizedBox(height: SSpacing.md),
                  Text('Email sent!',
                      style: SText.headingMd.copyWith(
                          color: SColors.success)),
                  const SizedBox(height: SSpacing.xs),
                  Text(
                    'Check ${_emailCtrl.text} for the reset link.',
                    textAlign: TextAlign.center,
                    style: SText.bodyMd.copyWith(
                        color: SColors.textSecondary),
                  ),
                ]),
              ),

              const SizedBox(height: SSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SColors.primary,
                    side: BorderSide(color: SColors.primary),
                    padding: const EdgeInsets.symmetric(
                        vertical: SSpacing.md),
                    shape: RoundedRectangleBorder(
                        borderRadius: SRadius.radiusMd),
                  ),
                  child: Text('Back to Sign In',
                      style: SText.labelLg.copyWith(
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],

            const SizedBox(height: SSpacing.md),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: SText.labelMd.copyWith(
                        color: SColors.textTertiary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// FIRST-TIME SETUP (replaces the one in admin_login_page.dart)
// Shown when no admin exists yet — only renders once ever
// ═════════════════════════════════════════════════════════════

class _FirstTimeSetupPage extends StatefulWidget {
  @override
  State<_FirstTimeSetupPage> createState() => _FirstTimeSetupPageState();
}

class _FirstTimeSetupPageState extends State<_FirstTimeSetupPage> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool  _showPass  = false;
  bool  _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty) {
      _snack('Please fill all fields', isError: true);
      return;
    }
    if (_passCtrl.text.length < 6) {
      _snack('Password must be at least 6 characters', isError: true);
      return;
    }
    if (_passCtrl.text != _confCtrl.text) {
      _snack('Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final ok = await context.read<AdminUserProvider>().setupFirstAdmin(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    setState(() => _isLoading = false);
    if (!mounted || !context.mounted) return;

    if (ok) {
      await context.read<AdminUserProvider>().login(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted || !context.mounted) return;
      Navigator.pushReplacementNamed(context, '/admin-home');
    } else {
      _snack('Setup failed. Please try again.', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg,
            style: SText.bodyMd.copyWith(color: Colors.white)),
        backgroundColor: isError ? SColors.error : SColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: SRadius.radiusMd),
        margin: const EdgeInsets.all(SSpacing.md),
      ));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(children: [
        Container(decoration: const BoxDecoration(gradient: SGradient.primary)),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: size.height * 0.74,
            decoration: const BoxDecoration(
              color: SColors.background,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(SRadius.xl)),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom
                    + SSpacing.xl),
            child: Column(children: [
              SizedBox(
                height: size.height * 0.24,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.5),
                      ),
                      child: const Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: SSpacing.md),
                    Text('First Time Setup',
                        style: SText.headingXl.copyWith(
                            color: SColors.textOnDark)),
                    const SizedBox(height: SSpacing.xs),
                    Text('Create the admin account to get started',
                        style: SText.bodySm.copyWith(
                            color: SColors.textOnDarkSub)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: SSpacing.lg),
                child: Container(
                  padding: SSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: SColors.surface,
                    borderRadius: SRadius.radiusLg,
                    border: Border.all(
                        color: SColors.border, width: 0.5),
                    boxShadow: SShadow.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Account Details',
                          style: SText.headingMd.copyWith(
                              color: SColors.textPrimary)),
                      const SizedBox(height: SSpacing.xs),
                      Text('This will be your permanent admin credentials',
                          style: SText.bodyXs.copyWith(
                              color: SColors.textSecondary)),
                      const SizedBox(height: SSpacing.lg),
                      _LoginField(controller: _nameCtrl,
                          label: 'Full Name', icon: Icons.person_outline),
                      const SizedBox(height: SSpacing.md),
                      _LoginField(controller: _emailCtrl,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboard: TextInputType.emailAddress),
                      const SizedBox(height: SSpacing.md),
                      _LoginField(
                        controller: _passCtrl,
                        label: 'Password (min 6 chars)',
                        icon: Icons.lock_outline,
                        obscure: !_showPass,
                        suffix: IconButton(
                          icon: Icon(
                            _showPass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: SColors.textTertiary, size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _showPass = !_showPass),
                        ),
                      ),
                      const SizedBox(height: SSpacing.md),
                      _LoginField(
                        controller: _confCtrl,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscure: !_showPass,
                      ),
                      const SizedBox(height: SSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _setup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: SRadius.radiusMd),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : Text('Create Admin Account',
                                  style: SText.labelLg.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
