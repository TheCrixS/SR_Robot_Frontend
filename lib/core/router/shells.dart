import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/data/chat_repository.dart';
import '../../shared/data/notifications_repository.dart';
import '../../shared/widgets/sr_bottom_nav.dart';
import '../utils/l10n_ext.dart';

/// Contenedor con las 5 pestañas del modo cliente.
class ClientShell extends ConsumerWidget {
  const ClientShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    // Mantiene vivo el socket global /events mientras hay sesión.
    ref.watch(eventsSocketProvider);
    // Cargas iniciales para las insignias (mensajes y campana).
    ref.watch(conversationsProvider);
    ref.watch(notificationsProvider);
    final unread = ref.watch(unreadMessagesProvider);
    return Scaffold(
      body: shell,
      bottomNavigationBar: SrBottomNav(
        currentIndex: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: [
          SrNavItem(Icons.home_outlined, Icons.home_rounded, l.navHome),
          SrNavItem(Icons.search_rounded, Icons.search_rounded, l.navSearch),
          SrNavItem(Icons.build_outlined, Icons.build_rounded, l.navRepairs),
          SrNavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded,
              l.navMessages,
              badge: unread),
          SrNavItem(Icons.person_outline_rounded, Icons.person_rounded,
              l.navProfile),
        ],
      ),
    );
  }
}

/// Contenedor con las 5 pestañas del modo técnico.
class TechnicianShell extends ConsumerWidget {
  const TechnicianShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    ref.watch(eventsSocketProvider);
    ref.watch(notificationsProvider);
    return Scaffold(
      body: shell,
      bottomNavigationBar: SrBottomNav(
        currentIndex: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: [
          SrNavItem(Icons.grid_view_outlined, Icons.grid_view_rounded, l.navPanel),
          SrNavItem(Icons.inbox_outlined, Icons.inbox_rounded, l.navRequests),
          SrNavItem(Icons.calendar_today_outlined, Icons.calendar_today_rounded,
              l.navAgenda),
          SrNavItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded,
              l.navParts),
          SrNavItem(Icons.storefront_outlined, Icons.storefront_rounded,
              l.navBusiness),
        ],
      ),
    );
  }
}
