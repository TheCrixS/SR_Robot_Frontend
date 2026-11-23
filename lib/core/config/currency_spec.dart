/// Formato de una moneda (dato, no lógica): símbolo, decimales y separadores.
///
/// Los montos llegan del backend como enteros en la unidad mínima de su
/// moneda (`minorUnits`). Ninguna pantalla decide por país: todo sale de aquí.
class CurrencySpec {
  final String code;
  final String symbol;
  final int decimals;
  final String thousandSeparator;
  final String decimalSeparator;
  final bool symbolBeforeAmount;

  const CurrencySpec({
    required this.code,
    required this.symbol,
    required this.decimals,
    required this.thousandSeparator,
    required this.decimalSeparator,
    required this.symbolBeforeAmount,
  });

  CurrencySpec copyWith({int? decimals}) => CurrencySpec(
        code: code,
        symbol: symbol,
        decimals: decimals ?? this.decimals,
        thousandSeparator: thousandSeparator,
        decimalSeparator: decimalSeparator,
        symbolBeforeAmount: symbolBeforeAmount,
      );

  /// Catálogo de monedas de los países que atiende el backend.
  static const Map<String, CurrencySpec> catalog = {
    'COP': CurrencySpec(code: 'COP', symbol: r'$', decimals: 0, thousandSeparator: '.', decimalSeparator: ',', symbolBeforeAmount: true),
    'MXN': CurrencySpec(code: 'MXN', symbol: r'$', decimals: 2, thousandSeparator: ',', decimalSeparator: '.', symbolBeforeAmount: true),
    'ARS': CurrencySpec(code: 'ARS', symbol: r'$', decimals: 2, thousandSeparator: '.', decimalSeparator: ',', symbolBeforeAmount: true),
    'CLP': CurrencySpec(code: 'CLP', symbol: r'$', decimals: 0, thousandSeparator: '.', decimalSeparator: ',', symbolBeforeAmount: true),
    'PEN': CurrencySpec(code: 'PEN', symbol: 'S/ ', decimals: 2, thousandSeparator: ',', decimalSeparator: '.', symbolBeforeAmount: true),
    'BRL': CurrencySpec(code: 'BRL', symbol: r'R$ ', decimals: 2, thousandSeparator: '.', decimalSeparator: ',', symbolBeforeAmount: true),
    'USD': CurrencySpec(code: 'USD', symbol: r'$', decimals: 2, thousandSeparator: ',', decimalSeparator: '.', symbolBeforeAmount: true),
    'EUR': CurrencySpec(code: 'EUR', symbol: '€', decimals: 2, thousandSeparator: '.', decimalSeparator: ',', symbolBeforeAmount: false),
  };

  /// Moneda desconocida: se muestra con su código y 2 decimales (ISO 4217).
  static CurrencySpec of(String code) =>
      catalog[code.toUpperCase()] ??
      CurrencySpec(
        code: code.toUpperCase(),
        symbol: '${code.toUpperCase()} ',
        decimals: 2,
        thousandSeparator: ',',
        decimalSeparator: '.',
        symbolBeforeAmount: true,
      );
}

/// Conversión entre lo que escribe el usuario (unidades mayores, p. ej.
/// `18.50`) y el entero en unidad mínima que espera el backend. Sin `double`.
extension CurrencyInput on CurrencySpec {
  /// `"18.5"` → 1850 (MXN) · `"180000"` → 180000 (COP). Null si no es válido.
  int? toMinor(String text) {
    final clean = text.trim().replaceAll(' ', '');
    if (clean.isEmpty) return null;
    final m = RegExp(r'^(\d+)(?:[.,](\d*))?$').firstMatch(clean);
    if (m == null) return null;
    var whole = int.parse(m.group(1)!);
    var frac = m.group(2) ?? '';
    if (decimals == 0) {
      // Sin decimales: "180.000" escrito con separador de miles.
      if (frac.isNotEmpty) {
        final digits = clean.replaceAll(RegExp(r'\D'), '');
        return int.tryParse(digits);
      }
      return whole;
    }
    if (frac.length > decimals) frac = frac.substring(0, decimals);
    frac = frac.padRight(decimals, '0');
    var factor = 1;
    for (var i = 0; i < decimals; i++) {
      factor *= 10;
    }
    whole = whole * factor + int.parse(frac);
    return whole;
  }

  /// 1850 (MXN) → `"18.50"` · 180000 (COP) → `"180000"` (para campos de texto).
  String toInput(int minor) {
    if (decimals == 0) return '$minor';
    var factor = 1;
    for (var i = 0; i < decimals; i++) {
      factor *= 10;
    }
    final whole = minor ~/ factor;
    final frac = (minor % factor).toString().padLeft(decimals, '0');
    return '$whole.$frac';
  }
}
