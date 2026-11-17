import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/business_repository.dart';
import '../../../shared/data/config_repository.dart';
import '../../../shared/models/technician_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/sr_card.dart';

/// Edición del perfil público del negocio.
class BusinessEditScreen extends ConsumerWidget {
  const BusinessEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myBusinessProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.bizPublicProfile)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(myBusinessProvider)),
        data: (b) => _Form(business: b),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.business});
  final TechnicianModel business;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final _name = TextEditingController(text: widget.business.businessName);
  late final _desc = TextEditingController(text: widget.business.description);
  late final _city = TextEditingController(text: widget.business.city ?? '');
  late final _address = TextEditingController(text: widget.business.address ?? '');
  late final _response =
      TextEditingController(text: widget.business.responseTime ?? '');
  late final _fee =
      TextEditingController(text: '${widget.business.homeExtraFee}');
  late final _radius =
      TextEditingController(text: '${widget.business.coverageRadiusKm}');
  late final Set<String> _cats = {...widget.business.categories};
  late bool _home = widget.business.homeService;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _desc, _city, _address, _response, _fee, _radius]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (_name.text.trim().isEmpty || _cats.isEmpty) {
      setState(() => _error = l.onboardRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(businessRepositoryProvider).update({
        'businessName': _name.text.trim(),
        'description': _desc.text.trim(),
        'categories': _cats.toList(),
        'city': _city.text.trim(),
        'address': _address.text.trim(),
        'responseTime': _response.text.trim(),
        'homeService': _home,
        'homeExtraFee': int.tryParse(_fee.text) ?? 0,
        'coverageRadiusKm': int.tryParse(_radius.text) ?? 0,
      });
      ref.invalidate(myBusinessProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.bizSaved)));
      context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const <String>[];
    final symbol = ref.watch(regionProfileProvider).currencySymbol;
    InputDecoration deco(String t) => InputDecoration(labelText: t);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        TextField(controller: _name, style: AppText.body, decoration: deco(l.onboardBusinessName)),
        const SizedBox(height: 10),
        TextField(
            controller: _desc,
            minLines: 2,
            maxLines: 4,
            style: AppText.body,
            decoration: deco(l.onboardDescription)),
        const SizedBox(height: 18),
        Text(l.onboardCategories, style: AppText.h3),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in {...cats, ..._cats})
              SrFilterChip(
                label: '${emojiFor(c)} $c',
                selected: _cats.contains(c),
                onTap: () => setState(
                    () => _cats.contains(c) ? _cats.remove(c) : _cats.add(c)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(controller: _city, style: AppText.body, decoration: deco(l.onboardCity)),
        const SizedBox(height: 10),
        TextField(controller: _address, style: AppText.body, decoration: deco(l.onboardAddress)),
        const SizedBox(height: 10),
        TextField(
            controller: _response,
            style: AppText.body,
            decoration: deco(l.bizResponseTime)),
        const SizedBox(height: 14),
        SrCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _home,
            onChanged: (v) => setState(() => _home = v),
            title: Text(l.onboardHome, style: AppText.bodyMedium),
          ),
        ),
        if (_home) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fee,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppText.body,
                  decoration: InputDecoration(
                      labelText: l.onboardHomeFee, prefixText: '$symbol '),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _radius,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppText.body,
                  decoration: deco(l.onboardCoverage),
                ),
              ),
            ],
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
        ],
        const SizedBox(height: 20),
        SrButton(label: l.commonSave, loading: _busy, onPressed: _save),
      ],
    );
  }
}
