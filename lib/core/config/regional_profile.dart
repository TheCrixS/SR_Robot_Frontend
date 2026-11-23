import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import 'app_settings.dart';
import 'currency_spec.dart';

/// Perfil regional desacoplado: toda diferencia por país vive aquí, como datos,
/// nunca en condicionales del tipo `if (country == 'CO')`.
///
/// Los valores de [catalog] son el respaldo sin red; el backend
/// (`GET /config/countries`) es la fuente de verdad y los reemplaza.
class RegionProfile {
  final String countryCode;
  final String countryName;
  final String locale;
  final CurrencySpec currency;
  final String phonePrefix;
  final List<String> availablePaymentMethods;

  const RegionProfile({
    required this.countryCode,
    required this.countryName,
    required this.locale,
    required this.currency,
    required this.phonePrefix,
    required this.availablePaymentMethods,
  });

  /// Nombre del país en el idioma de la interfaz (dato, no texto de pantalla).
  static const Map<String, Map<String, String>> _names = {
    'CO': {'es': 'Colombia', 'en': 'Colombia', 'pt': 'Colômbia', 'de': 'Kolumbien'},
    'MX': {'es': 'México', 'en': 'Mexico', 'pt': 'México', 'de': 'Mexiko'},
    'AR': {'es': 'Argentina', 'en': 'Argentina', 'pt': 'Argentina', 'de': 'Argentinien'},
    'CL': {'es': 'Chile', 'en': 'Chile', 'pt': 'Chile', 'de': 'Chile'},
    'PE': {'es': 'Perú', 'en': 'Peru', 'pt': 'Peru', 'de': 'Peru'},
    'BR': {'es': 'Brasil', 'en': 'Brazil', 'pt': 'Brasil', 'de': 'Brasilien'},
    'US': {'es': 'Estados Unidos', 'en': 'United States', 'pt': 'Estados Unidos', 'de': 'Vereinigte Staaten'},
    'ES': {'es': 'España', 'en': 'Spain', 'pt': 'Espanha', 'de': 'Spanien'},
    'DE': {'es': 'Alemania', 'en': 'Germany', 'pt': 'Alemanha', 'de': 'Deutschland'},
  };

  String localizedName(String languageCode) =>
      _names[countryCode]?[languageCode] ?? countryName;

  String get currencyCode => currency.code;
  String get currencySymbol => currency.symbol.trim();
  int get currencyDecimals => currency.decimals;
  String get thousandSeparator => currency.thousandSeparator;
  String get decimalSeparator => currency.decimalSeparator;
  bool get symbolBeforeAmount => currency.symbolBeforeAmount;

  static RegionProfile _c(String code, String name, String locale,
          String currency, String prefix, List<String> methods) =>
      RegionProfile(
        countryCode: code,
        countryName: name,
        locale: locale,
        currency: CurrencySpec.of(currency),
        phonePrefix: prefix,
        availablePaymentMethods: methods,
      );

  static final colombia = _c('CO', 'Colombia', 'es_CO', 'COP', '+57',
      const ['NEQUI', 'DAVIPLATA', 'CARD', 'CASH']);
  static final mexico = _c('MX', 'México', 'es_MX', 'MXN', '+52',
      const ['MERCADO_PAGO', 'SPEI', 'OXXO', 'CODI', 'CARD', 'CASH']);

  /// Países que carga el backend (API.md §16). Respaldo sin conexión.
  static final List<RegionProfile> catalog = [
    colombia,
    mexico,
    _c('AR', 'Argentina', 'es_AR', 'ARS', '+54', const ['MERCADO_PAGO', 'TRANSFERENCIA_3', 'CARD', 'CASH']),
    _c('CL', 'Chile', 'es_CL', 'CLP', '+56', const ['WEBPAY', 'TRANSFERENCIA', 'CARD', 'CASH']),
    _c('PE', 'Perú', 'es_PE', 'PEN', '+51', const ['YAPE', 'PLIN', 'PAGOEFECTIVO', 'CARD', 'CASH']),
    _c('BR', 'Brasil', 'pt_BR', 'BRL', '+55', const ['PIX', 'CARD']),
    _c('US', 'Estados Unidos', 'en_US', 'USD', '+1', const ['APPLE_PAY', 'CARD', 'STRIPE', 'VENMO']),
    _c('ES', 'España', 'es_ES', 'EUR', '+34', const ['BIZUM', 'CARD', 'STRIPE']),
    _c('DE', 'Alemania', 'de_DE', 'EUR', '+49', const ['PAYPAL', 'SEPA_DIRECT_DEBIT', 'KLARNA']),
  ];

