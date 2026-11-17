import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/config_repository.dart';
import '../../../shared/data/location_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/robot_avatar.dart';
import '../../../shared/widgets/sr_card.dart';
import '../../auth/domain/session_controller.dart';

/// Primer cambio a Modo Técnico: datos mínimos del negocio.
/// Al terminar, la sesión cambia de rol y el router lleva al panel.
class TechnicianOnboardingScreen extends ConsumerStatefulWidget {
  const TechnicianOnboardingScreen({super.key});

  @override
  ConsumerState<TechnicianOnboardingScreen> createState() =>
      _TechnicianOnboardingScreenState();
}

class _TechnicianOnboardingScreenState
    extends ConsumerState<TechnicianOnboardingScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _fee = TextEditingController(text: '15000');
  final _radius = TextEditingController(text: '10');
  final Set<String> _cats = {};
  bool _home = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _desc, _city, _address, _fee, _radius]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
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
      final loc = await ref.read(locationProvider.future);
      await ref.read(sessionProvider.notifier).switchMode(
        UserRole.technician,
        businessData: {
          'businessName': _name.text.trim(),
          'description': _desc.text.trim(),
          'categories': _cats.toList(),
          'city': _city.text.trim(),
          'address': _address.text.trim(),
          'homeService': _home,
          'homeExtraFee': int.tryParse(_fee.text) ?? 0,
          'coverageRadiusKm': int.tryParse(_radius.text) ?? 10,
          if (loc != null) 'lat': loc.lat,
          if (loc != null) 'lng': loc.lng,
        },
      );
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

    InputDecoration deco(String label) => InputDecoration(labelText: label);

    return Scaffold(
      appBar: AppBar(title: Text(l.onboardTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Row(
            children: [
              const RobotAvatar(size: 72),
              const SizedBox(width: 12),
              Expanded(child: Text(l.onboardBody, style: AppText.bodyGray)),
            ],
          ),
          const SizedBox(height: 20),
          TextField(controller: _name, style: AppText.body, decoration: deco(l.onboardBusinessName)),
          const SizedBox(height: 10),
          TextField(
              controller: _desc,
              minLines: 2,
              maxLines: 3,
              style: AppText.body,
              decoration: deco(l.onboardDescription)),
          const SizedBox(height: 18),
          Text(l.onboardCategories, style: AppText.h3),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in cats)
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
            Text(_error!,
                style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
          ],
          const SizedBox(height: 20),
          SrButton(label: l.onboardSubmit, loading: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}
