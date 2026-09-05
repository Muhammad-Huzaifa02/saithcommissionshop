// splash_page.dart  —  Saith Commission Shop

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:saithcommissionshop/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _badgeCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulse;
  late Animation<double> _particleAnim;
  late Animation<double> _badgeFade;
  late Animation<Offset> _badgeSlide;

  @override
  void initState() {
    super.initState();

    _logoCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _textCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _badgeCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _logoScale    = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade     = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.5)));
    _textFade     = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    _textSlide    = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _pulse        = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _particleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_particleCtrl);
    _badgeFade    = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeIn));
    _badgeSlide   = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOutBack));

    unawaited(_startSequence());
  }

  Future<void> _startSequence() async {
    await _logoCtrl.forward();
    await _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _badgeCtrl.forward();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: SGradient.primary),
        child: Stack(
          children: [
            // Floating particles
            AnimatedBuilder(
              animation: _particleAnim,
              builder: (_, __) => CustomPaint(
                painter: _ParticlePainter(_particleAnim.value),
                size: MediaQuery.of(context).size,
              ),
            ),

            // Subtle bottom arc
            Positioned(
              bottom: -60,
              left: -60,
              right: -60,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Logo ──────────────────────────────────────
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) =>
                        Transform.scale(scale: _pulse.value, child: child),
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: _LogoCircle(),
                      ),
                    ),
                  ),

                  const SizedBox(height: SSpacing.xl),

                  // ── Text block ────────────────────────────────
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          Text(
                            'Saith Commission Shop',
                            textAlign: TextAlign.center,
                            style: SText.displayMd.copyWith(
                              color: SColors.textOnDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: SSpacing.sm),
                          Text(
                            'Professional Rice Business Management',
                            textAlign: TextAlign.center,
                            style: SText.bodyMd.copyWith(
                              color: SColors.textOnDarkSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: SSpacing.xl),

                  // ── Feature badges ────────────────────────────
                  SlideTransition(
                    position: _badgeSlide,
                    child: FadeTransition(
                      opacity: _badgeFade,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: SSpacing.sm,
                        runSpacing: SSpacing.sm,
                        children: const [
                          _FeatureBadge(label: '📦 Stock'),
                          _FeatureBadge(label: '🧾 Invoices'),
                          _FeatureBadge(label: '📊 Analytics'),
                          _FeatureBadge(label: '💬 WhatsApp'),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Loading dots ──────────────────────────────
                  const _LoadingDots(),
                  const SizedBox(height: SSpacing.xs),
                  Text(
                    'Loading...',
                    style: SText.labelSm.copyWith(
                      color: SColors.textOnDarkSub,
                    ),
                  ),

                  const SizedBox(height: SSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logo circle ───────────────────────────────────────────────
class _LogoCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: SColors.primaryXLight.withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(SSpacing.lg),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront,
                    size: 64, color: SColors.primary),
                const SizedBox(height: SSpacing.xs),
                Text('Saith',
                    style: SText.labelMd.copyWith(
                      color: SColors.primary,
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Feature badge pill ────────────────────────────────────────
class _FeatureBadge extends StatelessWidget {
  final String label;
  const _FeatureBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: SSpacing.md, vertical: SSpacing.xs + 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: SRadius.radiusFull,
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: SText.labelSm.copyWith(color: SColors.textOnDark),
      ),
    );
  }
}

// ── Loading dots (unchanged logic, new colors) ────────────────
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay    = i / 3;
            final progress = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity  = sin(progress * pi).clamp(0.25, 1.0);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      );
}

// ── Particle painter (unchanged) ──────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rng   = Random(42);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 24; i++) {
      final x      = rng.nextDouble() * size.width;
      final startY = rng.nextDouble() * size.height;
      final speed  = 0.2 + rng.nextDouble() * 0.6;
      final y      = (startY - progress * size.height * speed) % size.height;
      final radius = 1.5 + rng.nextDouble() * 3.5;
      final opacity= 0.04 + rng.nextDouble() * 0.12;
      paint.color  = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
