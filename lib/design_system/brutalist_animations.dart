import 'package:flutter/animation.dart';

/// Animations brutalistes — Ultra-fluides 60fps.
///
/// Courbes spring() et bouncy, pas de linear.
/// Transitions rapides et énergiques.

class BrutalistAnimations {
  BrutalistAnimations._();

  /// Durées standards
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);

  /// Courbes — Spring-based pour un feeling "brut mais fluide"
  static const Curve enterCurve = Curves.easeOutBack;
  static const Curve exitCurve = Curves.easeInBack;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve sharpCurve = Curves.easeOutCubic;

  /// Courbe personnalisée pour les transitions de page
  static const Curve pageTransition = Curves.fastLinearToSlowEaseIn;
}
