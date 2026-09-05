// customer_signup_page.dart  —  Saith Commission Shop

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/customer_provider.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';

class CustomerSignupPage extends StatefulWidget {
  const CustomerSignupPage({super.key});
  @override
  State<CustomerSignupPage> createState() => _CustomerSignupPageState();
}

class _CustomerSignupPageState extends State<CustomerSignupPage>
    with SingleTickerProviderStateMixin {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool  _showPass    = false;
  bool  _isLoading   = false;

  late AnimationController _entranceCtrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade  = CurvedAnimation(parent: _entranceCtrl,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)));
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _emailCtrl,
      _addressCtrl, _passCtrl, _confirmCtrl]) c.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final error = await context.read<CustomerProvider>().register(
      name:     _nameCtrl.text.trim(),
      phone:    _phoneCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      address:  _addressCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!context.mounted) return;
    setState(() => _isLoading = false);
    if (!mounted) return;

    if (error == null) {
      await context.read<CustomerProvider>().login(
        identifier: _emailCtrl.text.trim(),
        password:   _passCtrl.text,
      );
      if (!mounted || !context.mounted) return;
      Navigator.pushReplacementNamed(context, '/customer-home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error,
            style: SText.bodyMd.copyWith(color: Colors.white)),
        backgroundColor: SColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: SRadius.radiusMd),
        margin: const EdgeInsets.all(SSpacing.md),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(children: [
        Container(decoration: const BoxDecoration(gradient: SGradient.primary)),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: size.height * 0.78,
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
              // Header
              SizedBox(
                height: size.height * 0.20,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.5),
                      ),
                      child: const Icon(Icons.person_add_alt_1_outlined,
                          size: 34, color: Colors.white),
                    ),
                    const SizedBox(height: SSpacing.md),
                    Text('Create Account',
                        style: SText.headingXl.copyWith(
                            color: SColors.textOnDark)),
                    const SizedBox(height: SSpacing.xs),
                    Text('Join Saith Commission Shop',
                        style: SText.bodySm.copyWith(
                            color: SColors.textOnDarkSub)),
                  ],
                ),
              ),

              // Form card
              FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: SSpacing.lg),
                    child: Form(
                      key: _formKey,
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
                            Text('Account Details',
                                style: SText.headingMd.copyWith(
                                    color: SColors.textPrimary)),
                            const SizedBox(height: SSpacing.xs),
                            Text('All starred fields are required',
                                style: SText.bodyXs.copyWith(
                                    color: SColors.textSecondary)),
                            const SizedBox(height: SSpacing.lg),

                            _Field(ctrl: _nameCtrl, label: 'Full Name *',
                                icon: Icons.person_outline,
                                validator: (v) => (v?.trim().isEmpty ?? true)
                                    ? 'Name is required' : null),
                            const SizedBox(height: SSpacing.md),

                            _Field(ctrl: _phoneCtrl, label: 'Mobile Number *',
                                icon: Icons.phone_outlined,
                                keyboard: TextInputType.phone,
                                validator: (v) => (v?.trim().isEmpty ?? true)
                                    ? 'Phone is required' : null),
                            const SizedBox(height: SSpacing.md),

                            _Field(ctrl: _emailCtrl, label: 'Email *',
                                icon: Icons.email_outlined,
                                keyboard: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email is required';
                                  if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
                                  return null;
                                }),
                            const SizedBox(height: SSpacing.md),

                            _Field(ctrl: _addressCtrl, label: 'Address (optional)',
                                icon: Icons.location_on_outlined),
                            const SizedBox(height: SSpacing.md),

                            _Field(
                              ctrl: _passCtrl,
                              label: 'Password *',
                              icon: Icons.lock_outline,
                              obscure: !_showPass,
                              suffix: IconButton(
                                icon: Icon(
                                  _showPass ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: SColors.textTertiary, size: 20),
                                onPressed: () =>
                                    setState(() => _showPass = !_showPass),
                              ),
                              validator: (v) => (v?.length ?? 0) < 6
                                  ? 'Minimum 6 characters' : null,
                            ),
                            const SizedBox(height: SSpacing.md),

                            _Field(
                              ctrl: _confirmCtrl,
                              label: 'Confirm Password *',
                              icon: Icons.lock_outline,
                              obscure: !_showPass,
                              validator: (v) => v != _passCtrl.text
                                  ? 'Passwords do not match' : null,
                            ),
                            const SizedBox(height: SSpacing.lg),

                            SizedBox(
                              width: double.infinity, height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: SRadius.radiusMd),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white))
                                    : Text('Create Account',
                                        style: SText.labelLg.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700)),
                              ),
                            ),

                            const SizedBox(height: SSpacing.md),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.pushReplacementNamed(
                                    context, '/login'),
                                child: Text('Already have an account? Sign In',
                                    style: SText.labelMd.copyWith(
                                        color: SColors.primary)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: SSpacing.md),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios,
                    size: 14, color: SColors.textOnDarkSub),
                label: Text('Go Back',
                    style: SText.labelMd.copyWith(
                        color: SColors.textOnDarkSub)),
              ),
              const SizedBox(height: SSpacing.md),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String       label;
  final IconData     icon;
  final TextInputType keyboard;
  final bool         obscure;
  final Widget?      suffix;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.obscure  = false,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:   ctrl,
    keyboardType: keyboard,
    obscureText:  obscure,
    validator:    validator,
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
          borderSide: const BorderSide(color: SColors.border, width: 0.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: SRadius.radiusMd,
          borderSide: const BorderSide(color: SColors.border, width: 0.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: SRadius.radiusMd,
          borderSide: const BorderSide(color: SColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: SRadius.radiusMd,
          borderSide: const BorderSide(color: SColors.error, width: 1)),
      labelStyle: SText.labelLg.copyWith(color: SColors.textSecondary),
    ),
  );
}
