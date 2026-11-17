import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/business_repository.dart';
import '../../../shared/models/technician_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/sr_card.dart';

/// Reseñas recibidas con una respuesta pública única por reseña.
class ReviewsReceivedScreen extends ConsumerWidget {
  const ReviewsReceivedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(myReviewsProvider);
    final locale = ref.watch(regionProfileProvider).locale;
    return Scaffold(
      appBar: AppBar(title: Text(l.bizReviews)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(myReviewsProvider)),
        data: (list) => list.isEmpty
            ? EmptyStateView(title: l.bizNoReviews)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ReviewItem(review: list[i], locale: locale),
              ),
      ),
    );
  }
}

class _ReviewItem extends ConsumerWidget {
  const _ReviewItem({required this.review, required this.locale});
  final ReviewModel review;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = review;
    return SrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(r.clientName,
                    style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              ),
              for (var i = 1; i <= 5; i++)
                Icon(i <= r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16, color: SrRobotColors.starOrange),
            ],
          ),
          if (r.createdAt != null)
            Text(DateFormatter.shortDate(r.createdAt!, locale), style: AppText.small),
          if (r.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final t in r.tags) SrTag(t)]),
          ],
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(r.comment!, style: AppText.body),
          ],
          const SizedBox(height: 10),
          if (r.replyText != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SrRobotColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(r.replyText!, style: AppText.meta),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final ok = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _ReplySheet(reviewId: r.id),
                  );
                  if (ok == true) ref.invalidate(myReviewsProvider);
                },
                icon: const Icon(Icons.reply_rounded, color: SrRobotColors.primaryTeal),
                label: Text(l.bizReply,
                    style: AppText.meta.copyWith(
                        color: SrRobotColors.primaryTeal, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReplySheet extends ConsumerStatefulWidget {
  const _ReplySheet({required this.reviewId});
  final String reviewId;

  @override
  ConsumerState<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends ConsumerState<_ReplySheet> {
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = context.l10n;
    if (_text.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(businessRepositoryProvider)
          .replyReview(widget.reviewId, _text.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.bizReplySent)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.bizReply, style: AppText.h2),
              const SizedBox(height: 12),
              TextField(
                controller: _text,
                minLines: 3,
                maxLines: 5,
                autofocus: true,
                style: AppText.body,
                decoration: InputDecoration(hintText: l.bizReplyHint),
              ),
              const SizedBox(height: 14),
              SrButton(label: l.commonSend, loading: _busy, onPressed: _send),
            ],
          ),
        ),
      ),
    );
  }
}
