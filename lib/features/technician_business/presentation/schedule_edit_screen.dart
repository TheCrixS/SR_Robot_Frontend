import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/business_repository.dart';
import '../../../shared/models/technician_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/sr_card.dart';

const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

class ScheduleEditScreen extends ConsumerWidget {
  const ScheduleEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myScheduleProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.bizScheduleTitle)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(myScheduleProvider)),
        data: (s) => _Editor(initial: s),
      ),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.initial});
  final Map<String, DaySchedule> initial;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final Map<String, DaySchedule> _s = {
    for (final k in _dayKeys)
      k: widget.initial[k] ?? const DaySchedule(false, '08:00', '18:00'),
  };
  bool _busy = false;

  Future<void> _pickTime(String day, bool open) async {
    final cur = open ? _s[day]!.open : _s[day]!.close;
    final parts = cur.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: int.tryParse(parts.first) ?? 8,
          minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0),
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final t =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final d = _s[day]!;
    setState(() => _s[day] =
        open ? DaySchedule(d.enabled, t, d.close) : DaySchedule(d.enabled, d.open, t));
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await ref.read(businessRepositoryProvider).saveSchedule(_s);
      ref.invalidate(myScheduleProvider);
      ref.invalidate(myBusinessProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.bizSaved)));
      context.pop();
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
    final names = {
      'mon': l.dayMon,
      'tue': l.dayTue,
      'wed': l.dayWed,
      'thu': l.dayThu,
      'fri': l.dayFri,
      'sat': l.daySat,
      'sun': l.daySun,
    };

    Widget timeChip(String day, bool open) {
      final d = _s[day]!;
      return GestureDetector(
        onTap: d.enabled ? () => _pickTime(day, open) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: d.enabled ? SrRobotColors.softTeal : SrRobotColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(open ? d.open : d.close,
              style: AppText.meta.copyWith(
                  color: d.enabled ? SrRobotColors.textInk : SrRobotColors.textGray,
                  fontWeight: FontWeight.w600)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        for (final k in _dayKeys) ...[
          SrCard(
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
            child: Row(
              children: [
                SizedBox(width: 46, child: Text(names[k]!, style: AppText.bodyMedium)),
                Switch(
                  value: _s[k]!.enabled,
                  onChanged: (v) => setState(
                      () => _s[k] = DaySchedule(v, _s[k]!.open, _s[k]!.close)),
                ),
                const Spacer(),
                if (_s[k]!.enabled) ...[
                  timeChip(k, true),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('–'),
                  ),
                  timeChip(k, false),
                ] else
                  Text(l.techClosed, style: AppText.meta),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        SrButton(label: l.commonSave, loading: _busy, onPressed: _save),
      ],
    );
  }
}
