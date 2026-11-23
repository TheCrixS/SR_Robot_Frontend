import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sr_robot_app/core/config/app_settings.dart';
import 'package:sr_robot_app/core/config/currency_spec.dart';
import 'package:sr_robot_app/core/config/regional_profile.dart';
import 'package:sr_robot_app/core/utils/currency_formatter.dart';
import 'package:sr_robot_app/shared/models/technician_model.dart';

void main() {
  group('Catálogo de países', () {
    test('incluye los 9 países del backend con moneda y prefijo', () {
      final codes = RegionProfile.catalog.map((r) => r.countryCode).toList();
      expect(codes, ['CO', 'MX', 'AR', 'CL', 'PE', 'BR', 'US', 'ES', 'DE']);
      for (final r in RegionProfile.catalog) {
        expect(r.phonePrefix, startsWith('+'));
        expect(r.availablePaymentMethods, isNotEmpty);
        expect(CurrencySpec.catalog.containsKey(r.currencyCode), isTrue,
            reason: r.countryCode);
      }
    });

    test('byCode cae en Colombia si el país no existe', () {
      expect(RegionProfile.byCode('XX').countryCode, 'CO');
    });

    test('el backend manda: moneda, decimales y métodos de pago', () {
      final mx = RegionProfile.mexico.copyWithBackend({
        'code': 'MX',
        'currency': 'MXN',
        'minorUnits': 2,
        'paymentMethods': ['CARD', 'CASH'],
      });
      expect(mx.currencyDecimals, 2);
      expect(mx.availablePaymentMethods, ['CARD', 'CASH']);
      final nuevo = RegionProfile.fromBackend(
          {'code': 'UY', 'name': 'Uruguay', 'currency': 'UYU', 'minorUnits': 2});
      expect(nuevo.countryName, 'Uruguay');
      expect(nuevo.currencyCode, 'UYU');
    });
  });

  group('Montos en la moneda del dato', () {
    test('una orden en COP vista desde México sigue en COP', () {
      expect(CurrencyFormatter.formatIn(90000, 'COP', RegionProfile.mexico),
          r'$90.000 COP');
    });

    test('misma moneda que el país activo: sin código', () {
      expect(CurrencyFormatter.formatIn(90000, 'COP', RegionProfile.colombia),
          r'$90.000');
      expect(CurrencyFormatter.formatIn(90000, null, RegionProfile.colombia),
          r'$90.000');
    });

    test('formato de cada moneda', () {
      String f(int v, String c) =>
          CurrencyFormatter.formatSpec(v, CurrencySpec.of(c));
      expect(f(180000, 'MXN'), r'$1,800.00');
      expect(f(90000, 'CLP'), r'$90.000');
      expect(f(35000, 'PEN'), 'S/ 350.00');
      expect(f(45000, 'BRL'), r'R$ 450,00');
      expect(f(15000, 'USD'), r'$150.00');
      expect(f(12000, 'EUR'), '120,00 €');
      expect(f(12000000, 'ARS'), r'$120.000,00');
    });
  });

  group('Entrada de montos sin double', () {
    test('MXN: unidades mayores → centavos y vuelta', () {
      final mxn = CurrencySpec.of('MXN');
      expect(mxn.toMinor('18.5'), 1850);
      expect(mxn.toMinor('18,50'), 1850);
      expect(mxn.toMinor('1800'), 180000);
      expect(mxn.toInput(1850), '18.50');
    });

    test('COP: entero, acepta separador de miles', () {
      final cop = CurrencySpec.of('COP');
      expect(cop.toMinor('180000'), 180000);
      expect(cop.toMinor('180.000'), 180000);
      expect(cop.toInput(180000), '180000');
      expect(cop.toMinor('abc'), isNull);
    });
  });

  group('Idiomas por país', () {
    test('cada país del catálogo tiene su idioma traducido', () {
      final esperado = {
        'CO': 'es', 'MX': 'es', 'AR': 'es', 'CL': 'es', 'PE': 'es',
        'ES': 'es', 'US': 'en', 'BR': 'pt', 'DE': 'de',
      };
      for (final r in RegionProfile.catalog) {
        expect(AppSettingsNotifier.languageFor(r.locale), esperado[r.countryCode],
            reason: r.countryCode);
      }
      expect(AppSettingsNotifier.languageFor('fr-FR'), 'es');
    });

    test('los 4 archivos .arb tienen las mismas claves y variables', () {
      Map<String, dynamic> load(String l) => jsonDecode(
          File('lib/l10n/app_$l.arb').readAsStringSync()) as Map<String, dynamic>;
      Set<String> keys(Map<String, dynamic> m) =>
          m.keys.where((k) => !k.startsWith('@')).toSet();
      final vars = RegExp(r'\{(\w+)[,}]');
      final es = load('es');
      for (final l in ['en', 'pt', 'de']) {
        final other = load(l);
        expect(keys(other), keys(es), reason: l);
        for (final k in keys(es)) {
          expect(
              vars.allMatches(other[k] as String).map((m) => m[1]).toSet(),
              vars.allMatches(es[k] as String).map((m) => m[1]).toSet(),
              reason: '$l.$k');
        }
      }
    });

    test('nombres de país en el idioma de la interfaz', () {
      expect(RegionProfile.byCode('DE').localizedName('de'), 'Deutschland');
      expect(RegionProfile.byCode('US').localizedName('en'), 'United States');
      expect(RegionProfile.byCode('BR').localizedName('pt'), 'Brasil');
    });
  });

  group('Datos del backend real', () {
    test('un técnico sin currency usa la moneda del país por defecto (CO)', () {
      final t = TechnicianModel.fromJson({
        'id': 1, 'businessName': 'Carlos Fix Tech',
        'location': {'city': 'Bogotá'},
        'services': [{'id': 1, 'name': 'Pantalla', 'priceFrom': 180000}],
      });
      expect(t.currency, 'COP');
      expect(
          CurrencyFormatter.formatIn(180000, t.currency, RegionProfile.mexico),
          r'$180.000 COP');
    });

    test('métodos de pago iguales a GET /config/countries', () {
      expect(RegionProfile.byCode('MX').availablePaymentMethods,
          ['MERCADO_PAGO', 'SPEI', 'OXXO', 'CODI', 'CARD', 'CASH']);
      expect(RegionProfile.byCode('DE').availablePaymentMethods,
          ['PAYPAL', 'SEPA_DIRECT_DEBIT', 'KLARNA']);
    });
  });
}
