// onboarding_page.dart  —  Saith Commission Shop

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';

// ── Page data model ───────────────────────────────────────────
class _OPage {
  final IconData icon;
  final String   title;
  final String   desc;
  final String   tag;
  final Color    accentColor;
  final List<String> bullets;

  const _OPage({
    required this.icon,
    required this.title,
    required this.desc,
    required this.tag,
    required this.accentColor,
    required this.bullets,
  });
}

const List<_OPage> _pages = [
  _OPage(
    icon:        Icons.storefront_outlined,
    title:       'Saith Commission Shop',
    desc:        'Pakistan\'s premier rice wholesale management system — built for commission shops, run by professionals.',
    tag:         'Welcome',
    accentColor: SColors.primary,
    bullets:     ['Wholesale rice management', 'Admin & customer portals', 'Works offline too'],
  ),
  _OPage(
    icon:        Icons.inventory_2_outlined,
    title:       'Real-Time Stock & Prices',
    desc:        'Update prices and stock instantly. Customers always see the latest mandi rates — no phone calls needed.',
    tag:         'Inventory',
    accentColor: SColors.catTeal,
    bullets:     ['Live price updates', 'Stock batch tracking', 'Barcode scanner support'],
  ),
  _OPage(
    icon:        Icons.receipt_long_outlined,
    title:       'Smart Invoice Management',
    desc:        'Create invoices in seconds. Track payments, pending balances, and full transaction history automatically.',
    tag:         'Invoicing',
    accentColor: SColors.catBlue,
    bullets:     ['PDF invoice generation', 'Overdue tracking', 'Multi-rate invoicing'],
  ),
  _OPage(
    icon:        Icons.people_outline,
    title:       'Customer Ledger & WhatsApp',
    desc:        'Every customer gets a full ledger. Send PDF statements and payment reminders directly via WhatsApp.',
    tag:         'Customers',
    accentColor: SColors.catPurple,
    bullets:     ['Full ledger per customer', 'WhatsApp PDF share', 'Payment history'],
  ),
  _OPage(
    icon:        Icons.bar_chart_outlined,
    title:       'Analytics & Reports',
    desc:        'Track sales, top products, customer tiers — export to Excel or PDF. Everything at a glance.',
    tag:         'Reports',
    accentColor: SColors.catOrange,
    bullets:     ['Revenue charts', 'Excel & PDF export', 'Top customer analytics'],
  ),
];

// ── Main widget ───────────────────────────────────────────────
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {

  final _pageCtrl   = PageController();
  int   _currentPage = 0;

  late AnimationController _contentCtrl;
  late Animation<double>   _contentFade;
  late Animation<Offset>   _contentSlide;

  @override
  void initState() {
    super.initState();
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _contentFade  = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));
    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted || !context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOutCubic);
    } else {
      _finish();
    }
  }

  void _prev() {
    _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut);
  }

  void _onPageChanged(int i) {
    _contentCtrl.reset();
    setState(() => _currentPage = i);
    _contentCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: SColors.background,
      body: Column(
        children: [
          // ── Gradient header with icon ──────────────────────
          _OnboardingHeader(
            page:         page,
            contentFade:  _contentFade,
            contentSlide: _contentSlide,
            height:       size.height * 0.42,
          ),

          // ── Page content card ──────────────────────────────
          Expanded(
            child: PageView.builder(
              controller:    _pageCtrl,
              onPageChanged: _onPageChanged,
              itemCount:     _pages.length,
              itemBuilder:   (_, i) => _PageContentCard(
                page:         _pages[i],
                contentFade:  i == _currentPage ? _contentFade  : const AlwaysStoppedAnimation(1.0),
                contentSlide: i == _currentPage ? _contentSlide : const AlwaysStoppedAnimation(Offset.zero),
              ),
            ),
          ),

          // ── Bottom controls ────────────────────────────────
          _BottomControls(
            currentPage:  _currentPage,
            totalPages:   _pages.length,
            activeColor:  page.accentColor,
            onNext:       _next,
            onPrev:       _prev,
            onSkip:       _finish,
          ),
        ],
      ),
    );
  }
}

// ── Header with gradient + floating icon ──────────────────────
class _OnboardingHeader extends StatelessWidget {
  final _OPage                 page;
  final Animation<double>      contentFade;
  final Animation<Offset>      contentSlide;
  final double                 height;

