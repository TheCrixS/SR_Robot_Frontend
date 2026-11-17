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
  static const supportedLanguages = ['es', 'en'];

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      state = AppSettings(
        languageCode: p.getString(_kLang) ?? 'es',
        countryCode: p.getString(_kCountry) ?? 'CO',
        demoMode: EnvConfig.mockMode,
      );
    } catch (_) {/* sin preferencias guardadas */}
  }

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

  Future<void> setCountry(String code) async {
    state = state.copyWith(countryCode: code);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCountry, code);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
        (ref) => AppSettingsNotifier());
