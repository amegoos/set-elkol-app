import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A smart image widget that seamlessly handles:
/// 1. Local Flutter assets (e.g., 'assets/images/molokhia_hero.jpg')
/// 2. Remote network images via CachedNetworkImage
/// 3. Graceful fallback when image is null, empty, or fails to load
class AppSmartImage extends StatelessWidget {
  const AppSmartImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.restaurant_rounded,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.secondary.withOpacity(0.5),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: (height != null && height! < 50) ? 20 : 36,
          color: AppColors.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    final url = imageUrl?.trim();

    if (url == null || url.isEmpty) {
      imageWidget = _buildFallback();
    } else if (url.startsWith('assets/')) {
      imageWidget = Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade100,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _buildFallback(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Helper to get an ImageProvider for CircleAvatar or BoxDecoration
  static ImageProvider? getProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;
    final clean = imageUrl.trim();
    if (clean.startsWith('assets/')) {
      return AssetImage(clean);
    }
    return CachedNetworkImageProvider(clean);
  }
}