  const _OnboardingHeader({
    required this.page,
    required this.contentFade,
    required this.contentSlide,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width:  double.infinity,
      decoration: const BoxDecoration(
        gradient: SGradient.primary,
        borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(SRadius.xl)),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Top row: tag + skip
            Positioned(
              top: SSpacing.sm,
              left:  SSpacing.md,
              right: SSpacing.md,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: SSpacing.md, vertical: SSpacing.xs),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: SRadius.radiusFull,
                    ),
                    child: Text(page.tag,
                        style: SText.labelSm.copyWith(
                            color: SColors.textOnDark)),
                  ),
                  TextButton(
                    onPressed: null, // handled by BottomControls
                    child: const Text('Skip',
                        style: SText.labelLg),
                  ),
                ],
              ),
            ),

            // Central icon
            Center(
              child: FadeTransition(
                opacity: contentFade,
                child: SlideTransition(
                  position: contentSlide,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Outer glow ring
                      Container(
                        width: 130, height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1),
                        ),
                        child: Center(
                          child: Container(
                            width: 96, height: 96,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(page.icon,
                                size: 48, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Page indicator dots at bottom
            Positioned(
              bottom: SSpacing.md,
              left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _pages.indexOf(page);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width:  active ? 24 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: SRadius.radiusFull,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page content card ─────────────────────────────────────────
class _PageContentCard extends StatelessWidget {
  final _OPage            page;
  final Animation<double> contentFade;
  final Animation<Offset> contentSlide;

  const _PageContentCard({
    required this.page,
    required this.contentFade,
    required this.contentSlide,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: contentFade,
      child: SlideTransition(
        position: contentSlide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              SSpacing.lg, SSpacing.lg, SSpacing.lg, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                page.title,
                style: SText.headingXl.copyWith(color: SColors.textPrimary),
              ),
              const SizedBox(height: SSpacing.sm),

              // Description
              Text(
                page.desc,
                style: SText.bodyMd.copyWith(
                  color: SColors.textSecondary,
                  height: 1.65,
                ),
              ),

              const SizedBox(height: SSpacing.lg),

              // Bullet feature list
              ...page.bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: SSpacing.sm),
                child: Row(children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: page.accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check,
                        color: page.accentColor, size: 14),
                  ),
                  const SizedBox(width: SSpacing.sm),
                  Text(b,
                      style: SText.bodySm.copyWith(
                          color: SColors.textPrimary,
                          fontWeight: FontWeight.w500)),
                ]),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom controls ───────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  final int        currentPage;
  final int        totalPages;
  final Color      activeColor;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onSkip;

  const _BottomControls({
    required this.currentPage,
    required this.totalPages,
    required this.activeColor,
    required this.onNext,
    required this.onPrev,
    required this.onSkip,
  });

  bool get _isFirst => currentPage == 0;
  bool get _isLast  => currentPage == totalPages - 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        SSpacing.lg,
        SSpacing.md,
        SSpacing.lg,
        SSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: SColors.surface,
        border: Border(
            top: BorderSide(color: SColors.border, width: 0.5)),
      ),
      child: Row(children: [
        // Back button
        AnimatedOpacity(
          opacity: _isFirst ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: _isFirst ? null : onPrev,
            child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: SColors.surfaceAlt,
                borderRadius: SRadius.radiusMd,
                border: Border.all(color: SColors.border, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  color: SColors.textSecondary, size: 18),
            ),
          ),
        ),

        const SizedBox(width: SSpacing.md),

        // Next / Get Started
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 50,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: SRadius.radiusMd,
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: SRadius.radiusMd,
                onTap: onNext,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLast ? 'Get Started' : 'Next',
                        style: SText.labelLg.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: SSpacing.sm),
                      Icon(
                        _isLast
                            ? Icons.check_circle_outline
                            : Icons.arrow_forward,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Skip on non-last pages
        if (!_isLast) ...[
          const SizedBox(width: SSpacing.md),
          GestureDetector(
            onTap: onSkip,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SSpacing.sm),
              child: Text('Skip',
                  style: SText.labelMd.copyWith(
                      color: SColors.textTertiary)),
            ),
          ),
        ],
      ]),
    );
  }
}
