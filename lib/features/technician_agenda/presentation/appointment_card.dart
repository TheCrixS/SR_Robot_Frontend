import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/technician_work_repository.dart';
import '../../../shared/models/business_models.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/order_timeline.dart';
import '../../../shared/widgets/sr_card.dart';
import 'order_actions.dart';

/// Cita del día con badge de modalidad y acciones rápidas.
class AppointmentCard extends ConsumerStatefulWidget {
  const AppointmentCard({super.key, required this.appointment, required this.day});
  final AppointmentModel appointment;
  final DateTime day;

  @override
  ConsumerState<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends ConsumerState<AppointmentCard> {
  bool _busy = false;

  Future<void> _advance(OrderState target, String okMessage) async {
    final orderId = widget.appointment.orderId;
    if (orderId == null) return;
    setState(() => _busy = true);
    try {
      await advanceOrderTo(ref, orderId, target);
      ref.invalidate(agendaProvider(widget.day));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(okMessage)));
      if (target == OrderState.diagnostico) {
        context.push(Routes.order(orderId));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = widget.appointment;
    final closed = a.status == 'CANCELLED' || a.status == 'COMPLETED';
    final state = a.orderState == null ? null : OrderState.fromApi(a.orderState);
    final canStart = !closed && (state == null || state == OrderState.solicitado);
    final canReady = !closed &&
        (state == null ||
            state == OrderState.diagnostico ||
            state == OrderState.enReparacion);

    return SrCard(
      onTap: a.orderId == null ? null : () => context.push(Routes.order(a.orderId!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: SrRobotColors.textInk,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(a.time,
                    style: AppText.bodyMedium.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text(a.clientName, style: AppText.meta),
                  ],
                ),
              ),
              SrTag(
                a.isHome ? l.agendaHome : l.agendaShop,
                icon: a.isHome ? Icons.home_outlined : Icons.storefront_outlined,
                color: a.isHome
                    ? SrRobotColors.yellowAccent.withValues(alpha: 0.4)
                    : SrRobotColors.softTeal,
                textColor: a.isHome ? SrRobotColors.textInk : SrRobotColors.darkTeal,
              ),
            ],
          ),
          if (a.isHome && a.address != null && a.address!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: SrRobotColors.textGray),
                const SizedBox(width: 4),
                Expanded(child: Text(a.address!, style: AppText.small)),
              ],
            ),
          ],
          if (a.notes != null && a.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('“${a.notes!}”', style: AppText.small),
          ],
          const SizedBox(height: 12),
          if (closed)
            SrTag(a.status == 'CANCELLED' ? l.agendaCancelled : l.agendaCompleted,
                color: SrRobotColors.lineBorder, textColor: SrRobotColors.textGray)
          else ...[
            if (state != null) ...[
              OrderStatusBadge(state),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                if (canStart)
                  Expanded(
                    child: SrButton(
                      label: l.agendaStart,
                      loading: _busy,
                      onPressed: () =>
                          _advance(OrderState.diagnostico, l.agendaStarted),
                    ),
                  ),
                if (canStart && canReady) const SizedBox(width: 8),
                if (canReady)
                  Expanded(
                    child: SrButton(
                      label: l.agendaReady,
                      variant: SrButtonVariant.dark,
                      loading: _busy && !canStart,
                      onPressed: () =>
                          _advance(OrderState.listo, l.agendaMarkedReady),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
