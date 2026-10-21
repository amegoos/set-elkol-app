import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_radius.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.color,
    this.textColor,
    this.width,
    this.height = 50,
    this.fontSize,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Widget? icon;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double height;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? AppColors.primary;
    final fgColor = textColor ?? AppColors.textOnPrimary;

    final style = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: bgColor,
            side: BorderSide(color: bgColor, width: 1.5),
            minimumSize: Size(width ?? double.infinity, height),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            minimumSize: Size(width ?? double.infinity, height),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          );

    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: isOutlined ? bgColor : fgColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  fontSize: fontSize,
                  color: isOutlined ? bgColor : fgColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );

    return isOutlined
        ? OutlinedButton(
            style: style, onPressed: isLoading ? null : onPressed, child: child)
        : ElevatedButton(
            style: style,
            onPressed: isLoading ? null : onPressed,
            child: child);
  }
}
