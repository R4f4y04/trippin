import 'package:flutter/services.dart';

/// Centralized utility for haptic feedback profiles to ensure consistent
/// micro-interactions across the app.
class AppHaptics {
  /// Very subtle iOS-style tap feedback for simple button taps.
  static Future<void> lightTap() async {
    await HapticFeedback.lightImpact();
  }

  /// Positive double-tap pulse indicating success (e.g., saving an expense, adding a member).
  static Future<void> successBuzz() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.lightImpact();
  }

  /// Warning buzz for deletion or double confirmation steps.
  static Future<void> warningBuzz() async {
    await HapticFeedback.heavyImpact();
  }

  /// Standard selection click for sliders or switching tabs.
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }
}
