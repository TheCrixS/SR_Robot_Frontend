import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings.dart';

/// Perfil regional desacoplado: toda diferencia por país vive aquí,
/// nunca en condicionales del tipo `if (country == 'CO')`.
class RegionProfile {
  final String countryCode;
  final String countryName;
  final String locale;
  final String currencyCode;
  final String currencySymbol;
  final int currencyDecimals;
  final String thousandSeparator;
  final String decimalSeparator;
  final bool symbolBeforeAmount;
  final String phonePrefix;
  final List<String> availablePaymentMethods;

  const RegionProfile({
    required this.countryCode,
    required this.countryName,
    required this.locale,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyDecimals,
    required this.thousandSeparator,
    required this.decimalSeparator,
    required this.symbolBeforeAmount,
    required this.phonePrefix,
    required this.availablePaymentMethods,
  });

  static const colombia = RegionProfile(
    countryCode: 'CO',
    countryName: 'Colombia',
    locale: 'es_CO',
    currencyCode: 'COP',
    currencySymbol: r'$',
    currencyDecimals: 0,
    thousandSeparator: '.',
    decimalSeparator: ',',
    symbolBeforeAmount: true,
    phonePrefix: '+57',
    availablePaymentMethods: ['NEQUI', 'DAVIPLATA', 'CARD', 'CASH'],
  );

  static const mexico = RegionProfile(
    countryCode: 'MX',
    countryName: 'México',
    locale: 'es_MX',
    currencyCode: 'MXN',
    currencySymbol: r'$',
    currencyDecimals: 2,
    thousandSeparator: ',',
    decimalSeparator: '.',
    symbolBeforeAmount: true,
    phonePrefix: '+52',
    availablePaymentMethods: ['CARD', 'CASH'],
  );

  static const all = [colombia, mexico];

  static RegionProfile byCode(String code) =>
      all.firstWhere((r) => r.countryCode == code, orElse: () => colombia);

  /// Mismo país con otro idioma de presentación (fechas y textos).
  RegionProfile withLanguage(String languageCode) {
    if (locale.startsWith(languageCode)) return this;
    return RegionProfile(
      countryCode: countryCode,
      countryName: countryName,
      locale: '${languageCode}_$countryCode',
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      currencyDecimals: currencyDecimals,
      thousandSeparator: thousandSeparator,
      decimalSeparator: decimalSeparator,
      symbolBeforeAmount: symbolBeforeAmount,
      phonePrefix: phonePrefix,
      availablePaymentMethods: availablePaymentMethods,
    );
  }

  /// Mezcla los datos que llegan de `GET /config/countries/:code`.
  RegionProfile copyWithBackend(Map<String, dynamic> json) {
    final methods = (json['paymentMethods'] as List?)?.cast<String>();
    return RegionProfile(
      countryCode: json['code'] as String? ?? countryCode,
      countryName: json['name'] as String? ?? countryName,
      locale: (json['locale'] as String?)?.replaceAll('-', '_') ?? locale,
      currencyCode: json['currency'] as String? ?? currencyCode,
      currencySymbol: currencySymbol,
      currencyDecimals: json['minorUnits'] as int? ?? currencyDecimals,
      thousandSeparator: thousandSeparator,
      decimalSeparator: decimalSeparator,
      symbolBeforeAmount: symbolBeforeAmount,
      phonePrefix: phonePrefix,
      availablePaymentMethods: methods ?? availablePaymentMethods,
    );
  }
}

/// Perfil regional activo, derivado de los ajustes (país + idioma).
final regionProfileProvider = Provider<RegionProfile>((ref) {
  final s = ref.watch(appSettingsProvider);
  return RegionProfile.byCode(s.countryCode).withLanguage(s.languageCode);
});
