import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/config_repository.dart';
import '../../../shared/data/location_provider.dart';
import '../../../shared/data/notifications_repository.dart';
import '../../../shared/data/orders_repository.dart';
import '../../../shared/data/technicians_repository.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/models/technician_model.dart';
import '../../../shared/widgets/brand_header.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/order_timeline.dart';
import '../../../shared/widgets/robot_avatar.dart';
import '../../../shared/widgets/sr_card.dart';
import '../../../shared/widgets/technician_cards.dart';
import '../../auth/domain/session_controller.dart';
import 'category_tile.dart';

const _nearbyQuery = TechnicianQuery(sort: 'distance', limit: 10);
const _topRatedQuery = TechnicianQuery(sort: 'rating', limit: 10);

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(locationProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(activeOrderProvider);
    ref.invalidate(techniciansSearchProvider(_nearbyQuery));
    ref.invalidate(techniciansSearchProvider(_topRatedQuery));
    await ref.read(techniciansSearchProvider(_nearbyQuery).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    final categories = ref.watch(categoriesProvider);
    final activeOrder = ref.watch(activeOrderProvider);

    return RefreshIndicator(
      color: SrRobotColors.primaryTeal,
      onRefresh: () => _refresh(ref),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(name: user?.firstName ?? ''),
          const SizedBox(height: 20),

          // Categorías
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SectionTitle(l.homeCategories),
          ),
          const SizedBox(height: 12),
          categories.when(
            loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (cats) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cats.length > 8 ? 8 : cats.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (_, i) => CategoryTile(
                  category: cats[i],
                  index: i,
                  onTap: () => context.go(
                      Uri(path: Routes.clientSearch, queryParameters: {
                    'cat': cats[i],
                  }).toString()),
                ),
              ),
            ),
          ),

          // Reparación en curso
          if (activeOrder.valueOrNull != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ActiveOrderCard(order: activeOrder.value!),
            ),
          ],

          // Banner de cotización
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _QuoteBanner(),
          ),

          // Técnicos cercanos
          const SizedBox(height: 24),
          _TechCarousel(
            title: l.homeNearby,
            query: _nearbyQuery,
          ),
          const SizedBox(height: 20),
          _TechCarousel(
            title: l.homeTopRated,
            query: _topRatedQuery,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final loc = ref.watch(locationProvider);
    final locationText = loc.when(
      data: (p) => p == null ? l.homeLocationUnknown : l.homeCurrentLocation,
      loading: () => l.commonLoading,
      error: (_, __) => l.homeLocationUnknown,
    );

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
                    GestureDetector(
                      onTap: () => ref.invalidate(locationProvider),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text(locationText,
                              style: AppText.meta.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(l.homeGreeting(name),
                        style: AppText.h1.copyWith(color: Colors.white)),
                    Text(l.homeQuestion,
                        style: AppText.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.92))),
                  ],
                ),
              ),
              _Bell(count: ref.watch(unreadNotificationsProvider)),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.go(Routes.clientSearch),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: SrRobotColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: SrRobotColors.cardShadow,
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: SrRobotColors.textGray),
                  const SizedBox(width: 10),
                  Text(l.homeSearchHint, style: AppText.bodyGray),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderCard extends ConsumerWidget {
  const _ActiveOrderCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(regionProfileProvider).locale;
    final step = order.state.step;
    return SrCard(
      onTap: () => context.push(Routes.order(order.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SrRobotColors.softTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.build_circle_outlined,
                    color: SrRobotColors.primaryTeal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.homeRepairInProgress, style: AppText.small),
                    Text(order.serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text(order.technicianName, style: AppText.small),
                  ],
                ),
              ),
              OrderStatusBadge(order.state),
            ],
          ),
          const SizedBox(height: 14),
          // Progreso de los 5 estados
          Row(
            children: [
              for (var i = 0; i < OrderState.sequence.length; i++) ...[
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: step >= 0 && i <= step
                          ? OrderState.sequence[i].color
                          : SrRobotColors.lineBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (i < OrderState.sequence.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
          if (order.estimatedDelivery != null) ...[
            const SizedBox(height: 10),
            Text(
              '${DateFormatter.dayMonth(order.estimatedDelivery!, locale)} · '
              '${DateFormatter.time(order.estimatedDelivery!, locale)}',
              style: AppText.small,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuoteBanner extends StatelessWidget {
  const _QuoteBanner();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
      decoration: BoxDecoration(
        color: SrRobotColors.yellowAccent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: SrRobotColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.homeQuoteBannerTitle, style: AppText.h3),
                const SizedBox(height: 4),
                Text(l.homeQuoteBannerBody,
                    style: AppText.meta.copyWith(color: SrRobotColors.textInk)),
                const SizedBox(height: 12),
                SrButton(
                  label: l.homeQuoteBannerCta,
                  variant: SrButtonVariant.dark,
                  expand: false,
                  onPressed: () => context.push(Routes.requestQuote()),
                ),
              ],
            ),
          ),
          const RobotAvatar(size: 96),
        ],
      ),
    );
  }
}

class _TechCarousel extends ConsumerWidget {
  const _TechCarousel({required this.title, required this.query});
  final String title;
  final TechnicianQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(techniciansSearchProvider(query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionTitle(
            title,
            action: l.commonSeeAll,
            onAction: () => context.go(Routes.clientSearch),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 196,
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: TextButton(
                onPressed: () =>
                    ref.invalidate(techniciansSearchProvider(query)),
                child: Text(errorText(context, e),
                    textAlign: TextAlign.center, style: AppText.meta),
              ),
            ),
            data: (List<TechnicianModel> list) => list.isEmpty
                ? Center(child: Text(l.homeNoTechnicians, style: AppText.meta))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => TechnicianCarouselCard(
                      tech: list[i],
                      onTap: () => context.push(Routes.technician(list[i].id)),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Routes.notifications),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: Colors.white),
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
