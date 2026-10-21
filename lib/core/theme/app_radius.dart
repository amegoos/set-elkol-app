import 'package:flutter/material.dart';

/// Border-radius constants for ست الكل.
/// Use these instead of inline BorderRadius.circular() calls.
abstract final class AppRadius {
  AppRadius._();

  // ── Semantic BorderRadius ─────────────────────────────────────────────────

  /// 4 dp — subtle rounding for small elements (badges, tags).
  static const BorderRadius small = BorderRadius.all(Radius.circular(4));

  /// 12 dp — default rounding for chips, inputs, and secondary buttons.
  static const BorderRadius medium = BorderRadius.all(Radius.circular(12));

  /// 20 dp — pronounced rounding for cards, modals.
  static const BorderRadius large = BorderRadius.all(Radius.circular(20));

  /// 32 dp — very rounded elements.
  static const BorderRadius extraLarge = BorderRadius.all(Radius.circular(32));

  /// 100 dp — effectively a pill / fully circular shape.
  static const BorderRadius circular = BorderRadius.all(Radius.circular(100));

  // ── Component-specific aliases ────────────────────────────────────────────

  /// Card border radius.
  static const BorderRadius card = medium;

  /// Primary and outlined button border radius.
  static const BorderRadius button = circular;

  /// Text field / input border radius.
  static const BorderRadius input = medium;

  /// Chip border radius.
  static const BorderRadius chip = BorderRadius.all(Radius.circular(8));

  /// Bottom sheet — only top corners are rounded.
  static const BorderRadius bottomSheet = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(24),
  );

  /// Dialog border radius (all corners).
  static const BorderRadius dialog = BorderRadius.all(Radius.circular(20));
}
