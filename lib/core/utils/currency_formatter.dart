import '../config/regional_profile.dart';

/// Formatea montos enteros (unidad mínima de la moneda) según el RegionProfile.
/// Nunca usa punto flotante para el cálculo.
class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(
    int amount,
    RegionProfile region, {
    String? freeLabel,
  }) {
    if (amount == 0 && freeLabel != null) return freeLabel;

    final negative = amount < 0;
    final abs = amount.abs();
    final divisor = _pow10(region.currencyDecimals);
    final whole = abs ~/ divisor;
    final fraction = abs % divisor;

    final wholeStr = _groupThousands(whole.toString(), region.thousandSeparator);
    var number = wholeStr;
    if (region.currencyDecimals > 0) {
      number +=
          '${region.decimalSeparator}${fraction.toString().padLeft(region.currencyDecimals, '0')}';
    }

    final withSymbol = region.symbolBeforeAmount
        ? '${region.currencySymbol}$number'
        : '$number ${region.currencySymbol}';
    return negative ? '-$withSymbol' : withSymbol;
  }

  static int _pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  static String _groupThousands(String digits, String sep) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buf.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(sep);
    }
    return buf.toString();
  }
}
