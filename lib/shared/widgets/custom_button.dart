import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

enum SrButtonVariant { primary, dark, ghost, ghostLight, yellow }

/// Botón de acción del sistema de diseño (alto 52, radio 16).
class SrButton extends StatelessWidget {
  const SrButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SrButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final SrButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      SrButtonVariant.primary => (SrRobotColors.primaryTeal, Colors.white, null),
      SrButtonVariant.dark => (SrRobotColors.textInk, Colors.white, null),
      SrButtonVariant.yellow =>
        (SrRobotColors.yellowAccent, SrRobotColors.textInk, null),
      SrButtonVariant.ghost => (
          Colors.transparent,
          SrRobotColors.textInk,
          SrRobotColors.lineBorder
        ),
      SrButtonVariant.ghostLight =>
        (Colors.transparent, Colors.white, Colors.white),
    };
    final disabled = onPressed == null || loading;

    final child = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, size: 20, color: fg),
              if (icon != null && label.isNotEmpty) const SizedBox(width: 8),
              if (label.isNotEmpty)
                Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.button.copyWith(color: fg),
                ),
              ),
            ],
          );

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Container(
        width: expand ? double.infinity : null,
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: border == null ? null : Border.all(color: border, width: 1.5),
          boxShadow: variant == SrButtonVariant.primary
              ? [
                  BoxShadow(
                    color: SrRobotColors.primaryTeal.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: disabled ? null : onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: label.isEmpty ? 0 : 20, vertical: 15),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
