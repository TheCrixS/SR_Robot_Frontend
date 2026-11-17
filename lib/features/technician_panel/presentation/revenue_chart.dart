import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/business_models.dart';

/// Gráfico de barras de ingresos semanales (sin librerías externas).
/// La última barra (semana actual) se resalta en teal.
class RevenueBarChart extends StatelessWidget {
  const RevenueBarChart({
    super.key,
    required this.weeks,
    required this.labelFor,
    required this.formatAmount,
  });

  final List<WeeklyRevenue> weeks;
  final String Function(WeeklyRevenue) labelFor;
  final String Function(int) formatAmount;

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) return const SizedBox(height: 140);
    final max = weeks.map((w) => w.revenue).fold<int>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 168,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < weeks.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _Bar(
                  fraction: max == 0 ? 0 : weeks[i].revenue / max,
                  highlighted: i == weeks.length - 1,
                  value: weeks[i].revenue == 0 ? '' : formatAmount(weeks[i].revenue),
                  label: labelFor(weeks[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.highlighted,
    required this.value,
    required this.label,
  });

  final double fraction;
  final bool highlighted;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (highlighted && value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: FittedBox(
              child: Text(value,
                  style: AppText.tag.copyWith(
                      color: SrRobotColors.darkTeal, fontWeight: FontWeight.w700)),
            ),
          ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Container(
            height: 6 + 110 * v,
            decoration: BoxDecoration(
              color: highlighted
                  ? SrRobotColors.primaryTeal
                  : SrRobotColors.softTeal,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, maxLines: 1, style: AppText.tag.copyWith(color: SrRobotColors.textGray)),
      ],
    );
  }
}
