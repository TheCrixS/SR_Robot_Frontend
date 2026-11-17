import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/data/config_repository.dart';

/// Categoría: emoji en contenedor pastel de 62x62.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.index,
    required this.onTap,
  });

  final String category;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SrRobotColors.pastels[index % SrRobotColors.pastels.length],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(emojiFor(category), style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 6),
          Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppText.small.copyWith(color: SrRobotColors.textInk),
          ),
        ],
      ),
    );
  }
}
