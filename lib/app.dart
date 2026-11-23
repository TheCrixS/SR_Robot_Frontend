import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_settings.dart';
import 'core/config/regional_profile.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/session_controller.dart';
import 'shared/widgets/country_picker.dart';
import 'l10n/app_localizations.dart';

class SrRobotApp extends ConsumerWidget {
  const SrRobotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final lang = ref.watch(appSettingsProvider).languageCode;

    // El país de la cuenta (servidor) manda: al iniciar sesión o actualizar
    // el perfil, la moneda, el prefijo y los pagos siguen a ese país.
    // El idioma sigue al `locale` de la cuenta (p. ej. pt-BR → portugués).
    ref.listen(
        currentUserProvider.select((u) => u == null ? null : (u.country, u.locale)),
        (_, next) {
      if (next == null || next.$1.isEmpty) return;
      final (country, locale) = next;
      // Si eligió un país en el login, ese manda y se guarda en la cuenta.
      final chosen = ref.read(loginCountryChoiceProvider);
      if (chosen != null) {
        ref.read(loginCountryChoiceProvider.notifier).state = null;
        if (chosen != country) {
          final lang = ref.read(appSettingsProvider).languageCode;
          ref
              .read(sessionProvider.notifier)
              .updateAccount({'country': chosen, 'locale': '$lang-$chosen'})
              .catchError((_) {});
          return;
        }
      }
      final current = ref.read(appSettingsProvider);
      final language = AppSettingsNotifier.languageFor(locale);
      if (current.countryCode != country || current.languageCode != language) {
        ref
            .read(appSettingsProvider.notifier)
            .setCountry(country, language: language);
      }
    });
    // Carga temprana de los países activos del backend.
    ref.watch(countriesProvider);
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
