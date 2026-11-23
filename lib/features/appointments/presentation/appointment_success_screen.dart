import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/appointments_repository.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/payment_selector.dart';
import '../../../shared/widgets/robot_avatar.dart';
import '../../../shared/widgets/sr_card.dart';

class AppointmentSuccessScreen extends ConsumerWidget {
  const AppointmentSuccessScreen({super.key, required this.summary});
  final AppointmentSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(regionProfileProvider).locale;
    final date = DateTime.tryParse(summary.date);
    final dateText =
        date == null ? summary.date : DateFormatter.shortDate(date, locale);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(child: RobotAvatar(size: 150)),
              const SizedBox(height: 16),
              Text(l.successTitle,
                  textAlign: TextAlign.center, style: AppText.h1),
              const SizedBox(height: 6),
              Text(l.successBody(dateText, summary.time),
                  textAlign: TextAlign.center, style: AppText.bodyGray),
              const SizedBox(height: 24),
              SrCard(
                child: Column(
                  children: [
                    SummaryRow(summary.serviceName, ref.money(summary.servicePrice, currency: summary.currency)),
                    if (summary.isHome)
                      SummaryRow(l.scheduleHomeLine, ref.money(summary.homeFee, currency: summary.currency)),
                    SummaryRow(l.schedulePayment,
                        paymentLabel(l, summary.paymentMethod)),
                    const Divider(height: 16),
                    SummaryRow(l.commonTotal, ref.money(summary.total, currency: summary.currency), bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const EscrowNote(),
              const Spacer(),
              SrButton(
                label: l.successSeeOrder,
                onPressed: () {
                  context.go(Routes.clientOrders);
                  context.push(Routes.order(summary.orderId));
                },
              ),
              const SizedBox(height: 10),
              SrButton(
                label: l.successGoHome,
                variant: SrButtonVariant.ghost,
                onPressed: () => context.go(Routes.clientHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
