import 'package:flutter_test/flutter_test.dart';
import 'package:sr_robot_app/core/utils/validators.dart';
import 'package:sr_robot_app/shared/data/supplier_repository.dart';
import 'package:sr_robot_app/shared/models/business_models.dart';
import 'package:sr_robot_app/shared/models/order_model.dart';
import 'package:sr_robot_app/shared/models/quote_model.dart';
import 'package:sr_robot_app/shared/models/technician_model.dart';
import 'package:sr_robot_app/shared/models/user_model.dart';

void main() {
  group('Validators', () {
    test('correo y celular', () {
      expect(Validators.isEmail('cliente@srrobot.com'), isTrue);
      expect(Validators.isEmail('cliente@'), isFalse);
      expect(Validators.isPhone('300 123 4567'), isTrue);
      expect(Validators.isPhone('12'), isFalse);
      expect(Validators.isOtp('123456'), isTrue);
      expect(Validators.isOtp('12a456'), isFalse);
    });
  });

  group('Modelos desde el JSON de API.md', () {
    test('usuario con doble rol', () {
      final u = UserModel.fromJson({
        'id': 1,
        'name': 'Juan Pérez',
        'roles': ['CLIENT', 'TECHNICIAN'],
        'role': 'CLIENT',
      });
      expect(u.id, '1');
      expect(u.initials, 'JP');
      expect(u.hasTechnicianRole, isTrue);
      expect(u.activeRole, UserRole.client);
    });

    test('técnico público con servicios y distribución', () {
      final t = TechnicianModel.fromJson({
        'id': 1,
        'businessName': 'Carlos Fix Tech',
        'categories': ['Smartphones', 'Laptops'],
        'rating': 4.8,
        'isVerified': true,
        'location': {'lat': 4.6, 'lng': -74.08, 'city': 'Bogotá'},
        'homeExtraFee': 15000,
        'services': [
          {'id': 1, 'name': 'Pantalla', 'priceFrom': 180000, 'active': true},
          {'id': 2, 'name': 'Batería', 'priceFrom': 90000, 'active': true},
          {'id': 3, 'name': 'Viejo', 'priceFrom': 1000, 'active': false},
        ],
        'ratingDistribution': {'5': 10, '4': 2},
      });
      expect(t.minPrice, 90000);
      expect(t.canQuote, isTrue);
      expect(t.city, 'Bogotá');
      expect(t.ratingDistribution[5], 10);
    });

    test('orden con desglose, ajuste pendiente y timeline', () {
      final o = OrderModel.fromJson({
        'id': 7,
        'state': 'DIAGNOSTICO',
        'amount': 195000,
        'paymentBreakdown': {'service': 180000, 'homeFee': 15000, 'total': 195000},
        'pendingAdjustment': {'id': 3, 'amount': 35000, 'reason': 'Flex', 'status': 'PENDING'},
        'timeline': [
          {'state': 'SOLICITADO', 'note': 'Orden creada', 'media': [], 'timestamp': '2026-11-16T18:30:00Z'},
        ],
        'warranty': {'days': 90, 'active': false},
      });
      expect(o.state, OrderState.diagnostico);
      expect(o.state.step, 1);
      expect(o.homeFee, 15000);
      expect(o.pendingAdjustment?.amount, 35000);
      expect(o.timeline.single.state, OrderState.solicitado);
      expect(o.isActive, isTrue);
    });

    test('cotización con etiquetas calculadas', () {
      final q = QuoteModel.fromJson({
        'id': 5,
        'price': 150000,
        'tags': ['BEST_PRICE', 'FASTEST'],
      });
      expect(q.isBestPrice, isTrue);
      expect(q.isFastest, isTrue);
      expect(q.isBestRated, isFalse);
    });

    test('métricas del técnico normalizan la conversión', () {
      final a = TechnicianAnalytics.fromJson({
        'totalRevenue': 500000,
        'conversionRate': 0.42,
        'weeklyRevenue': [
          {'weekStart': '2026-11-02', 'revenue': 100000},
        ],
      });
      expect(a.conversionRate, closeTo(42, 0.001));
      expect(a.weekly.single.revenue, 100000);
    });
  });

  group('Carrito B2B', () {
    ProductModel p(String id, int price, {int stock = 10}) => ProductModel(
        id: id,
        name: 'P$id',
        category: 'X',
        listPrice: price,
        discount: 0,
        price: price,
        stock: stock);

    test('envío gratis desde \$200.000', () {
      final cart = CartNotifier();
      cart.add(p('1', 150000));
      expect(cart.shipping, SupplierRules.shippingCost);
      cart.add(p('2', 60000));
      expect(cart.subtotal, 210000);
      expect(cart.shipping, 0);
      expect(cart.count, 2);
    });

    test('no supera el stock y quita en cero', () {
      final cart = CartNotifier();
      final prod = p('1', 1000, stock: 1);
      cart.add(prod);
      cart.add(prod);
      expect(cart.count, 1);
      cart.remove(prod);
      expect(cart.count, 0);
    });
  });
}
