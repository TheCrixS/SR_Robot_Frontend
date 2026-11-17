import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/orders_repository.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/sr_card.dart';

/// Hoja modal de calificación: 1–5 estrellas, tags y comentario.
/// Devuelve `true` si se envió.
Future<bool?> showReviewSheet(BuildContext context, String orderId) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReviewSheet(orderId: orderId),
    );

class ReviewSheet extends ConsumerStatefulWidget {
  const ReviewSheet({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  int _rating = 0;
  final Set<String> _tags = {};
  final _comment = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (_rating == 0) {
      setState(() => _error = l.reviewNeedRating);
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(ordersRepositoryProvider).review(
            widget.orderId,
            rating: _rating,
            tags: _tags.toList(),
            comment: _comment.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tags = [
      l.reviewTagPunctual,
      l.reviewTagExcellent,
      l.reviewTagFriendly,
      l.reviewTagClean,
      l.reviewTagFair,
      l.reviewTagFast,
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.reviewTitle, textAlign: TextAlign.center, style: AppText.h2),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      iconSize: 40,
                      onPressed: () => setState(() {
                        _rating = i;
                        _error = null;
                      }),
                      icon: Icon(
                        i <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: SrRobotColors.starOrange,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(l.reviewTags, style: AppText.h3),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in tags)
                    SrFilterChip(
                      label: t,
                      selected: _tags.contains(t),
                      onTap: () => setState(() =>
                          _tags.contains(t) ? _tags.remove(t) : _tags.add(t)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _comment,
                minLines: 2,
                maxLines: 4,
                style: AppText.body,
                decoration: InputDecoration(hintText: l.reviewComment),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
              ],
              const SizedBox(height: 16),
              SrButton(label: l.reviewSubmit, loading: _sending, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
