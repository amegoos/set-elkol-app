import 'package:flutter/material.dart';

/// Spacing scale and EdgeInsets helpers for ست الكل.
/// All layout spacing should come from these constants for consistency.
abstract final class AppSpacing {
  AppSpacing._();

  // ── Spacing scale (dp) ────────────────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // ── Common EdgeInsets ─────────────────────────────────────────────────────

  /// Screen-level horizontal padding; used as the outer margin on most screens.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  /// Standard inner padding for cards and list tiles.
  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  /// Padding inside primary and outlined buttons.
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 14,
  );
}
