import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/config_repository.dart';
import '../../../shared/data/location_provider.dart';
import '../../../shared/data/technicians_repository.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/sr_card.dart';
import '../../../shared/widgets/technician_cards.dart';
import 'map_view.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialCategory});
  final String? initialCategory;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TechnicianQuery _query =
      TechnicianQuery(category: widget.initialCategory, limit: 50);
  final _text = TextEditingController();
  Timer? _debounce;
  bool _mapMode = false;

  @override
  void didUpdateWidget(covariant SearchScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialCategory != old.initialCategory &&
        widget.initialCategory != null) {
      setState(() =>
          _query = _query.copyWith(category: widget.initialCategory));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _onText(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _query = _query.copyWith(q: v.trim()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final results = ref.watch(techniciansSearchProvider(_query));
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final location = ref.watch(locationProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(child: Text(l.searchTitle, style: AppText.h1)),
                  _ViewToggle(
                    mapMode: _mapMode,
                    listLabel: l.searchList,
                    mapLabel: l.searchMap,
                    onChanged: (v) => setState(() => _mapMode = v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: TextField(
                controller: _text,
                onChanged: _onText,
                textInputAction: TextInputAction.search,
                style: AppText.body,
                decoration: InputDecoration(
                  hintText: l.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: SrRobotColors.textGray),
                ),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  SrFilterChip(
                    label: l.searchFilterHome,
                    selected: _query.home,
                    onTap: () => setState(
                        () => _query = _query.copyWith(home: !_query.home)),
                  ),
                  const SizedBox(width: 8),
                  SrFilterChip(
                    label: l.searchFilterVerified,
                    selected: _query.verified,
                    onTap: () => setState(() =>
                        _query = _query.copyWith(verified: !_query.verified)),
                  ),
                  const SizedBox(width: 8),
                  SrFilterChip(
                    label: l.searchFilterRating,
                    selected: _query.minRating != null,
                    onTap: () => setState(() => _query =
                        _query.minRating != null
                            ? _query.copyWith(clearMinRating: true)
                            : _query.copyWith(minRating: 4.8)),
                  ),
                  for (final c in cats) ...[
                    const SizedBox(width: 8),
                    SrFilterChip(
                      label: '${emojiFor(c)} $c',
                      selected: _query.category == c,
                      onTap: () => setState(() => _query =
                          _query.category == c
                              ? _query.copyWith(clearCategory: true)
                              : _query.copyWith(category: c)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(techniciansSearchProvider(_query)),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyStateView(
                        title: l.searchEmptyTitle, body: l.searchEmptyBody);
                  }
                  if (_mapMode) {
                    if (location == null) {
                      return EmptyStateView(title: l.searchMapNeedsLocation);
                    }
                    return TechniciansMapView(
                      technicians: list,
                      center: location,
                      onOpen: (t) => context.push(Routes.technician(t.id)),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: Text(l.searchResults(list.length),
                            style: AppText.meta),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          color: SrRobotColors.primaryTeal,
                          onRefresh: () async {
                            ref.invalidate(techniciansSearchProvider(_query));
                            await ref.read(
                                techniciansSearchProvider(_query).future);
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => TechnicianListTile(
                              tech: list[i],
                              onTap: () =>
                                  context.push(Routes.technician(list[i].id)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.mapMode,
    required this.listLabel,
    required this.mapLabel,
    required this.onChanged,
  });

  final bool mapMode;
  final String listLabel;
  final String mapLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label, bool selected, bool value) =>
        GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? SrRobotColors.primaryTeal : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: selected ? Colors.white : SrRobotColors.textGray),
                const SizedBox(width: 4),
                Text(label,
                    style: AppText.small.copyWith(
                      color: selected ? Colors.white : SrRobotColors.textGray,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SrRobotColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SrRobotColors.lineBorder),
      ),
      child: Row(children: [
        item(Icons.view_list_rounded, listLabel, !mapMode, false),
        item(Icons.map_outlined, mapLabel, mapMode, true),
      ]),
    );
  }
}
