import 'package:flutter_test/flutter_test.dart';
import 'package:sr_robot_app/core/config/regional_profile.dart';
import 'package:sr_robot_app/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('COP sin decimales y separador de miles con punto', () {
      expect(CurrencyFormatter.format(180000, RegionProfile.colombia),
          r'$180.000');
      expect(CurrencyFormatter.format(1500000, RegionProfile.colombia),
          r'$1.500.000');
    });

    test('cero se muestra como Gratis cuando se pide', () {
      expect(
          CurrencyFormatter.format(0, RegionProfile.colombia,
              freeLabel: 'Gratis'),
          'Gratis');
    });

    test('MXN usa centavos', () {
      expect(CurrencyFormatter.format(123456, RegionProfile.mexico),
          r'$1,234.56');
    });
  });
}
