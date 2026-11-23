import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/models/order_model.dart';
import '../config/regional_profile.dart';
import '../constants/app_colors.dart';
import '../network/api_client.dart';
import 'currency_formatter.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension MoneyX on WidgetRef {
  /// Formatea un monto entero. Si el dato trae su moneda ([currency], p. ej.
  /// `order.currency`) se usa esa; si no, la del país activo.
  /// Usa `read` para poder llamarse también desde callbacks; las pantallas
  /// que muestran dinero ya observan el perfil regional o sus datos.
  String money(int amount, {String? freeLabel, String? currency}) =>
      CurrencyFormatter.formatIn(
          amount, currency, read(regionProfileProvider),
          freeLabel: freeLabel);
}

extension OrderStateUi on OrderState {
  String label(AppLocalizations l) => switch (this) {
        OrderState.solicitado => l.statusSolicitado,
        OrderState.diagnostico => l.statusDiagnostico,
        OrderState.enReparacion => l.statusEnReparacion,
        OrderState.listo => l.statusListo,
        OrderState.entregado => l.statusEntregado,
        OrderState.cancelado => l.statusCancelado,
        OrderState.disputa => l.statusDisputa,
      };

  Color get color => switch (this) {
        OrderState.solicitado => SrRobotColors.statusSolicitado,
        OrderState.diagnostico => SrRobotColors.statusDiagnostico,
        OrderState.enReparacion => SrRobotColors.statusEnReparacion,
        OrderState.listo => SrRobotColors.statusListo,
        OrderState.entregado => SrRobotColors.statusEntregado,
        OrderState.cancelado => SrRobotColors.alertRed,
        OrderState.disputa => SrRobotColors.alertRed,
      };
}

/// Marcas de pago locales: son nombres propios (no se traducen).
const paymentBrandNames = <String, String>{
  'NEQUI': 'Nequi',
  'DAVIPLATA': 'Daviplata',
  'OXXO': 'OXXO',
  'SPEI': 'SPEI',
  'MERCADOPAGO': 'Mercado Pago',
  'MERCADO_PAGO': 'Mercado Pago',
  'CODI': 'CoDi',
  'TRANSFERENCIA_3': 'Transferencias 3.0',
  'PAGOEFECTIVO': 'PagoEfectivo',
  'APPLE_PAY': 'Apple Pay',
  'STRIPE': 'Stripe',
  'VENMO': 'Venmo',
  'SEPA_DIRECT_DEBIT': 'SEPA',
  'KLARNA': 'Klarna',
  'WEBPAY': 'Webpay',
  'YAPE': 'Yape',
  'PLIN': 'Plin',
  'PIX': 'Pix',
  'BOLETO': 'Boleto',
  'PAYPAL': 'PayPal',
  'BIZUM': 'Bizum',
  'SEPA': 'SEPA',
  'PSE': 'PSE',
};

/// Nombre visible de un método de pago del backend.
String paymentLabel(AppLocalizations l, String code) => switch (code) {
      'CARD' => l.payCARD,
      'CASH' => l.payCASH,
      'TRANSFERENCIA' => l.payTRANSFER,
      _ => paymentBrandNames[code] ?? _humanize(code),
    };

String _humanize(String code) {
  final w = code.toLowerCase().replaceAll('_', ' ');
  return w.isEmpty ? code : w[0].toUpperCase() + w.substring(1);
}

/// Ícono por tipo de método (dato visual).
const _paymentIcons = <String, IconData>{
  'CARD': Icons.credit_card_rounded,
  'CASH': Icons.payments_outlined,
  'OXXO': Icons.storefront_outlined,
  'BOLETO': Icons.receipt_long_outlined,
  'SPEI': Icons.account_balance_outlined,
  'SEPA': Icons.account_balance_outlined,
  'SEPA_DIRECT_DEBIT': Icons.account_balance_outlined,
  'TRANSFERENCIA': Icons.account_balance_outlined,
  'TRANSFERENCIA_3': Icons.qr_code_2_rounded,
  'CODI': Icons.qr_code_2_rounded,
  'PAGOEFECTIVO': Icons.storefront_outlined,
  'APPLE_PAY': Icons.phone_iphone_rounded,
  'STRIPE': Icons.credit_card_rounded,
  'KLARNA': Icons.receipt_long_outlined,
  'VENMO': Icons.account_balance_wallet_outlined,
  'MERCADO_PAGO': Icons.account_balance_wallet_outlined,
  'PSE': Icons.account_balance_outlined,
  'PAYPAL': Icons.account_balance_wallet_outlined,
  'MERCADOPAGO': Icons.account_balance_wallet_outlined,
  'WEBPAY': Icons.credit_card_rounded,
};

IconData paymentIcon(String code) =>
    _paymentIcons[code] ?? Icons.phone_iphone_rounded;

/// Mensaje de error legible a partir de cualquier excepción.
String errorText(BuildContext context, Object error) {
  final e = ApiException.from(error);
  if (e.isNetwork) return context.l10n.commonNetworkError;
  return e.message ?? context.l10n.commonGenericError;
}
