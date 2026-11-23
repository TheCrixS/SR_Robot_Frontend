import '../config/currency_spec.dart';
import '../config/regional_profile.dart';

/// Formatea montos enteros (unidad mínima de la moneda).
/// Nunca usa punto flotante para el cálculo.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Monto en la moneda del perfil regional activo.
  static String format(
    int amount,
    RegionProfile region, {
    String? freeLabel,
  }) =>
      formatSpec(amount, region.currency, freeLabel: freeLabel);

  /// Monto en una moneda concreta (la del dato: orden, técnico, cotización).
  /// Si no es la moneda del país activo se añade el código para no confundir
  /// (p. ej. `$90.000 COP` visto desde México).
  static String formatIn(
    int amount,
    String? currencyCode,
    RegionProfile region, {
    String? freeLabel,
  }) {
    if (currencyCode == null ||
        currencyCode.isEmpty ||
        currencyCode.toUpperCase() == region.currencyCode) {
      return format(amount, region, freeLabel: freeLabel);
    }
    final spec = CurrencySpec.of(currencyCode);
    final text = formatSpec(amount, spec, freeLabel: freeLabel);
    return text == freeLabel || spec.symbol.trim() == spec.code
        ? text
        : '$text ${spec.code}';
  }

  static String formatSpec(
    int amount,
    CurrencySpec spec, {
    String? freeLabel,
  }) {
    if (amount == 0 && freeLabel != null) return freeLabel;

    final negative = amount < 0;
    final abs = amount.abs();
    final divisor = _pow10(spec.decimals);
    final whole = abs ~/ divisor;
    final fraction = abs % divisor;

    var number = _groupThousands(whole.toString(), spec.thousandSeparator);
    if (spec.decimals > 0) {
      number +=
          '${spec.decimalSeparator}${fraction.toString().padLeft(spec.decimals, '0')}';
    }

    final withSymbol = spec.symbolBeforeAmount
        ? '${spec.symbol}$number'
        : '$number ${spec.symbol}';
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
