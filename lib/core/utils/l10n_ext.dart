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
  /// Formatea un monto entero con el perfil regional activo.
  String money(int amount, {String? freeLabel}) => CurrencyFormatter.format(
      amount, read(regionProfileProvider),
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

/// Nombre visible de un método de pago del backend.
String paymentLabel(AppLocalizations l, String code) => switch (code) {
      'NEQUI' => l.payNEQUI,
      'DAVIPLATA' => l.payDAVIPLATA,
      'CARD' => l.payCARD,
      'CASH' => l.payCASH,
      _ => code,
    };

IconData paymentIcon(String code) => switch (code) {
      'CARD' => Icons.credit_card_rounded,
      'CASH' => Icons.payments_outlined,
      _ => Icons.phone_iphone_rounded,
    };

/// Mensaje de error legible a partir de cualquier excepción.
String errorText(BuildContext context, Object error) {
  final e = ApiException.from(error);
  if (e.isNetwork) return context.l10n.commonNetworkError;
  return e.message ?? context.l10n.commonGenericError;
}
