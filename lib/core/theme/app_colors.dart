import 'package:flutter/material.dart';

/// Central color palette for ست الكل.
/// All colors are derived from an Egyptian clay / terracotta brand identity.
abstract final class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFB5541A); // warm terracotta / Egyptian clay
  static const Color primaryLight = Color(0xFFD4723F);
  static const Color primaryDark = Color(0xFF8B3D10);

  // ── Secondary / Cream ──────────────────────────────────────────────────────
  static const Color secondary = Color(0xFFF5EDD8);
  static const Color secondaryDark = Color(0xFFE8D9B8);

  // ── Accent / Olive green ───────────────────────────────────────────────────
  static const Color accent = Color(0xFF3D6B2E);
  static const Color accentLight = Color(0xFF5A8C42);

  // ── Backgrounds & Surfaces ─────────────────────────────────────────────────
  static const Color background = Color(0xFFFAF7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5EDD8);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1C1C1E); // dark charcoal
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFFADADAD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2D8A4E);
  static const Color warning = Color(0xFFE8A020);
  static const Color error = Color(0xFFD32F2F);

  // ── Decorative ────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFEEEEEE);
  static const Color shadow = Color(0x1A000000);

  // ── Shimmer ────────────────────────────────────────────────────────────────
  static const Color shimmer = Color(0xFFE8E0D0);
  static const Color shimmerHighlight = Color(0xFFF5EDD8);

  // ── Ratings ────────────────────────────────────────────────────────────────
  static const Color starActive = Color(0xFFF4A833);
  static const Color starInactive = Color(0xFFDDD5C5);

  // ── Tags & Badges ──────────────────────────────────────────────────────────
  static const Color tagBackground = Color(0xFFF0EBE0);
  static const Color tagText = Color(0xFF5C4A30);
  static const Color badgeBackground = Color(0xFFD32F2F);
  static const Color badgeText = Color(0xFFFFFFFF);

  // ── Cards & Inputs ────────────────────────────────────────────────────────
  static const Color cardBorder = Color(0xFFEDE6D8);
  static const Color inputBorder = Color(0xFFD8CFBF);
  static const Color inputFill = Color(0xFFFAF7F2);

  // ── Bottom Navigation ─────────────────────────────────────────────────────
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navSelected = Color(0xFFB5541A);
  static const Color navUnselected = Color(0xFFADADAD);

  // ── Role Badges ───────────────────────────────────────────────────────────
  static const Color vendorBadge = Color(0xFF3D6B2E);
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
