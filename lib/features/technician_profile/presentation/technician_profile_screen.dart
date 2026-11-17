import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/data/technicians_repository.dart';
import '../../../shared/models/technician_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/sr_card.dart';
import '../../../shared/widgets/technician_cards.dart';

class TechnicianProfileScreen extends ConsumerWidget {
  const TechnicianProfileScreen({super.key, required this.technicianId});
  final String technicianId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(technicianDetailProvider(technicianId));
    return Scaffold(
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => SafeArea(
          child: ErrorView(
            error: e,
            onRetry: () =>
                ref.invalidate(technicianDetailProvider(technicianId)),
          ),
        ),
        data: (t) => _Body(tech: t),
      ),
      bottomNavigationBar: async.hasValue ? _ActionBar(tech: async.value!) : null,
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.tech});
  final TechnicianModel tech;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late bool _favorite = widget.tech.isFavorite;

  Future<void> _toggleFavorite() async {
    final l = context.l10n;
    final next = !_favorite;
    setState(() => _favorite = next);
    try {
      await ref
          .read(techniciansRepositoryProvider)
          .setFavorite(widget.tech.id, next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next ? l.techFavoriteAdded : l.techFavoriteRemoved)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _favorite = !next);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tech;
    final l = context.l10n;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Cover(
          tech: t,
          favorite: _favorite,
          onFavorite: _toggleFavorite,
        )),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          sliver: SliverList.list(
            children: [
              _InfoRow(tech: t),
              if (t.description.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(l.techAbout, style: AppText.h3),
                const SizedBox(height: 6),
                Text(t.description, style: AppText.bodyGray),
              ],
              const SizedBox(height: 20),
              Text(l.techServices, style: AppText.h2),
              const SizedBox(height: 10),
              if (t.services.where((s) => s.active).isEmpty)
                Text(l.techNoServices, style: AppText.meta)
              else
                for (final s in t.services.where((s) => s.active)) ...[
                  _ServiceTile(service: s),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 14),
              _ScheduleCard(schedule: t.schedule),
              const SizedBox(height: 24),
              _ReviewsSection(tech: t),
            ],
          ),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({
    required this.tech,
    required this.favorite,
    required this.onFavorite,
  });

  final TechnicianModel tech;
  final bool favorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: const BoxDecoration(
        gradient: SrRobotColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 24),
      child: Column(
        children: [
          Row(
            children: [
              _CircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.pop()),
              const Spacer(),
              _CircleButton(
                icon: favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: favorite ? SrRobotColors.alertRed : SrRobotColors.textInk,
                onTap: onFavorite,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TechnicianPhoto(tech: tech, size: 84),
          const SizedBox(height: 10),
          Text(tech.businessName,
              textAlign: TextAlign.center,
              style: AppText.h1.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(tech.categories.join(' · '),
              textAlign: TextAlign.center,
              style: AppText.meta.copyWith(color: Colors.white)),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (tech.isVerified)
                SrTag(l.techVerified,
                    icon: Icons.verified_rounded,
                    color: Colors.white,
                    textColor: SrRobotColors.darkTeal),
              SrTag(
                '★ ${tech.rating.toStringAsFixed(1)} · ${l.techReviews(tech.reviewsCount)}',
                color: Colors.white,
                textColor: SrRobotColors.textInk,
              ),
              if (tech.distanceKm != null)
                SrTag(l.commonKm(tech.distanceKm!.toStringAsFixed(1)),
                    icon: Icons.near_me_outlined,
                    color: Colors.white,
                    textColor: SrRobotColors.textInk),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton(
      {required this.icon, required this.onTap, this.color = SrRobotColors.textInk});
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

class _InfoRow extends ConsumerWidget {
  const _InfoRow({required this.tech});
  final TechnicianModel tech;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = <(IconData, String)>[
      (Icons.task_alt_rounded, l.techCompleted(tech.completedOrders)),
      if (tech.responseTime != null && tech.responseTime!.isNotEmpty)
        (Icons.bolt_rounded, l.techResponseTime(tech.responseTime!)),
      if (tech.homeService) ...[
        (Icons.home_outlined, l.techCoverage(tech.coverageRadiusKm)),
        if (tech.homeExtraFee > 0)
          (Icons.local_shipping_outlined,
              l.techHomeFee(ref.money(tech.homeExtraFee))),
      ],
    ];
    return SrCard(
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        children: [
          for (final (icon, text) in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: SrRobotColors.primaryTeal),
                const SizedBox(width: 6),
                Text(text, style: AppText.meta.copyWith(color: SrRobotColors.textInk)),
              ],
            ),
        ],
      ),
    );
  }
}

class _ServiceTile extends ConsumerWidget {
  const _ServiceTile({required this.service});
  final TechService service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return SrCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: SrRobotColors.softTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.handyman_outlined,
                color: SrRobotColors.primaryTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  [
                    if (service.estimatedTime.isNotEmpty) service.estimatedTime,
                    l.techWarrantyDays(service.warrantyDays),
                  ].join(' · '),
                  style: AppText.small,
                ),
              ],
            ),
          ),
          Text(l.techFrom(ref.money(service.priceFrom)),
              style: AppText.meta.copyWith(
                  color: SrRobotColors.darkTeal, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule});
  final Map<String, DaySchedule> schedule;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final days = <String, String>{
      'mon': l.dayMon,
      'tue': l.dayTue,
      'wed': l.dayWed,
      'thu': l.dayThu,
      'fri': l.dayFri,
      'sat': l.daySat,
      'sun': l.daySun,
    };
    final today = const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'][
        DateTime.now().weekday - 1];

    return SrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.techSchedule, style: AppText.h3),
          const SizedBox(height: 8),
          for (final e in days.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(e.value,
                        style: (e.key == today ? AppText.bodyMedium : AppText.body)
                            .copyWith(
                                color: e.key == today
                                    ? SrRobotColors.primaryTeal
                                    : null)),
                  ),
                  const Spacer(),
                  Text(
                    (schedule[e.key]?.enabled ?? false)
                        ? '${schedule[e.key]!.open} – ${schedule[e.key]!.close}'
                        : l.techClosed,
                    style: AppText.meta,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.tech});
  final TechnicianModel tech;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(regionProfileProvider).locale;
    final total = tech.ratingDistribution.values.fold<int>(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.techReviewsTitle, style: AppText.h2),
        const SizedBox(height: 10),
        SrCard(
          child: Row(
            children: [
              Column(
                children: [
                  Text(tech.rating.toStringAsFixed(1),
                      style: AppText.h1.copyWith(fontSize: 36)),
                  _Stars(rating: tech.rating.round()),
                  const SizedBox(height: 4),
                  Text(l.techReviews(tech.reviewsCount), style: AppText.small),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    for (var star = 5; star >= 1; star--)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text('$star', style: AppText.small),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: total == 0
                                      ? 0
                                      : (tech.ratingDistribution[star] ?? 0) /
                                          total,
                                  minHeight: 6,
                                  backgroundColor: SrRobotColors.lineBorder,
                                  color: SrRobotColors.starOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (tech.reviews.isEmpty)
          Text(l.techNoReviews, style: AppText.meta)
        else
          for (final r in tech.reviews) ...[
            _ReviewTile(review: r, locale: locale, l: l),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile(
      {required this.review, required this.locale, required this.l});
  final ReviewModel review;
  final String locale;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final initials =
        review.clientName.isEmpty ? '?' : review.clientName[0].toUpperCase();
    return SrCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(initials: initials, size: 36, seed: review.clientName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.clientName,
                        style: AppText.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    _Stars(rating: review.rating, size: 14),
                  ],
                ),
              ),
              if (review.createdAt != null)
                Text(DateFormatter.shortDate(review.createdAt!, locale),
                    style: AppText.small),
            ],
          ),
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final t in review.tags) SrTag(t)],
            ),
          ],
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: AppText.body),
          ],
          if (review.replyText != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SrRobotColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.techReply,
                      style: AppText.small.copyWith(
                          color: SrRobotColors.darkTeal,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(review.replyText!, style: AppText.meta),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 16});
  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: SrRobotColors.starOrange,
          ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.tech});
  final TechnicianModel tech;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: const BoxDecoration(
        color: SrRobotColors.surfaceWhite,
        border: Border(top: BorderSide(color: SrRobotColors.lineBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: SrButton(
              label: '',
              icon: Icons.chat_bubble_outline_rounded,
              variant: SrButtonVariant.ghost,
              onPressed: () =>
                  context.push(Routes.chatWithTechnician(tech.id)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SrButton(
              label: l.techQuote,
              variant: SrButtonVariant.dark,
              onPressed: () =>
                  context.push(Routes.requestQuote(technicianId: tech.id)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SrButton(
              label: l.techSchedule2,
              onPressed: () => context.push(Routes.schedule(tech.id)),
            ),
          ),
        ],
      ),
    );
  }
}
