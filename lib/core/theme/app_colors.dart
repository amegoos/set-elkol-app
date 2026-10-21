import 'package:flutter/material.dart';

/// Central color palette for ست الكل.
/// Pink/Fuchsia + Olive Green palette — premium, warm, Egyptian homemade-food marketplace.
abstract final class AppColors {
  AppColors._();

  // ── Brand: Pink/Fuchsia (Primary) ──────────────────────────────────────────
  /// Main CTA buttons, important actions, selected navigation items, interactive highlights.
  static const Color primary = Color(0xFFD63384); // Fuchsia pink
  static const Color primaryLight = Color(0xFFEC4899); // Pink 400
  static const Color primaryDark = Color(0xFFBE185D); // Pink 700
  static const Color primaryContainer = Color(0xFFFCE7F3); // Pink 50
  static const Color onPrimaryContainer = Color(0xFF831843); // Pink 900

  // Secondary / Cream palette
  static const Color secondary = Color(0xFFF5EDD8); // Warm cream
  static const Color secondaryDark = Color(0xFFE8D9B8);

  // ── Olive Green (Secondary/Accent) ─────────────────────────────────────────
  /// Secondary actions, food categories, subtle highlights, selected chips, supporting brand elements.
  static const Color accent = Color(0xFF689F38); // Olive green 600
  static const Color accentLight = Color(0xFF81C784); // Olive green 400
  static const Color accentDark = Color(0xFF33691E); // Olive green 800
  static const Color accentContainer = Color(0xFFF1F8E9); // Olive green 50
  static const Color onAccentContainer = Color(0xFF1B5E20); // Olive green 900

  // ── Backgrounds & Surfaces ─────────────────────────────────────────────────
  static const Color background = Color(0xFFFDFBF7); // Warm white / off-white
  static const Color surface = Color(0xFFFFFFFF); // Pure white cards
  static const Color surfaceVariant = Color(0xFFFEF9F3); // Very light warm tint

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E); // Dark charcoal
  static const Color textSecondary = Color(0xFF6E6E6E); // Soft neutral gray
  static const Color textHint = Color(0xFFADADAD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2D8A4E);
  static const Color warning = Color(0xFFE8A020);
  static const Color error = Color(0xFFD32F2F);

  // ── Decorative ────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFEEE5ED); // Subtle pink-tinted divider
  static const Color shadow = Color(0x1A000000);

  // ── Shimmer ────────────────────────────────────────────────────────────────
  static const Color shimmer = Color(0xFFF5E8F0); // Pink-tinted shimmer
  static const Color shimmerHighlight = Color(0xFFFCE7F3); // Pink 100

  // ── Ratings ────────────────────────────────────────────────────────────────
  static const Color starActive = Color(0xFFF4A833);
  static const Color starInactive = Color(0xFFE8E0E8); // Pink-tinted

  // ── Tags & Badges ──────────────────────────────────────────────────────────
  static const Color tagBackground = Color(0xFFFCE7F3); // Pink 100
  static const Color tagText = Color(0xFF831843); // Pink 900
  static const Color badgeBackground = Color(0xFFD32F2F);
  static const Color badgeText = Color(0xFFFFFFFF);

  // ── Cards & Inputs ────────────────────────────────────────────────────────
  static const Color cardBorder = Color(0xFFEDE0E8); // Subtle pink border
  static const Color inputBorder =
      Color(0xFFD8C8D0); // Pink-tinted input border
  static const Color inputFill = Color(0xFFFEF9F3); // Warm off-white

  // ── Bottom Navigation ─────────────────────────────────────────────────────
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navSelected = Color(0xFFD63384); // Primary pink
  static const Color navUnselected = Color(0xFFADADAD);

  // ── Role Badges ───────────────────────────────────────────────────────────
  static const Color vendorBadge = Color(0xFF689F38); // Olive green
  static const Color deliveryBadge = Color(0xFF1565C0);
  static const Color pickupBadge = Color(0xFF6A1B9A);

  // ── Order Status ──────────────────────────────────────────────────────────
  static const Color pendingStatus = Color(0xFFE8A020);
  static const Color acceptedStatus = Color(0xFF2196F3);
  static const Color preparingStatus = Color(0xFF9C27B0);
  static const Color readyStatus = Color(0xFF2D8A4E);
  static const Color completedStatus = Color(0xFF2D8A4E);
  static const Color cancelledStatus = Color(0xFFD32F2F);
}
