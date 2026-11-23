import 'package:flutter/services.dart';

import '../config/currency_spec.dart';

/// Permite dígitos y, si la moneda tiene decimales, un separador `.`/`,`
/// con hasta [CurrencySpec.decimals] cifras después.
List<TextInputFormatter> moneyInputFormatters(CurrencySpec spec) => [
      spec.decimals == 0
          ? FilteringTextInputFormatter.digitsOnly
          : FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      if (spec.decimals > 0)
        TextInputFormatter.withFunction((old, value) {
          final ok = RegExp('^\\d*([.,]\\d{0,${spec.decimals}})?\$')
              .hasMatch(value.text);
          return ok ? value : old;
        }),
    ];
