import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/data/config_repository.dart';
import '../../../shared/data/location_provider.dart';
import '../../../shared/data/quotes_repository.dart';
import '../../../shared/data/technicians_repository.dart';
import '../../../shared/models/quote_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/media_picker.dart';
import '../../../shared/widgets/sr_card.dart';

class RequestQuoteScreen extends ConsumerStatefulWidget {
  const RequestQuoteScreen({super.key, this.technicianId, this.category});
  final String? technicianId;
  final String? category;

  @override
  ConsumerState<RequestQuoteScreen> createState() => _RequestQuoteScreenState();
}

class _RequestQuoteScreenState extends ConsumerState<RequestQuoteScreen> {
  late String? _device = widget.category;
  final _brand = TextEditingController();
  final _issue = TextEditingController();
  final _address = TextEditingController();
  final Set<String> _quickIssues = {};
  List<String> _media = [];
  bool _home = false;
  Urgency _urgency = Urgency.normal;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _brand.dispose();
    _issue.dispose();
    _address.dispose();
    super.dispose();
  }

  List<String> _commonIssues(AppLocalizations l) => [
        l.issueScreen,
        l.issueBattery,
        l.issueNoPower,
        l.issueWater,
        l.issueSlow,
        l.issueSound,
        l.issueCamera,
        l.issueKeyboard,
      ];

  String _composeIssue() {
    final parts = [
      if (_quickIssues.isNotEmpty) _quickIssues.join(', '),
      if (_issue.text.trim().isNotEmpty) _issue.text.trim(),
    ];
    return parts.join('. ');
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final issue = _composeIssue();
    if (_device == null || _brand.text.trim().isEmpty || issue.isEmpty) {
      setState(() => _error = l.quoteRequired);
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
      final loc = await ref.read(locationProvider.future);
      final req = await ref.read(quotesRepositoryProvider).create(
            NewQuoteRequest(
              deviceType: _device!,
              brandModel: _brand.text.trim(),
              issueDescription: issue,
              urgency: _urgency,
              isHomeService: _home,
              address: _home ? _address.text.trim() : null,
              location: loc,
              targetTechnicianId: widget.technicianId,
              filePaths: _media,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.technicianId == null &&
                req.matchedTechnicianIds.isEmpty
            ? l.quoteNoTechnicians
            : l.quoteSent),
      ));
      ref.invalidate(myOpenQuoteRequestsProvider);
      context.pushReplacement(Routes.compareQuotes(req.id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const <String>[];
    final target = widget.technicianId == null
        ? null
        : ref.watch(technicianDetailProvider(widget.technicianId!)).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l.quoteTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          _Label(l.quoteDevice),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in cats)
                SrFilterChip(
                  label: '${emojiFor(c)} ${categoryLabel(context.l10n, c)}',
                  selected: _device == c,
                  onTap: () => setState(() => _device = c),
                ),
            ],
          ),
          _Label(l.quoteBrandModel),
          TextField(
            controller: _brand,
            style: AppText.body,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: l.quoteBrandModelHint),
          ),
          _Label(l.quoteIssue),
          Text(l.quoteCommonIssues, style: AppText.small),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final issue in _commonIssues(l))
                SrFilterChip(
                  label: issue,
                  selected: _quickIssues.contains(issue),
                  onTap: () => setState(() => _quickIssues.contains(issue)
                      ? _quickIssues.remove(issue)
                      : _quickIssues.add(issue)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _issue,
            minLines: 3,
            maxLines: 5,
            style: AppText.body,
            decoration: InputDecoration(hintText: l.quoteIssueHint),
          ),
          _Label(l.quoteMedia),
          Text(l.quoteMediaHint, style: AppText.small),
          const SizedBox(height: 8),
          MediaPickerField(
              paths: _media, onChanged: (v) => setState(() => _media = v)),
          const SizedBox(height: 20),
          SrCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _home,
              onChanged: (v) => setState(() => _home = v),
              title: Text(l.quoteHome, style: AppText.bodyMedium),
            ),
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
          _Label(l.quoteUrgency),
          Row(
            children: [
              for (final u in Urgency.values) ...[
                Expanded(
                  child: _UrgencyOption(
                    label: switch (u) {
                      Urgency.low => l.urgencyLow,
                      Urgency.normal => l.urgencyNormal,
                      Urgency.high => l.urgencyHigh,
                    },
                    color: switch (u) {
                      Urgency.low => SrRobotColors.lime,
                      Urgency.normal => SrRobotColors.infoBlue,
                      Urgency.high => SrRobotColors.alertRed,
                    },
                    selected: _urgency == u,
                    onTap: () => setState(() => _urgency = u),
                  ),
                ),
                if (u != Urgency.high) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SrRobotColors.softTeal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                    widget.technicianId == null
                        ? Icons.campaign_outlined
                        : Icons.person_pin_outlined,
                    color: SrRobotColors.primaryTeal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.technicianId == null
                        ? l.quoteBroadcast
                        : l.quoteDirect(target?.businessName ?? ''),
                    style: AppText.meta.copyWith(color: SrRobotColors.textInk),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
          ],
          const SizedBox(height: 20),
          SrButton(label: l.quoteSubmit, loading: _sending, onPressed: _submit),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(text, style: AppText.h3),
      );
}

class _UrgencyOption extends StatelessWidget {
  const _UrgencyOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : SrRobotColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? color : SrRobotColors.lineBorder, width: 1.5),
        ),
        child: Text(label,
            style: AppText.meta.copyWith(
                color: SrRobotColors.textInk, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
