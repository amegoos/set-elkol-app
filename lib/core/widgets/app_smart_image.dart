import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A smart image widget that seamlessly handles:
/// 1. Base64 data URIs (e.g. 'data:image/jpeg;base64,...')
/// 2. Local Flutter assets (e.g., 'assets/images/molokhia_hero.jpg')
/// 3. Local device files (e.g., '/var/mobile/...', 'file://...')
/// 4. Remote network images via CachedNetworkImage
/// 5. Graceful fallback when image is null, empty, or fails to load
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
    } else if (url.startsWith('data:image')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64Data = commaIndex != -1 ? url.substring(commaIndex + 1) : url;
        final bytes = base64Decode(base64Data);
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      } catch (_) {
        imageWidget = _buildFallback();
      }
    } else if (url.startsWith('assets/')) {
      imageWidget = Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else if (!kIsWeb && (url.startsWith('/') || url.startsWith('file://'))) {
      try {
        final filePath = url.replaceFirst('file://', '');
        final file = File(filePath);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildFallback(),
          );
        } else {
          imageWidget = _buildFallback();
        }
      } catch (_) {
        imageWidget = _buildFallback();
      }
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

    if (clean.startsWith('data:image')) {
      try {
        final commaIndex = clean.indexOf(',');
        final base64Data =
            commaIndex != -1 ? clean.substring(commaIndex + 1) : clean;
        return MemoryImage(base64Decode(base64Data));
      } catch (_) {
        return null;
      }
    }

    if (clean.startsWith('assets/')) {
      return AssetImage(clean);
    }

    if (!kIsWeb && (clean.startsWith('/') || clean.startsWith('file://'))) {
      try {
        final path = clean.replaceFirst('file://', '');
        return FileImage(File(path));
      } catch (_) {
        return null;
      }
    }

    return CachedNetworkImageProvider(clean);
  }
}
