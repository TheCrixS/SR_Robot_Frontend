import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_settings.dart';
import '../../core/config/regional_profile.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';

/// País elegido en el login antes de iniciar sesión. Al entrar, se guarda en
/// la cuenta (PUT /auth/me) si es distinto del que ya tenía.
final loginCountryChoiceProvider = StateProvider<String?>((ref) => null);

/// Bandera a partir del código ISO (dato visual, no texto de interfaz).
String flagEmoji(String countryCode) {
  if (countryCode.length != 2) return '🌐';
  final c = countryCode.toUpperCase().codeUnits;
  return String.fromCharCodes([0x1F1E6 + c[0] - 65, 0x1F1E6 + c[1] - 65]);
}

/// Hoja inferior con los países activos. Devuelve el elegido y ya aplica
/// país + idioma del país en los ajustes.
Future<RegionProfile?> pickCountry(BuildContext context, WidgetRef ref) async {
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(l.profileCountry, style: AppText.h3),
            ),
            for (final r in countries)
              ListTile(
                leading: Text(flagEmoji(r.countryCode),
                    style: const TextStyle(fontSize: 24)),
                title: Text(r.localizedName(l.localeName), style: AppText.body),
                subtitle: Text('${r.currencyCode} · ${r.phonePrefix}',
                    style: AppText.small),
                trailing: current == r.countryCode
                    ? const Icon(Icons.check_rounded,
                        color: SrRobotColors.primaryTeal)
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
  if (code == null) return null;
  // El idioma sigue al país elegido (Brasil → portugués, Alemania → alemán…).
  final region = RegionProfile.byCode(code, countries);
  await ref.read(appSettingsProvider.notifier).setCountry(code,
      language: AppSettingsNotifier.languageFor(region.locale));
  return region;
}

/// Botón del login con el país activo: bandera, nombre y moneda.
class CountryPill extends ConsumerWidget {
  const CountryPill({super.key, required this.onPicked});
  final ValueChanged<RegionProfile> onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final region = ref.watch(regionProfileProvider);
    final lang = ref.watch(appSettingsProvider).languageCode;
    return Material(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final r = await pickCountry(context, ref);
          if (r != null) onPicked(r);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flagEmoji(region.countryCode),
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '${region.localizedName(lang)} · ${region.currencyCode}',
                style: AppText.bodyMedium
                    .copyWith(color: Colors.white, fontSize: 13),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
