import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/session_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/appointments/presentation/appointment_success_screen.dart';
import '../../features/appointments/presentation/schedule_appointment_screen.dart';
import '../../features/chat/presentation/chat_room_screen.dart';
import '../../features/chat/presentation/conversations_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/orders/presentation/orders_list_screen.dart';
import '../../features/quotes/presentation/compare_quotes_screen.dart';
import '../../features/quotes/presentation/request_quote_screen.dart';
import '../../shared/data/appointments_repository.dart';
import '../../shared/models/chat_models.dart';
import '../../features/client_home/presentation/home_screen.dart';
import '../../features/profile/presentation/account_lists_screens.dart';
import '../../features/profile/presentation/client_profile_screen.dart';
import '../../features/profile/presentation/my_devices_screen.dart';
import '../../features/support/presentation/support_screens.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/spare_parts/presentation/cart_screen.dart';
import '../../features/spare_parts/presentation/parts_catalog_screen.dart';
import '../../features/technician_agenda/presentation/agenda_screen.dart';
import '../../features/technician_agenda/presentation/order_execution_screen.dart';
import '../../features/technician_business/presentation/business_edit_screen.dart';
import '../../features/technician_business/presentation/business_profile_screen.dart';
import '../../features/technician_business/presentation/reviews_received_screen.dart';
import '../../features/technician_business/presentation/schedule_edit_screen.dart';
import '../../features/technician_business/presentation/services_screen.dart';
import '../../features/technician_business/presentation/subscription_plans_screen.dart';
import '../../features/technician_business/presentation/technician_onboarding_screen.dart';
import '../../features/technician_business/presentation/verification_screen.dart';
import '../../features/technician_business/presentation/wallet_screen.dart';
import '../../features/technician_panel/presentation/dashboard_screen.dart';
import '../../features/technician_panel/presentation/requests_screen.dart';
import '../../features/technician_profile/presentation/technician_profile_screen.dart';
import '../../shared/models/user_model.dart';
import 'shells.dart';

/// Rutas con nombre para navegar sin cadenas sueltas.
class Routes {
  Routes._();
  static const splash = '/splash';
  static const login = '/login';
  static const otp = '/login/otp';
  static const register = '/register';

  static const clientHome = '/c/home';
  static const clientSearch = '/c/search';
  static const clientOrders = '/c/orders';
  static const clientMessages = '/c/messages';
  static const clientProfile = '/c/profile';

  static const techDashboard = '/t/dashboard';
  static const techRequests = '/t/requests';
  static const techAgenda = '/t/agenda';
  static const techParts = '/t/parts';
  static const techBusiness = '/t/business';

  static String technician(String id) => '/technician/$id';
  static String requestQuote({String? technicianId, String? category}) =>
      Uri(path: '/quote/new', queryParameters: {
        if (technicianId != null) 'tech': technicianId,
        if (category != null) 'cat': category,
      }).toString();
  static String schedule(String technicianId) => '/schedule/$technicianId';
  static String order(String id) => '/order/$id';
  static String chatWithTechnician(String technicianId) =>
      '/chat/new/$technicianId';
  static String chatRoom(String conversationId) => '/chat/$conversationId';
  static String compareQuotes(String requestId) => '/quote/$requestId/quotes';
  static const appointmentSuccess = '/appointment/success';
  static const conversations = '/messages';
  static const notifications = '/notifications';

  // Técnico
  static const techOnboarding = '/tech-onboarding';
  static const verification = '/business/verification';
  static const businessEdit = '/business/edit';
  static const businessSchedule = '/business/schedule';
  static const businessServices = '/business/services';
  static const businessReviews = '/business/reviews';
  static const subscription = '/business/subscription';
  static const wallet = '/business/wallet';
  static const cart = '/parts/cart';

  // Cuenta del cliente
  static const myDevices = '/account/devices';
  static const addresses = '/account/addresses';
  static const paymentMethods = '/account/payment-methods';
  static const favorites = '/account/favorites';
  static const support = '/account/support';
  static String dispute(String id) => '/account/support/$id';
}

