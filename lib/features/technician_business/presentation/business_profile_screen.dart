import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/data/business_repository.dart';
import '../../../shared/widgets/sr_card.dart';
import '../../../shared/widgets/technician_cards.dart';
import '../../profile/presentation/mode_switch_card.dart';

String verificationLabel(AppLocalizations l, String s) => switch (s) {
      'VERIFIED' => l.bizStatusVERIFIED,
      'IN_REVIEW' => l.bizStatusIN_REVIEW,
      'REJECTED' => l.bizStatusREJECTED,
      _ => l.bizStatusPENDING,
    };

/// "Mi negocio": acceso a perfil, horario, servicios, suscripción,
/// billetera, reseñas, verificación y cambio de modo.
class BusinessProfileScreen extends ConsumerWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final business = ref.watch(myBusinessProvider).valueOrNull;
    final wallet = ref.watch(walletProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l.bizTitle, style: AppText.h1)),
      body: RefreshIndicator(
        color: SrRobotColors.primaryTeal,
        onRefresh: () async {
          ref.invalidate(myBusinessProvider);
          ref.invalidate(walletProvider);
          await ref.read(myBusinessProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            if (business != null)
              SrCard(
                onTap: () => context.push(Routes.technician(business.id)),
                child: Row(
                  children: [
                    TechnicianPhoto(tech: business, size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(business.businessName, style: AppText.h3),
                          const SizedBox(height: 2),
                          RatingLabel(business.rating,
                              count: business.reviewsCount),
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, runSpacing: 6, children: [
                            SrTag(verificationLabel(l, business.verificationStatus),
                                icon: Icons.verified_user_outlined),
                            SrTag(l.dashPlan(business.plan),
                                color: SrRobotColors.yellowAccent
                                    .withValues(alpha: 0.4),
                                textColor: SrRobotColors.textInk),
                          ]),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: SrRobotColors.textGray),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _Tile(
              icon: Icons.storefront_outlined,
              title: l.bizPublicProfile,
              onTap: () => context.push(Routes.businessEdit),
            ),
            _Tile(
              icon: Icons.schedule_rounded,
              title: l.bizScheduleTitle,
              onTap: () => context.push(Routes.businessSchedule),
            ),
            _Tile(
              icon: Icons.handyman_outlined,
              title: l.bizServices,
              onTap: () => context.push(Routes.businessServices),
            ),
            _Tile(
              icon: Icons.workspace_premium_outlined,
              title: l.bizSubscription,
              trailing: business?.plan,
              onTap: () => context.push(Routes.subscription),
            ),
            _Tile(
              icon: Icons.account_balance_wallet_outlined,
              title: l.bizWallet,
              trailing: wallet == null ? null : ref.money(wallet.available),
              onTap: () => context.push(Routes.wallet),
            ),
            _Tile(
              icon: Icons.star_outline_rounded,
              title: l.bizReviews,
              onTap: () => context.push(Routes.businessReviews),
            ),
            if (business != null && business.verificationStatus != 'VERIFIED' &&
                business.verificationStatus != 'IN_REVIEW')
              _Tile(
                icon: Icons.verified_user_outlined,
                title: l.bizVerification,
                trailing: verificationLabel(l, business.verificationStatus),
                onTap: () => context.push(Routes.verification),
              ),
            const SizedBox(height: 16),
            const AccountModeSection(),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(
      {required this.icon, required this.title, required this.onTap, this.trailing});
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SrCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: SrRobotColors.softTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: SrRobotColors.primaryTeal),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppText.bodyMedium)),
            if (trailing != null)
              Text(trailing!,
                  style: AppText.meta.copyWith(
                      color: SrRobotColors.darkTeal, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: SrRobotColors.textGray),
          ],
        ),
      ),
    );
  }
}
