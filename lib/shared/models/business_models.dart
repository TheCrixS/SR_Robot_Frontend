import 'json_utils.dart';

class WeeklyRevenue {
  final DateTime? weekStart;
  final int revenue;
  const WeeklyRevenue(this.weekStart, this.revenue);
}

class TechnicianAnalytics {
  final int totalRevenue;
  final double revenueChangePct;
  final List<WeeklyRevenue> weekly;
  final int completedOrders;
  final int profileViews;
  final int requestsReceived;
  final int quotesSent;
  final int quotesAccepted;
  final double conversionRate;
  final double rating;
  final String plan;

  const TechnicianAnalytics({
    required this.totalRevenue,
    required this.revenueChangePct,
    required this.weekly,
    required this.completedOrders,
    required this.profileViews,
    required this.requestsReceived,
    required this.quotesSent,
    required this.quotesAccepted,
    required this.conversionRate,
    required this.rating,
    required this.plan,
  });

  factory TechnicianAnalytics.fromJson(Map<String, dynamic> j) {
    var conv = asDouble(j['conversionRate']);
    if (conv > 0 && conv <= 1) conv *= 100; // fracción → porcentaje
    return TechnicianAnalytics(
      totalRevenue: asInt(j['totalRevenue']),
      revenueChangePct: asDouble(j['revenueChangePct']),
      weekly: [
        for (final w in asMapList(j['weeklyRevenue']))
          WeeklyRevenue(asDate(w['weekStart']), asInt(w['revenue'])),
      ],
      completedOrders: asInt(j['completedOrders']),
      profileViews: asInt(j['profileViews']),
      requestsReceived: asInt(j['requestsReceived']),
      quotesSent: asInt(j['quotesSent']),
      quotesAccepted: asInt(j['quotesAccepted']),
      conversionRate: conv,
      rating: asDouble(j['rating']),
      plan: asStr(j['plan']) ?? 'BASIC',
    );
  }
}

class AppointmentModel {
  final String id;
  final String? orderId;
  final String clientName;
  final String serviceName;
  final String date;
  final String time;
  final bool isHome;
  final String status;
  final String? address;
  final String? notes;
  final String? orderState;

  const AppointmentModel({
    required this.id,
    required this.clientName,
    required this.serviceName,
    required this.date,
    required this.time,
    required this.isHome,
    required this.status,
    this.orderId,
    this.address,
    this.notes,
    this.orderState,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> j) {
    final order = asMap(j['order']);
    final service = asMap(j['service']);
    final client = asMap(j['client']);
    return AppointmentModel(
      id: asId(j['id']),
      orderId: asStr(j['orderId']) ?? asStr(order['id']),
      clientName: asStr(j['clientName']) ?? asStr(client['name']) ?? '',
      serviceName: asStr(j['serviceName']) ?? asStr(service['name']) ?? '',
      date: asStr(j['date']) ?? '',
      time: asStr(j['time']) ?? '',
      isHome: asStr(j['mode']) == 'HOME' || asBool(j['isHomeService']),
      status: asStr(j['status']) ?? 'CONFIRMED',
      address: asStr(j['address']),
      notes: asStr(j['notes']),
      orderState: asStr(j['orderState']) ?? asStr(order['state']),
    );
  }
}

class WalletModel {
  final int held;
  final int available;
  final int withdrawn;
  const WalletModel(this.held, this.available, this.withdrawn);

  factory WalletModel.fromJson(Map<String, dynamic> j) => WalletModel(
      asInt(j['held']), asInt(j['available']), asInt(j['withdrawn']));
}

class LedgerEntry {
  final String id;
  final String type;
  final int amount;
  final String? orderId;
  final String? note;
  final DateTime? createdAt;

  const LedgerEntry(
      this.id, this.type, this.amount, this.orderId, this.note, this.createdAt);

  factory LedgerEntry.fromJson(Map<String, dynamic> j) => LedgerEntry(
        asId(j['id']),
        asStr(j['type']) ?? '',
        asInt(j['amount']),
        asStr(j['orderId']),
        asStr(j['note']),
        asDate(j['createdAt']),
      );
}

class PlanModel {
  final String code;
  final String name;
  final int price;
  final int? maxQuotes;
  final double discountSpareParts;
  final List<String> features;

  const PlanModel({
    required this.code,
    required this.name,
    required this.price,
    required this.discountSpareParts,
    required this.features,
    this.maxQuotes,
  });

  factory PlanModel.fromJson(Map<String, dynamic> j) {
    var disc = asDouble(j['discountSpareParts']);
    if (disc > 1) disc /= 100;
    return PlanModel(
      code: asStr(j['code']) ?? '',
      name: asStr(j['name']) ?? '',
      price: asInt(j['price']),
      maxQuotes: j['maxQuotes'] == null ? null : asInt(j['maxQuotes']),
      discountSpareParts: disc,
      features: asStrList(j['features']),
    );
  }
}

class MySubscription {
  final String plan;
  final DateTime? nextBillingDate;
  final bool cancelAtPeriodEnd;
  const MySubscription(this.plan, this.nextBillingDate, this.cancelAtPeriodEnd);

  factory MySubscription.fromJson(Map<String, dynamic> j) {
    final sub = asMap(j['subscription']);
    return MySubscription(
      asStr(j['plan']) ?? asStr(sub['plan']) ?? 'BASIC',
      asDate(sub['nextBillingDate'] ?? j['nextBillingDate']),
      asBool(sub['cancelAtPeriodEnd']) || asStr(sub['status']) == 'CANCELLED',
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String category;
  final String? description;
  final int listPrice;
  final double discount;
  final int price;
  final int stock;
  final String? supplierName;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.listPrice,
    required this.discount,
    required this.price,
    required this.stock,
    this.description,
    this.supplierName,
  });

  bool get hasDiscount => price < listPrice;

  factory ProductModel.fromJson(Map<String, dynamic> j) {
    final price = asInt(j['price']);
    var disc = asDouble(j['discount']);
    if (disc > 1) disc /= 100;
    return ProductModel(
      id: asId(j['id']),
      name: asStr(j['name']) ?? '',
      category: asStr(j['category']) ?? '',
      description: asStr(j['description']),
      listPrice: asInt(j['listPrice'], price),
      discount: disc,
      price: price,
      stock: asInt(j['stock']),
      supplierName:
          asStr(j['supplierName']) ?? asStr(asMap(j['supplier'])['name']),
    );
  }
}
