import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_settings.dart';
import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/client_repository.dart';
import '../../../shared/data/orders_repository.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/widgets/menu_tile.dart';
import '../../../shared/widgets/sr_card.dart';
import 'mode_switch_card.dart';
import '../../auth/domain/session_controller.dart';
import '../../../shared/data/quotes_repository.dart';
import '../../../l10n/app_localizations.dart';

/// Perfil del cliente: estadísticas, cuenta, preferencias y cambio de modo.
class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final history = ref.watch(ordersListProvider('history')).valueOrNull ?? const [];
    final active = ref.watch(ordersListProvider('active')).valueOrNull ?? const [];
    final warranties = ref.watch(activeWarrantiesProvider).valueOrNull;
    final settings = ref.watch(appSettingsProvider);
    final region = ref.watch(regionProfileProvider);

    final delivered =
        history.where((o) => o.state == OrderState.entregado).toList();
    // Total invertido por moneda: no se suman pesos colombianos con mexicanos.
    final spentBy = <String?, int>{};
    for (final o in delivered) {
      spentBy[o.currency] = (spentBy[o.currency] ?? 0) + o.amount;
    }
    final spentText = spentBy.isEmpty
        ? ref.money(0)
        : spentBy.entries
            .map((e) => ref.money(e.value, currency: e.key))
            .join(' + ');

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: SrRobotColors.primaryTeal,
          onRefresh: () async {
            ref.invalidate(ordersListProvider('history'));
            ref.invalidate(ordersListProvider('active'));
            ref.invalidate(activeWarrantiesProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(l.navProfile, style: AppText.h1),
              const SizedBox(height: 16),
              const AccountModeSection(showActions: false),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                        value: '${delivered.length + active.length}',
                        label: l.profileStatsServices),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Stat(
                        value: warranties == null ? '—' : '$warranties',
                        label: l.profileStatsWarranties),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _Stat(value: spentText, label: l.profileStatsSpent)),
                ],
              ),
              const SizedBox(height: 20),
              MenuTile(
                icon: Icons.devices_other_outlined,
                title: l.profileMyDevices,
                onTap: () => context.push(Routes.myDevices),
              ),
              MenuTile(
                icon: Icons.location_on_outlined,
                title: l.profileAddresses,
                onTap: () => context.push(Routes.addresses),
              ),
              MenuTile(
                icon: Icons.credit_card_rounded,
                title: l.profilePaymentMethods,
                onTap: () => context.push(Routes.paymentMethods),
              ),
              MenuTile(
                icon: Icons.favorite_border_rounded,
                title: l.profileFavorites,
                onTap: () => context.push(Routes.favorites),
              ),
              MenuTile(
                icon: Icons.support_agent_outlined,
                title: l.profileSupport,
                onTap: () => context.push(Routes.support),
              ),
              const SizedBox(height: 10),
              Text(l.profileSettings, style: AppText.h3),
              const SizedBox(height: 10),
              MenuTile(
                icon: Icons.translate_rounded,
                title: l.profileLanguage,
                trailing: _languageName(l, settings.languageCode),
                onTap: () => _pickLanguage(context, ref),
              ),
              MenuTile(
                icon: Icons.public_rounded,
                title: l.profileCountry,
                trailing:
                    '${region.localizedName(settings.languageCode)} · ${region.currencyCode}',
                onTap: () => _pickCountry(context, ref),
              ),
              const SizedBox(height: 10),
              const AccountModeSection(showCard: false),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final current = ref.read(appSettingsProvider).languageCode;
    final code = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final k in AppSettingsNotifier.supportedLanguages)
              ListTile(
                title: Text(_languageName(l, k), style: AppText.body),
                trailing: current == k
                    ? const Icon(Icons.check_rounded, color: SrRobotColors.primaryTeal)
                    : null,
                onTap: () => Navigator.pop(c, k),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (code == null) return;
    await ref.read(appSettingsProvider.notifier).setLanguage(code);
    await _syncAccount(ref);
  }

  Future<void> _pickCountry(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final current = ref.read(appSettingsProvider).countryCode;
    final countries = ref.read(availableCountriesProvider);
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
         child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in countries)
              ListTile(
                title: Text(r.localizedName(l.localeName), style: AppText.body),
                subtitle: Text('${r.currencyCode} · ${r.phonePrefix}', style: AppText.small),
                trailing: current == r.countryCode
                    ? const Icon(Icons.check_rounded, color: SrRobotColors.primaryTeal)
                    : null,
                onTap: () => Navigator.pop(c, r.countryCode),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(l.profileCountryNote, style: AppText.small),
            ),
          ],
         ),
        ),
      ),
    );
    if (code == null) return;
    // El idioma sigue al país elegido (Brasil → portugués, Alemania → alemán…).
    final region = RegionProfile.byCode(code, countries);
    await ref.read(appSettingsProvider.notifier).setCountry(code,
        language: AppSettingsNotifier.languageFor(region.locale));
    await _syncAccount(ref);
  }

  /// Guarda idioma/país en la cuenta: el backend decide métodos de pago y
  /// moneda según el país del usuario. Si no hay red queda solo local.
  Future<void> _syncAccount(WidgetRef ref) async {
    final s = ref.read(appSettingsProvider);
    try {
      await ref.read(sessionProvider.notifier).updateAccount({
        'country': s.countryCode,
        'locale': '${s.languageCode}-${s.countryCode}',
      });
    } catch (_) {/* sin red: se mantiene el ajuste local */}
    ref.invalidate(paymentMethodsProvider);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: AppText.h3.copyWith(color: SrRobotColors.darkTeal)),
          ),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppText.small),
        ],
      ),
    );
  }
}

/// Nombre de cada idioma escrito en ese idioma.
String _languageName(AppLocalizations l, String code) => switch (code) {
      'en' => l.languageEn,
      'pt' => l.languagePt,
      'de' => l.languageDe,
      _ => l.languageEs,
    };
