import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/technician_work_repository.dart';
import '../../../shared/widgets/empty_state_view.dart';
import 'appointment_card.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class TechnicianAgendaScreen extends ConsumerStatefulWidget {
  const TechnicianAgendaScreen({super.key});

  @override
  ConsumerState<TechnicianAgendaScreen> createState() =>
      _TechnicianAgendaScreenState();
}

class _TechnicianAgendaScreenState extends ConsumerState<TechnicianAgendaScreen> {
  late final List<DateTime> _days = List.generate(
      7, (i) => _dateOnly(DateTime.now()).add(Duration(days: i)));
  late DateTime _day = _days.first;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = ref.watch(regionProfileProvider).locale;
    final async = ref.watch(agendaProvider(_day));

    return Scaffold(
      appBar: AppBar(title: Text(l.agendaTitle, style: AppText.h1)),
      body: Column(
        children: [
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              itemCount: _days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = _days[i];
                final sel = d == _day;
                return GestureDetector(
                  onTap: () => setState(() => _day = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 52,
                    decoration: BoxDecoration(
                      color: sel ? SrRobotColors.primaryTeal : SrRobotColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: sel ? SrRobotColors.primaryTeal : SrRobotColors.lineBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormatter.weekdayShort(d, locale),
                            style: AppText.small.copyWith(
                                color: sel ? Colors.white : SrRobotColors.textGray)),
                        Text('${d.day}',
                            style: AppText.h3.copyWith(
                                color: sel ? Colors.white : SrRobotColors.textInk)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                  error: e, onRetry: () => ref.invalidate(agendaProvider(_day))),
              data: (list) => RefreshIndicator(
                color: SrRobotColors.primaryTeal,
                onRefresh: () async {
                  ref.invalidate(agendaProvider(_day));
                  await ref.read(agendaProvider(_day).future);
                },
                child: list.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 40),
                        EmptyStateView(title: l.agendaEmpty),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            AppointmentCard(appointment: list[i], day: _day),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
