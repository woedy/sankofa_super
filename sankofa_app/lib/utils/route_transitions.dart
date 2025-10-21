import 'package:flutter/material.dart';

enum AppPageTransition {
  fade,
  slideUp,
  slideLeft,
  slideRight,
}

class RouteTransitions {
  static const Duration _forwardDuration = Duration(milliseconds: 320);
  static const Duration _reverseDuration = Duration(milliseconds: 260);

  const RouteTransitions._();

  static PageRoute<T> fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: _forwardDuration,
      reverseTransitionDuration: _reverseDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(opacity: curved, child: child);
      },
    );
  }

  static PageRoute<T> slideUp<T>(Widget page) => _slide(page, const Offset(0, 1));

  static PageRoute<T> slideLeft<T>(Widget page) => _slide(page, const Offset(1, 0));

  static PageRoute<T> slideRight<T>(Widget page) => _slide(page, const Offset(-1, 0));

  static PageRoute<T> build<T>(Widget page, AppPageTransition transition) {
    switch (transition) {
      case AppPageTransition.fade:
        return fade(page);
      case AppPageTransition.slideUp:
        return slideUp(page);
      case AppPageTransition.slideLeft:
        return slideLeft(page);
      case AppPageTransition.slideRight:
        return slideRight(page);
    }
  }

  static PageRoute<T> _slide<T>(Widget page, Offset beginOffset) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: _forwardDuration,
      reverseTransitionDuration: _reverseDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final offsetAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
    );
  }
}
