/// Rutas REST relativas a `/api/v1` (ver API.md).
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const otp = '/auth/otp';
  static const verifyOtp = '/auth/verify';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';
  static const me = '/auth/me';
  static const switchMode = '/auth/switch-mode';

  // Configuración
  static const categories = '/config/categories';
  static String country(String code) => '/config/countries/$code';

  // Técnicos
  static const technicians = '/technicians';
  static String technician(Object id) => '/technicians/$id';
  static String availability(Object id) => '/technicians/$id/availability';
  static String technicianReviews(Object id) => '/technicians/$id/reviews';
  static const myBusiness = '/technicians/me';
  static const mySchedule = '/technicians/me/schedule';
  static const myServices = '/technicians/me/services';
  static const myWallet = '/technicians/me/wallet';
  static const myLedger = '/technicians/me/ledger';
  static const myWithdrawals = '/technicians/me/withdrawals';
  static const myAnalytics = '/technicians/me/analytics';

  // Cotizaciones
  static const quoteRequests = '/quote-requests';
  static const myQuoteRequests = '/quote-requests/mine';
  static const receivedQuoteRequests = '/quote-requests/received';
  static String quoteRequest(Object id) => '/quote-requests/$id';
  static String quotes(Object requestId) => '/quote-requests/$requestId/quotes';
  static String rejectRequest(Object id) => '/quote-requests/$id/reject';
  static String acceptQuote(Object requestId, Object quoteId) =>
      '/quote-requests/$requestId/quotes/$quoteId/accept';

  // Citas
  static const appointments = '/appointments';

  // Órdenes
  static const orders = '/orders';
  static String order(Object id) => '/orders/$id';
  static String transitions(Object id) => '/orders/$id/transitions';
  static String confirmReceipt(Object id) => '/orders/$id/confirm-receipt';
  static String adjustments(Object id) => '/orders/$id/adjustments';
  static String approveAdjustment(Object id, Object adj) =>
      '/orders/$id/adjustments/$adj/approve';
  static String rejectAdjustment(Object id, Object adj) =>
      '/orders/$id/adjustments/$adj/reject';
  static String reviews(Object id) => '/orders/$id/reviews';
  static String evidence(Object id) => '/orders/$id/evidence';

  // Chat
  static const conversations = '/chat/conversations';
  static String messages(Object id) => '/chat/conversations/$id/messages';

  // Notificaciones
  static const notifications = '/notifications';
  static const notificationsReadAll = '/notifications/read-all';

  // Cliente
  static const favorites = '/client/favorites';
  static const equipments = '/client/equipments';
  static const addresses = '/client/addresses';
  static const clientPaymentMethods = '/client/payment-methods';
  static const warranties = '/client/warranties';

  // Disputas
  static const disputes = '/disputes';
  static String orderDisputes(Object id) => '/orders/$id/disputes';

  // Pagos, suscripciones, proveedores
  static const paymentMethods = '/payments/methods';
  static const plans = '/subscriptions/plans';
  static const mySubscription = '/subscriptions/me';
  static const supplierProducts = '/supplier/products';
  static const supplierOrders = '/supplier/orders';
}
