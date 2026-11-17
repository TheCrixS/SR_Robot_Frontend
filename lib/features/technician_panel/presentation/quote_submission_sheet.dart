import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/technician_work_repository.dart';
import '../../../shared/models/quote_model.dart';
import '../../../shared/widgets/custom_button.dart';

/// Modal para que el técnico envíe precio, tiempo, garantía y mensaje.
Future<bool?> showQuoteSubmissionSheet(
        BuildContext context, QuoteRequestModel request) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => QuoteSubmissionSheet(request: request),
    );

class QuoteSubmissionSheet extends ConsumerStatefulWidget {
  const QuoteSubmissionSheet({super.key, required this.request});
  final QuoteRequestModel request;

  @override
  ConsumerState<QuoteSubmissionSheet> createState() =>
      _QuoteSubmissionSheetState();
}

class _QuoteSubmissionSheetState extends ConsumerState<QuoteSubmissionSheet> {
  final _price = TextEditingController();
  final _time = TextEditingController();
  final _warranty = TextEditingController(text: '90');
  final _message = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _price.dispose();
    _time.dispose();
    _warranty.dispose();
    _message.dispose();
    super.dispose();
  }

  /// "2 horas" → 2; "1 día" → 24 (aproximación para estimatedHours).
  int? _hoursFrom(String text) {
    final n = int.tryParse(RegExp(r'\d+').firstMatch(text)?.group(0) ?? '');
    if (n == null) return null;
    return text.toLowerCase().contains('d') && !text.toLowerCase().contains('h')
        ? n * 24
        : n;
  }

  Future<void> _send() async {
    final l = context.l10n;
    final price = int.tryParse(_price.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (price <= 0 || _time.text.trim().isEmpty) {
      setState(() => _error = l.qsInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(technicianWorkRepositoryProvider).sendQuote(
            widget.request.id,
            price: price,
            estimatedTime: _time.text.trim(),
            estimatedHours: _hoursFrom(_time.text),
            warrantyDays: int.tryParse(_warranty.text) ?? 90,
            message: _message.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = errorText(context, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final region = ref.watch(regionProfileProvider);
    final r = widget.request;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.qsTitle, style: AppText.h2),
              const SizedBox(height: 4),
              Text('${r.deviceType} · ${r.brandModel}', style: AppText.meta),
              const SizedBox(height: 16),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppText.h3,
                decoration: InputDecoration(
                  labelText: l.qsPrice,
                  prefixText: '${region.currencySymbol} ',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _time,
                      style: AppText.body,
                      decoration: InputDecoration(
                          labelText: l.qsTime, hintText: l.qsTimeHint),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _warranty,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppText.body,
                      decoration: InputDecoration(labelText: l.qsWarranty),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _message,
                minLines: 2,
                maxLines: 4,
                style: AppText.body,
                decoration: InputDecoration(labelText: l.qsMessage),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
              ],
              const SizedBox(height: 16),
              SrButton(label: l.qsSend, loading: _busy, onPressed: _send),
            ],
          ),
        ),
      ),
    );
  }
}
