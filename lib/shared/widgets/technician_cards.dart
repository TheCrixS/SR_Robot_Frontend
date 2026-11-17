import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';
import '../models/technician_model.dart';
import 'sr_card.dart';

/// Foto del técnico o iniciales si no tiene.
class TechnicianPhoto extends StatelessWidget {
  const TechnicianPhoto({super.key, required this.tech, this.size = 56});
  final TechnicianModel tech;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = tech.photos.isEmpty ? null : EnvConfig.mediaUrl(tech.photos.first);
    final fallback =
        InitialsAvatar(initials: tech.initials, size: size, seed: tech.id);
    if (url == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => fallback,
        placeholder: (_, __) => fallback,
      ),
    );
  }
}

/// Tarjeta vertical para carruseles horizontales del inicio.
class TechnicianCarouselCard extends ConsumerWidget {
  const TechnicianCarouselCard({super.key, required this.tech, this.onTap});
  final TechnicianModel tech;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final price = tech.minPrice;
    return SizedBox(
      width: 168,
      child: SrCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TechnicianPhoto(tech: tech, size: 48),
                const Spacer(),
                if (tech.isVerified)
                  const Icon(Icons.verified_rounded,
                      size: 18, color: SrRobotColors.primaryTeal),
              ],
            ),
            const SizedBox(height: 10),
            Text(tech.businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            Text(tech.mainCategory,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.small),
            const SizedBox(height: 8),
            Row(
              children: [
                RatingLabel(tech.rating),
                const Spacer(),
                if (tech.distanceKm != null)
                  Text(l.commonKm(tech.distanceKm!.toStringAsFixed(1)),
                      style: AppText.small),
              ],
            ),
            if (price != null) ...[
              const SizedBox(height: 6),
              Text(l.techFrom(ref.money(price)),
                  style: AppText.small.copyWith(
                      color: SrRobotColors.darkTeal,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fila de resultado de búsqueda.
class TechnicianListTile extends ConsumerWidget {
  const TechnicianListTile({super.key, required this.tech, this.onTap});
  final TechnicianModel tech;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final price = tech.minPrice;
    return SrCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          TechnicianPhoto(tech: tech, size: 60),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(tech.businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyMedium
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                    if (tech.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          size: 16, color: SrRobotColors.primaryTeal),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(tech.categories.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.small),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    RatingLabel(tech.rating, count: tech.reviewsCount),
                    if (tech.distanceKm != null)
                      Text(l.commonKm(tech.distanceKm!.toStringAsFixed(1)),
                          style: AppText.small),
                    if (tech.homeService)
                      SrTag(l.techHomeService, icon: Icons.home_outlined),
                  ],
                ),
              ],
            ),
          ),
          if (price != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(ref.money(price),
                      style: AppText.bodyMedium.copyWith(
                          color: SrRobotColors.darkTeal,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
