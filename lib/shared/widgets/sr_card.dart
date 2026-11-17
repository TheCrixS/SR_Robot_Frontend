import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Tarjeta blanca, radio 20 y sombra difusa.
class SrCard extends StatelessWidget {
  const SrCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.margin,
    this.color = SrRobotColors.surfaceWhite,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: SrRobotColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Avatar cuadrado redondeado con iniciales sobre color sólido.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size = 48,
    this.seed,
  });

  final String initials;
  final double size;
  final String? seed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SrRobotColors.avatarColorFor(seed ?? initials),
        borderRadius: BorderRadius.circular(size >= 56 ? 16 : 14),
      ),
      child: Text(
        initials,
        style: AppText.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

/// Etiqueta pequeña sobre fondo pastel (11 px, Medium).
class SrTag extends StatelessWidget {
  const SrTag(this.text,
      {super.key,
      this.color = SrRobotColors.softTeal,
      this.textColor = SrRobotColors.darkTeal,
      this.icon});

  final String text;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(text, style: AppText.tag.copyWith(color: textColor)),
        ],
      ),
    );
  }
}

/// Calificación con estrella naranja.
class RatingLabel extends StatelessWidget {
  const RatingLabel(this.rating, {super.key, this.count});
  final double rating;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 16, color: SrRobotColors.starOrange),
        const SizedBox(width: 2),
        Text(rating.toStringAsFixed(1),
            style: AppText.meta.copyWith(
                color: SrRobotColors.textInk, fontWeight: FontWeight.w600)),
        if (count != null) Text(' ($count)', style: AppText.meta),
      ],
    );
  }
}

/// Chip de filtro (radio 12, padding 12x6).
class SrFilterChip extends StatelessWidget {
  const SrFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? SrRobotColors.primaryTeal : SrRobotColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? SrRobotColors.primaryTeal
                  : SrRobotColors.lineBorder),
        ),
        child: Text(
          label,
          style: AppText.meta.copyWith(
            color: selected ? Colors.white : SrRobotColors.textInk,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Encabezado de sección con acción opcional.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppText.h2)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: AppText.meta.copyWith(
                    color: SrRobotColors.primaryTeal,
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
