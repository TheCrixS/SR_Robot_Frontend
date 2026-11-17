import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/business_repository.dart';
import '../../../shared/data/chat_repository.dart';
import '../../../shared/data/notifications_repository.dart';
import '../../../shared/data/orders_repository.dart';
import '../../../shared/data/technician_work_repository.dart';
import '../../../shared/models/technician_model.dart';
import '../../../shared/widgets/brand_header.dart';
import '../../../shared/widgets/sr_card.dart';
import '../../auth/domain/session_controller.dart';
import '../../orders/presentation/orders_list_screen.dart';
import '../../technician_agenda/presentation/appointment_card.dart';
import 'requests_screen.dart';
import 'revenue_chart.dart';

DateTime get _today {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

class TechnicianDashboardScreen extends ConsumerWidget {
  const TechnicianDashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(myBusinessProvider);
    ref.invalidate(analyticsProvider);
    ref.invalidate(receivedRequestsProvider('NEW'));
    ref.invalidate(agendaProvider(_today));
    ref.invalidate(ordersListProvider('active'));
    await ref.read(analyticsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final business = ref.watch(myBusinessProvider);
    final analytics = ref.watch(analyticsProvider);
    final newRequests = ref.watch(receivedRequestsProvider('NEW'));
    final today = ref.watch(agendaProvider(_today));
    final orders = ref.watch(ordersListProvider('active'));
    final locale = ref.watch(regionProfileProvider).locale;

    return RefreshIndicator(
      color: SrRobotColors.primaryTeal,
      onRefresh: () => _refresh(ref),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(business: business.valueOrNull),
          if (business.valueOrNull != null &&
              business.value!.verificationStatus != 'VERIFIED') ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: VerificationBanner(status: business.value!.verificationStatus),
            ),
          ],
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: analytics.when(
              loading: () => const SizedBox(
                  height: 160, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text(errorText(context, e), style: AppText.meta),
              data: (a) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Kpi(
                          icon: Icons.payments_outlined,
                          label: l.dashRevenue,
                          value: ref.money(a.totalRevenue),
                          footnote: a.revenueChangePct == 0
                              ? null
                              : l.dashChange(
                                  '${a.revenueChangePct > 0 ? '+' : ''}${a.revenueChangePct.toStringAsFixed(0)}'),
                          footColor: a.revenueChangePct >= 0
                              ? SrRobotColors.darkTeal
                              : SrRobotColors.alertRed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Kpi(
                          icon: Icons.task_alt_rounded,
                          label: l.dashCompleted,
                          value: '${a.completedOrders}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Kpi(
                          icon: Icons.trending_up_rounded,
                          label: l.dashConversion,
                          value: '${a.conversionRate.toStringAsFixed(0)}%',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Kpi(
                          icon: Icons.visibility_outlined,
                          label: l.dashViews,
                          value: '${a.profileViews}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SrCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.dashWeekly, style: AppText.h3),
                        const SizedBox(height: 14),
                        RevenueBarChart(
                          weeks: a.weekly,
                          formatAmount: (v) => ref.money(v),
                          labelFor: (w) => w.weekStart == null
                              ? ''
                              : DateFormatter.dayMonth(w.weekStart!, locale),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: l.dashNewRequests,
            action: l.commonSeeAll,
            onAction: () => context.go(Routes.techRequests),
            child: newRequests.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(errorText(context, e), style: AppText.meta),
              data: (r) => r.items.isEmpty
                  ? _EmptyLine(l.dashNoRequests)
                  : Column(children: [
                      for (final q in r.items.take(2)) ...[
                        RequestCard(request: q),
                        const SizedBox(height: 10),
                      ],
                    ]),
            ),
          ),
          _Section(
            title: l.dashToday,
            action: l.commonSeeAll,
            onAction: () => context.go(Routes.techAgenda),
            child: today.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(errorText(context, e), style: AppText.meta),
              data: (list) => list.isEmpty
                  ? _EmptyLine(l.dashNoAppointments)
                  : Column(children: [
                      for (final a in list) ...[
                        AppointmentCard(appointment: a, day: _today),
                        const SizedBox(height: 10),
                      ],
                    ]),
            ),
          ),
          _Section(
            title: l.dashActiveOrders,
            child: orders.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(errorText(context, e), style: AppText.meta),
              data: (list) => list.isEmpty
                  ? _EmptyLine(l.dashNoOrders)
                  : Column(children: [
                      for (final o in list) ...[
                        OrderCard(order: o, showClient: true),
                        const SizedBox(height: 10),
                      ],
                    ]),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Header extends ConsumerStatefulWidget {
  const _Header({required this.business});
  final TechnicianModel? business;

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  bool? _available;

  Future<void> _toggle(bool v) async {
    setState(() => _available = v);
    try {
      await ref.read(businessRepositoryProvider).setAvailable(v);
    } catch (e) {
      if (!mounted) return;
      setState(() => _available = !v);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final b = widget.business;
    final user = ref.watch(currentUserProvider);
    final available = _available ?? b?.available ?? true;
    final unreadMsgs = ref.watch(unreadMessagesProvider);
    final unreadNotif = ref.watch(unreadNotificationsProvider);

    return BrandHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.dashHello(user?.firstName ?? ''),
                        style: AppText.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.92))),
                    Text(b?.businessName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.h1.copyWith(color: Colors.white)),
                    if (b != null) ...[
                      const SizedBox(height: 4),
                      SrTag(l.dashPlan(b.plan),
                          icon: Icons.workspace_premium_outlined,
                          color: Colors.white,
                          textColor: SrRobotColors.darkTeal),
                    ],
                  ],
                ),
              ),
              _HeaderIcon(
                icon: Icons.chat_bubble_outline_rounded,
                count: unreadMsgs,
                onTap: () => context.push(Routes.conversations),
              ),
              const SizedBox(width: 8),
              _HeaderIcon(
                icon: Icons.notifications_none_rounded,
                count: unreadNotif,
                onTap: () => context.push(Routes.notifications),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            decoration: BoxDecoration(
              color: SrRobotColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: SrRobotColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: available ? SrRobotColors.lime : SrRobotColors.textGray,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.dashAvailable, style: AppText.bodyMedium),
                      Text(available ? l.dashOnline : l.dashOffline,
                          style: AppText.small),
                    ],
                  ),
                ),
                Switch(value: available, onChanged: b == null ? null : _toggle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon(
      {required this.icon, required this.count, required this.onTap});
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SrRobotColors.alertRed,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(count > 99 ? '99+' : '$count',
                    style: AppText.tag.copyWith(color: Colors.white, fontSize: 10)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    this.footnote,
    this.footColor = SrRobotColors.darkTeal,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? footnote;
  final Color footColor;

  @override
  Widget build(BuildContext context) {
    return SrCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: SrRobotColors.softTeal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: SrRobotColors.primaryTeal),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppText.h2),
          ),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.small),
          if (footnote != null)
            Text(footnote!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.tag.copyWith(color: footColor)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.child, this.action, this.onAction});
  final String title;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(title, action: action, onAction: onAction),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => SrCard(
        child: Text(text, style: AppText.meta, textAlign: TextAlign.center),
      );
}

/// Aviso de verificación pendiente/en revisión/rechazada.
class VerificationBanner extends StatelessWidget {
  const VerificationBanner({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final inReview = status == 'IN_REVIEW';
    final rejected = status == 'REJECTED';
    final color = rejected
        ? SrRobotColors.alertRed
        : inReview
            ? SrRobotColors.infoBlue
            : SrRobotColors.yellowAccent;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            inReview ? Icons.hourglass_top_rounded : Icons.verified_user_outlined,
            color: SrRobotColors.textInk,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rejected
                  ? l.verifyBannerRejected
                  : inReview
                      ? l.verifyBannerReview
                      : l.verifyBannerPending,
              style: AppText.meta.copyWith(color: SrRobotColors.textInk),
            ),
          ),
          if (!inReview)
            TextButton(
              onPressed: () => context.push(Routes.verification),
              child: Text(l.verifyCta,
                  style: AppText.meta.copyWith(
                      color: SrRobotColors.textInk, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
