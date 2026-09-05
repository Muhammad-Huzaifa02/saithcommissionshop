import 'package:flutter/material.dart';

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset beginOffset;

  SlidePageRoute({
    required this.page,
    this.beginOffset = const Offset(1.0, 0),
  }) : super(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) {
      final tween = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOut));
      return SlideTransition(
          position: anim.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 250),
  );
}

class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScalePageRoute({required this.page})
      : super(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) => ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: FadeTransition(opacity: anim, child: child)),
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// Navigate with slide from right.
void navigateSlide(BuildContext context, Widget page) {
  Navigator.push(context, SlidePageRoute(page: page));
}

/// Navigate with fade.
void navigateFade(BuildContext context, Widget page) {
  Navigator.push(context, FadePageRoute(page: page));
}

/// Navigate with scale + fade.
void navigateScale(BuildContext context, Widget page) {
  Navigator.push(context, ScalePageRoute(page: page));
}

/// Replace current with fade.
void navigateReplaceFade(BuildContext context, Widget page) {
  Navigator.pushReplacement(context, FadePageRoute(page: page));
}