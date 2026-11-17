import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';

/// Lista seleccionable de métodos de pago (Nequi, Daviplata, Tarjeta…).
class PaymentSelector extends StatelessWidget {
  const PaymentSelector({
    super.key,
    required this.methods,
    required this.selected,
    required this.onChanged,
  });

  final List<String> methods;
  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final m in methods)
          GestureDetector(
            onTap: () => onChanged(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 150,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: selected == m
                    ? SrRobotColors.softTeal
                    : SrRobotColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected == m
                      ? SrRobotColors.primaryTeal
                      : SrRobotColors.lineBorder,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(paymentIcon(m),
                      size: 20,
                      color: selected == m
                          ? SrRobotColors.primaryTeal
                          : SrRobotColors.textGray),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(paymentLabel(l, m),
                        style: AppText.bodyMedium.copyWith(fontSize: 14)),
                  ),
                  if (selected == m)
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: SrRobotColors.primaryTeal),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Leyenda de pago protegido en custodia.
class EscrowNote extends StatelessWidget {
  const EscrowNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SrRobotColors.softTeal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined,
              color: SrRobotColors.primaryTeal, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(context.l10n.escrowNote,
                style: AppText.meta.copyWith(color: SrRobotColors.textInk)),
          ),
        ],
      ),
    );
  }
}

/// Fila etiqueta / valor para resúmenes de pago.
class SummaryRow extends StatelessWidget {
  const SummaryRow(this.label, this.value, {super.key, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? AppText.bodyMedium.copyWith(fontWeight: FontWeight.w700)
        : AppText.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: bold ? style : AppText.bodyGray)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
