import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/l10n_ext.dart';
import '../models/order_model.dart';

/// Línea de tiempo vertical con los 5 estados secuenciales.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order, required this.locale});

  final OrderModel order;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final current = order.state.step;
    final steps = OrderState.sequence;

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(
            state: steps[i],
            done: current >= 0 && i < current,
            active: i == current,
            isLast: i == steps.length - 1,
            entry: _entryFor(steps[i]),
            locale: locale,
          ),
      ],
    );
  }

  TimelineEntry? _entryFor(OrderState s) {
    final list = order.timeline.where((e) => e.state == s).toList();
    return list.isEmpty ? null : list.last;
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.state,
    required this.done,
    required this.active,
    required this.isLast,
    required this.entry,
    required this.locale,
  });

  final OrderState state;
  final bool done;
  final bool active;
  final bool isLast;
  final TimelineEntry? entry;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final reached = done || active;
    final nodeColor = reached ? state.color : SrRobotColors.lineBorder;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: active ? 24 : 20,
                  height: active ? 24 : 20,
                  decoration: BoxDecoration(
                    color: reached ? nodeColor : SrRobotColors.surfaceWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: nodeColor, width: 2),
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: nodeColor.withValues(alpha: 0.35),
                                blurRadius: 10)
                          ]
                        : null,
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded,
                          size: 13, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: done
                          ? state.color
                          : SrRobotColors.lineBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.label(context.l10n),
                    style: (active ? AppText.bodyMedium : AppText.body).copyWith(
                      color: reached
                          ? SrRobotColors.textInk
                          : SrRobotColors.textGray,
                      fontWeight: active ? FontWeight.w700 : null,
                    ),
                  ),
                  if (entry?.timestamp != null)
                    Text(
                      '${DateFormatter.dayMonth(entry!.timestamp!, locale)} · '
                      '${DateFormatter.time(entry!.timestamp!, locale)}',
                      style: AppText.small,
                    ),
                  if (entry?.note != null && entry!.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(entry!.note!, style: AppText.meta),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge con el color semántico del estado.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge(this.state, {super.key});
  final OrderState state;

  @override
  Widget build(BuildContext context) {
    final c = state.color;
    final isYellow = state == OrderState.enReparacion;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: isYellow ? 0.35 : 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        state.label(context.l10n),
        style: AppText.tag.copyWith(
          color: isYellow ? SrRobotColors.textInk : c,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
