import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/sr_card.dart';
import '../../auth/domain/session_controller.dart';

/// Tarjeta de usuario + alternancia Cliente/Técnico + cerrar sesión.
/// Se comparte entre el perfil del cliente y "Mi negocio".
class AccountModeSection extends ConsumerStatefulWidget {
  const AccountModeSection(
      {super.key, this.showCard = true, this.showActions = true});

  /// Tarjeta con nombre, contacto y modo actual.
  final bool showCard;

  /// Botones de cambio de modo y cerrar sesión.
  final bool showActions;

  @override
  ConsumerState<AccountModeSection> createState() =>
      _AccountModeSectionState();
}

class _AccountModeSectionState extends ConsumerState<AccountModeSection> {
  bool _switching = false;

  Future<void> _switch(UserRole target) async {
    final user = ref.read(currentUserProvider);
    // Primera vez como técnico: pedimos los datos del negocio.
    if (target == UserRole.technician && !(user?.hasTechnicianRole ?? false)) {
      context.push(Routes.techOnboarding);
      return;
    }
    setState(() => _switching = true);
    try {
      await ref.read(sessionProvider.notifier).switchMode(target);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final isTech = user.activeRole == UserRole.technician;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showCard)
        SrCard(
          child: Row(
            children: [
              InitialsAvatar(initials: user.initials, size: 56, seed: user.id),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: AppText.h3),
                    Text(user.email ?? user.phone ?? '', style: AppText.meta),
                    const SizedBox(height: 6),
                    SrTag(isTech ? l.profileModeTechnician : l.profileModeClient),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.showCard && widget.showActions) const SizedBox(height: 16),
        if (widget.showActions) ...[
        SrButton(
          label: isTech ? l.profileSwitchToClient : l.profileSwitchToTechnician,
          icon: Icons.swap_horiz_rounded,
          variant: SrButtonVariant.dark,
          loading: _switching,
          onPressed: () =>
              _switch(isTech ? UserRole.client : UserRole.technician),
        ),
        const SizedBox(height: 10),
        SrButton(
          label: l.profileLogout,
          icon: Icons.logout_rounded,
          variant: SrButtonVariant.ghost,
          onPressed: () => ref.read(sessionProvider.notifier).logout(),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(l.appName,
              style: AppText.small.copyWith(color: SrRobotColors.textGray)),
        ),
        ],
      ],
    );
  }
}
