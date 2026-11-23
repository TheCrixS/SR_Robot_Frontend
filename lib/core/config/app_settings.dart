import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'env_config.dart';

/// Preferencias locales: idioma de la interfaz y país (define moneda,
/// prefijo telefónico y métodos de pago vía RegionProfile).
class AppSettings {
  final String languageCode;
  final String countryCode;
  final bool demoMode;
  const AppSettings(
      {this.languageCode = 'es', this.countryCode = 'CO', this.demoMode = false});

  AppSettings copyWith({String? languageCode, String? countryCode, bool? demoMode}) =>
      AppSettings(
        languageCode: languageCode ?? this.languageCode,
        countryCode: countryCode ?? this.countryCode,
        demoMode: demoMode ?? this.demoMode,
      );
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(AppSettings(demoMode: EnvConfig.mockMode)) {
    _load();
  }

  static const _kLang = 'sr_lang';
  static const _kCountry = 'sr_country';
  static const kDemo = 'sr_demo';
  static const supportedLanguages = ['es', 'en', 'pt', 'de'];

  /// Idioma de interfaz que corresponde a un locale (`pt_BR` → `pt`).
  /// Si no está traducido se usa español.
  static String languageFor(String locale) {
    final lang = locale.split(RegExp('[_-]')).first.toLowerCase();
    return supportedLanguages.contains(lang) ? lang : 'es';
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      state = AppSettings(
        languageCode: _supported(p.getString(_kLang)),
        countryCode: p.getString(_kCountry) ?? 'CO',
        demoMode: EnvConfig.mockMode,
      );
    } catch (_) {/* sin preferencias guardadas */}
  }

  static String _supported(String? code) =>
      supportedLanguages.contains(code) ? code! : 'es';

  Future<void> setLanguage(String code) async {
    state = state.copyWith(languageCode: code);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, code);
  }

  /// Activa o desactiva el backend simulado (se guarda para el próximo inicio).
  Future<void> setDemoMode(bool on) async {
    EnvConfig.mockMode = on;
    state = state.copyWith(demoMode: on);
    final p = await SharedPreferences.getInstance();
    await p.setBool(kDemo, on);
  }

  /// Cambia el país y, si se indica, el idioma que le corresponde.
  Future<void> setCountry(String code, {String? language}) async {
    state = state.copyWith(countryCode: code, languageCode: language);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCountry, code);
    if (language != null) await p.setString(_kLang, language);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
        (ref) => AppSettingsNotifier());