  /// País por defecto del backend (API.md: `country` por defecto `CO`).
  static const backendDefaultCountry = 'CO';

  /// Moneda de un monto que no trae `currency`: la del país indicado o, si
  /// tampoco llega, la del país por defecto del backend.
  static String currencyForCountry(String? countryCode) =>
      byCode(countryCode ?? backendDefaultCountry).currencyCode;

  /// Compatibilidad: la lista completa del catálogo.
  static List<RegionProfile> get all => catalog;

  static RegionProfile byCode(String code, [List<RegionProfile>? from]) {
    final list = from ?? catalog;
    for (final r in list) {
      if (r.countryCode == code) return r;
    }
    for (final r in catalog) {
      if (r.countryCode == code) return r;
    }
    return list.isNotEmpty ? list.first : colombia;
  }

  /// Mismo país con otro idioma de presentación (fechas y textos).
  RegionProfile withLanguage(String languageCode) {
    if (locale.startsWith(languageCode)) return this;
    return RegionProfile(
      countryCode: countryCode,
      countryName: countryName,
      locale: '${languageCode}_$countryCode',
      currency: currency,
      phonePrefix: phonePrefix,
      availablePaymentMethods: availablePaymentMethods,
    );
  }

  /// Mezcla los datos de `GET /config/countries` (code, name, locale,
  /// currency, minorUnits, paymentMethods). Lo que no llega se conserva.
  RegionProfile copyWithBackend(Map<String, dynamic> json) {
    final methods = (json['paymentMethods'] as List?)
        ?.map((e) => e.toString())
        .toList();
    final code = json['currency'] as String?;
    var spec = code == null ? currency : CurrencySpec.of(code);
    final minor = json['minorUnits'];
    if (minor is int) spec = spec.copyWith(decimals: minor);
    final phone = json['phonePrefix'] as String? ?? json['phoneCode'] as String?;
    return RegionProfile(
      countryCode: json['code'] as String? ?? countryCode,
      countryName: json['name'] as String? ?? countryName,
      locale: (json['locale'] as String?)?.replaceAll('-', '_') ?? locale,
      currency: spec,
      phonePrefix: phone ?? phonePrefix,
      availablePaymentMethods:
          (methods == null || methods.isEmpty) ? availablePaymentMethods : methods,
    );
  }

  /// Construye un perfil desde el backend aunque el país no esté en el catálogo.
  static RegionProfile fromBackend(Map<String, dynamic> json) {
    final code = json['code'] as String? ?? '';
    RegionProfile? known;
    for (final r in catalog) {
      if (r.countryCode == code) known = r;
    }
    final base = known ??
        RegionProfile(
          countryCode: code,
          countryName: code,
          locale: 'es_$code',
          currency: CurrencySpec.of(json['currency'] as String? ?? 'USD'),
          phonePrefix: '+',
          availablePaymentMethods: const ['CARD'],
        );
    return base.copyWithBackend(json);
  }
}

/// Países activos según el backend; si no hay red se usa el catálogo local.
final countriesProvider = FutureProvider<List<RegionProfile>>((ref) async {
  try {
    final body =
        await ref.watch(apiClientProvider).get(ApiEndpoints.countries);
    final data = body['data'];
    final list = data is List
        ? data
            .whereType<Map>()
            .map((m) => RegionProfile.fromBackend(Map<String, dynamic>.from(m)))
            .where((r) => r.countryCode.isNotEmpty)
            .toList()
        : <RegionProfile>[];
    return list.isEmpty ? RegionProfile.catalog : list;
  } catch (_) {
    return RegionProfile.catalog;
  }
});

/// Lista de países disponible ya (backend si cargó, catálogo si no).
final availableCountriesProvider = Provider<List<RegionProfile>>((ref) =>
    ref.watch(countriesProvider).valueOrNull ?? RegionProfile.catalog);

/// Perfil regional activo, derivado de los ajustes (país + idioma).
final regionProfileProvider = Provider<RegionProfile>((ref) {
  final s = ref.watch(appSettingsProvider);
  final countries = ref.watch(availableCountriesProvider);
  return RegionProfile.byCode(s.countryCode, countries)
      .withLanguage(s.languageCode);
});