/// Notifica a GoRouter cuando cambia la sesión para re-evaluar redirect.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    ref.listen<SessionState>(sessionProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _SessionListenable(ref);
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: listenable,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final loc = state.matchedLocation;
      final inAuth = loc == Routes.login ||
          loc == Routes.otp ||
          loc == Routes.register;

      switch (session.status) {
        case SessionStatus.unknown:
          return loc == Routes.splash ? null : Routes.splash;
        case SessionStatus.unauthenticated:
          return inAuth ? null : Routes.login;
        case SessionStatus.authenticated:
          final isTech = session.user?.activeRole == UserRole.technician;
          final home = isTech ? Routes.techDashboard : Routes.clientHome;
          if (inAuth || loc == Routes.splash) return home;
          if (isTech && loc == Routes.techOnboarding) return home;
          if (isTech && loc.startsWith('/c/')) return home;
          if (!isTech && loc.startsWith('/t/')) return home;
          return null;
      }
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: Routes.otp,
        builder: (_, state) => OtpScreen(args: state.extra as OtpArgs),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, state) =>
            RegisterScreen(initialRole: state.extra as UserRole?),
      ),

      // ---------- Modo cliente ----------
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ClientShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.clientHome,
                builder: (_, __) => const ClientHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.clientSearch,
              builder: (_, state) => SearchScreen(
                  initialCategory: state.uri.queryParameters['cat']),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.clientOrders,
                builder: (_, __) => const OrdersListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.clientMessages,
                builder: (_, __) => const ConversationsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.clientProfile,
                builder: (_, __) => const ClientProfileScreen()),
          ]),
        ],
      ),

      // ---------- Modo técnico ----------
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => TechnicianShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.techDashboard,
                builder: (_, __) => const TechnicianDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.techRequests,
                builder: (_, __) => const TechnicianRequestsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.techAgenda,
                builder: (_, __) => const TechnicianAgendaScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.techParts,
                builder: (_, __) => const PartsCatalogScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.techBusiness,
                builder: (_, __) => const BusinessProfileScreen()),
          ]),
        ],
      ),

      // ---------- Pantallas completas ----------
      GoRoute(
        path: '/technician/:id',
        builder: (_, state) =>
            TechnicianProfileScreen(technicianId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/quote/new',
        builder: (_, state) => RequestQuoteScreen(
          technicianId: state.uri.queryParameters['tech'],
          category: state.uri.queryParameters['cat'],
        ),
      ),
      GoRoute(
        path: '/quote/:id/quotes',
        builder: (_, state) =>
            CompareQuotesScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/schedule/:techId',
        builder: (_, state) => ScheduleAppointmentScreen(
            technicianId: state.pathParameters['techId']!),
      ),
      GoRoute(
        path: Routes.appointmentSuccess,
        builder: (_, state) => AppointmentSuccessScreen(
            summary: state.extra as AppointmentSummary),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          // Misma ruta para ambos modos: el técnico ve la vista de ejecución.
          return ref.read(sessionProvider).isClientMode
              ? OrderDetailScreen(orderId: id)
              : OrderExecutionScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/chat/new/:techId',
        builder: (_, state) =>
            StartChatScreen(technicianId: state.pathParameters['techId']!),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) => ChatRoomScreen(
          conversationId: state.pathParameters['id']!,
          conversation: state.extra as ConversationModel?,
        ),
      ),
      GoRoute(
        path: Routes.conversations,
        builder: (_, __) => const ConversationsScreen(standalone: true),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
          path: Routes.techOnboarding,
          builder: (_, __) => const TechnicianOnboardingScreen()),
      GoRoute(
          path: Routes.verification,
          builder: (_, __) => const VerificationScreen()),
      GoRoute(
          path: Routes.businessEdit,
          builder: (_, __) => const BusinessEditScreen()),
      GoRoute(
          path: Routes.businessSchedule,
          builder: (_, __) => const ScheduleEditScreen()),
      GoRoute(
          path: Routes.businessServices,
          builder: (_, __) => const ServicesScreen()),
      GoRoute(
          path: Routes.businessReviews,
          builder: (_, __) => const ReviewsReceivedScreen()),
      GoRoute(
          path: Routes.subscription,
          builder: (_, __) => const SubscriptionPlansScreen()),
      GoRoute(path: Routes.wallet, builder: (_, __) => const WalletScreen()),
      GoRoute(path: Routes.cart, builder: (_, __) => const CartScreen()),
      GoRoute(
          path: Routes.myDevices, builder: (_, __) => const MyDevicesScreen()),
      GoRoute(
          path: Routes.addresses, builder: (_, __) => const AddressesScreen()),
      GoRoute(
          path: Routes.paymentMethods,
          builder: (_, __) => const PaymentMethodsScreen()),
      GoRoute(
          path: Routes.favorites, builder: (_, __) => const FavoritesScreen()),
      GoRoute(path: Routes.support, builder: (_, __) => const SupportScreen()),
      GoRoute(
        path: '/account/support/:id',
        builder: (_, state) =>
            DisputeDetailScreen(disputeId: state.pathParameters['id']!),
      ),
    ],
  );
});
