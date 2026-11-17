import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/appointments_repository.dart';
import '../../../shared/data/orders_repository.dart';
import '../../../shared/data/quotes_repository.dart';
import '../../../shared/data/technicians_repository.dart';
import '../../../shared/models/technician_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/payment_selector.dart';
import '../../../shared/widgets/sr_card.dart';

class ScheduleAppointmentScreen extends ConsumerWidget {
  const ScheduleAppointmentScreen({super.key, required this.technicianId});
  final String technicianId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(technicianDetailProvider(technicianId));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.scheduleTitle)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            error: e,
            onRetry: () =>
                ref.invalidate(technicianDetailProvider(technicianId))),
        data: (t) => _ScheduleForm(tech: t),
      ),
    );
  }
}

class _ScheduleForm extends ConsumerStatefulWidget {
  const _ScheduleForm({required this.tech});
  final TechnicianModel tech;

  @override
  ConsumerState<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends ConsumerState<_ScheduleForm> {
  late final List<DateTime> _days = List.generate(8, (i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: i));
  });

  TechService? _service;
  late DateTime _day = _days.first;
  String? _time;
  bool _home = false;
  String? _payment;
  final _address = TextEditingController();
  final _notes = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final active = widget.tech.services.where((s) => s.active).toList();
    if (active.length == 1) _service = active.first;
  }

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  int get _homeFee => _home ? widget.tech.homeExtraFee : 0;
  int get _total => (_service?.priceFrom ?? 0) + _homeFee;

  Future<void> _confirm() async {
    final l = context.l10n;
    if (_service == null || _time == null || _payment == null) {
      setState(() => _error = l.scheduleIncomplete);
      return;
    }
    if (_home && _address.text.trim().isEmpty) {
      setState(() => _error = l.quoteAddressRequired);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final summary = await ref.read(appointmentsRepositoryProvider).create(
            technicianId: widget.tech.id,
            serviceId: _service!.id,
            serviceName: _service!.name,
            date: _day,
            time: _time!,
            isHome: _home,
            paymentMethod: _payment!,
            address: _address.text.trim(),
            notes: _notes.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(activeOrderProvider);
      context.pushReplacement(Routes.appointmentSuccess, extra: summary);
    } catch (e) {
      if (!mounted) return;
      // 409: la franja se ocupó; refrescamos disponibilidad.
      ref.invalidate(availabilityProvider(
          (technicianId: widget.tech.id, day: _day)));
      setState(() {
        _time = null;
        _error = errorText(context, e);
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = ref.watch(regionProfileProvider).locale;
    final services = widget.tech.services.where((s) => s.active).toList();
    final slots = ref.watch(
        availabilityProvider((technicianId: widget.tech.id, day: _day)));
    final methods = ref.watch(paymentMethodsProvider).valueOrNull ??
        ref.watch(regionProfileProvider).availablePaymentMethods;

    if (services.isEmpty) {
      return EmptyStateView(title: l.scheduleNoServices);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(widget.tech.businessName, style: AppText.meta),
        _Title(l.scheduleService),
        for (final s in services) ...[
          _SelectableCard(
            selected: _service?.id == s.id,
            onTap: () => setState(() => _service = s),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: AppText.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      if (s.estimatedTime.isNotEmpty)
                        Text(s.estimatedTime, style: AppText.small),
                    ],
                  ),
                ),
                Text(ref.money(s.priceFrom),
                    style: AppText.bodyMedium.copyWith(
                        color: SrRobotColors.darkTeal,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        _Title(l.scheduleDay),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = _days[i];
              final selected = d == _day;
              return GestureDetector(
                onTap: () => setState(() {
                  _day = d;
                  _time = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 58,
                  decoration: BoxDecoration(
                    color: selected
                        ? SrRobotColors.primaryTeal
                        : SrRobotColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: selected
                            ? SrRobotColors.primaryTeal
                            : SrRobotColors.lineBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormatter.weekdayShort(d, locale),
                          style: AppText.small.copyWith(
                              color: selected
                                  ? Colors.white
                                  : SrRobotColors.textGray)),
                      Text('${d.day}',
                          style: AppText.h3.copyWith(
                              color: selected
                                  ? Colors.white
                                  : SrRobotColors.textInk)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _Title(l.scheduleTime),
        slots.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(errorText(context, e), style: AppText.meta),
          data: (list) => list.isEmpty
              ? Text(l.scheduleNoSlots, style: AppText.meta)
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in list)
                      GestureDetector(
                        onTap: () => setState(() => _time = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: 76,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _time == t
                                ? SrRobotColors.textInk
                                : SrRobotColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _time == t
                                    ? SrRobotColors.textInk
                                    : SrRobotColors.lineBorder),
                          ),
                          child: Text(t,
                              style: AppText.meta.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _time == t
                                      ? Colors.white
                                      : SrRobotColors.textInk)),
                        ),
                      ),
                  ],
                ),
        ),
        _Title(l.scheduleMode),
        Row(
          children: [
            Expanded(
              child: _SelectableCard(
                selected: !_home,
                onTap: () => setState(() => _home = false),
                child: Column(
                  children: [
                    const Icon(Icons.storefront_outlined,
                        color: SrRobotColors.primaryTeal),
                    const SizedBox(height: 4),
                    Text(l.scheduleAtShop, style: AppText.bodyMedium),
                  ],
                ),
              ),
            ),
            if (widget.tech.homeService) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _SelectableCard(
                  selected: _home,
                  onTap: () => setState(() => _home = true),
                  child: Column(
                    children: [
                      const Icon(Icons.home_outlined,
                          color: SrRobotColors.primaryTeal),
                      const SizedBox(height: 4),
                      Text(l.scheduleAtHome, style: AppText.bodyMedium),
                      if (widget.tech.homeExtraFee > 0)
                        Text(
                            l.scheduleHomeFee(
                                ref.money(widget.tech.homeExtraFee)),
                            style: AppText.small.copyWith(
                                color: SrRobotColors.darkTeal,
                                fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_home) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _address,
            style: AppText.body,
            decoration: InputDecoration(
              hintText: l.quoteAddressHint,
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: SrRobotColors.textGray),
            ),
          ),
        ],
        _Title(l.schedulePayment),
        PaymentSelector(
          methods: methods,
          selected: _payment,
          onChanged: (m) => setState(() => _payment = m),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          style: AppText.body,
          decoration: InputDecoration(
              hintText: '${l.scheduleNotes} (${l.commonOptional})'),
        ),
        _Title(l.scheduleSummary),
        SrCard(
          child: Column(
            children: [
              SummaryRow(l.scheduleServiceLine,
                  _service == null ? '—' : ref.money(_service!.priceFrom)),
              if (_home)
                SummaryRow(l.scheduleHomeLine, ref.money(_homeFee)),
              const Divider(height: 16),
              SummaryRow(l.commonTotal, ref.money(_total), bold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const EscrowNote(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
        ],
        const SizedBox(height: 20),
        SrButton(
            label: l.scheduleConfirm, loading: _sending, onPressed: _confirm),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(text, style: AppText.h3),
      );
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard(
      {required this.selected, required this.onTap, required this.child});
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? SrRobotColors.softTeal : SrRobotColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                selected ? SrRobotColors.primaryTeal : SrRobotColors.lineBorder,
            width: 1.5,
          ),
        ),
        child: child,
      ),
    );
  }
}
