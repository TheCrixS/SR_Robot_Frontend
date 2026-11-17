import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'sr_card.dart';

/// Fila de menú con ícono en contenedor pastel, valor opcional y chevron.
class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SrCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: SrRobotColors.softTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: SrRobotColors.primaryTeal),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppText.bodyMedium)),
            if (trailing != null)
              Text(trailing!,
                  style: AppText.meta.copyWith(
                      color: SrRobotColors.darkTeal, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: SrRobotColors.textGray),
          ],
        ),
      ),
    );
  }
}
