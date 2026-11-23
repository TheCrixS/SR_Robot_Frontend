import 'package:dio/dio.dart';

/// Backend simulado en memoria con el mismo contrato que API.md.
/// Permite usar toda la app (cliente y técnico) sin servidor.
/// Los datos se reinician al cerrar la app.
class MockBackend {
  MockBackend._() {
    _seed();
  }
  static final MockBackend instance = MockBackend._();

  // ------------------------------------------------------------------ estado
  int _seq = 100;
  int _nextId() => ++_seq;
  String _now([Duration offset = Duration.zero]) =>
      DateTime.now().toUtc().add(offset).toIso8601String();
  String _day(int plusDays) {
    final d = DateTime.now().add(Duration(days: plusDays));
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  final Map<int, Map<String, dynamic>> _users = {};
  int _currentUser = 1;
  String _activeRole = 'CLIENT';

  final Map<int, Map<String, dynamic>> _techs = {};
  final Map<int, Map<String, dynamic>> _orders = {};
  final Map<int, Map<String, dynamic>> _requests = {};
  final Map<int, Map<String, dynamic>> _quotes = {};
  final Map<int, Map<String, dynamic>> _appointments = {};
  final Map<int, Map<String, dynamic>> _conversations = {};
  final Map<int, List<Map<String, dynamic>>> _messages = {};
  final List<Map<String, dynamic>> _notifications = [];
  final Map<int, Map<String, dynamic>> _products = {};
  final Map<int, Map<String, dynamic>> _equipments = {};
  final Map<int, Map<String, dynamic>> _addresses = {};
  final Map<int, Map<String, dynamic>> _payMethods = {};
  final Set<int> _favorites = {};
  final Map<int, Map<String, dynamic>> _disputes = {};
  final Map<int, Map<String, dynamic>> _reviews = {};
  final List<Map<String, dynamic>> _ledger = [];
  Map<String, int> _wallet = {'held': 195000, 'available': 320000, 'withdrawn': 150000};
  String _plan = 'PRO';
  String _subscriptionStatus = 'ACTIVE';

  static const _categories = [
    'Smartphones', 'Laptops', 'Tablets', 'Consolas',
    'Televisores', 'Electrodomésticos', 'Audio', 'Cámaras',
  ];

  static const _plans = [
    {'code': 'BASIC', 'name': 'Básico', 'price': 0, 'maxQuotes': 10, 'discountSpareParts': 0, 'features': ['Perfil público', 'Agenda de citas']},
    {'code': 'PRO', 'name': 'Pro', 'price': 49900, 'maxQuotes': 0, 'discountSpareParts': 0.10, 'features': ['Insignia destacada', 'Métricas avanzadas']},
    {'code': 'PREMIUM', 'name': 'Premium', 'price': 99900, 'maxQuotes': 0, 'discountSpareParts': 0.15, 'features': ['Primero en búsquedas', 'Multiusuario']},
  ];

  int get _myTechId => 1; // el técnico de prueba es el negocio #1

  /// Países activos (como `GET /config/countries` del backend real).
  /// `screen` = precio de referencia de un cambio de pantalla en unidad mínima.
  static const _countries = <Map<String, dynamic>>[
    {'code': 'CO', 'name': 'Colombia', 'locale': 'es-CO', 'currency': 'COP', 'minorUnits': 0, 'phonePrefix': '+57', 'paymentMethods': ['NEQUI', 'DAVIPLATA', 'CARD', 'CASH'], 'dataRegion': 'LATAM', 'privacyLaw': 'Ley 1581 de 2012', 'city': 'Bogotá', 'lat': 4.6486, 'lng': -74.0628, 'screen': 180000},
    {'code': 'MX', 'name': 'México', 'locale': 'es-MX', 'currency': 'MXN', 'minorUnits': 2, 'phonePrefix': '+52', 'paymentMethods': ['MERCADO_PAGO', 'SPEI', 'OXXO', 'CODI', 'CARD', 'CASH'], 'dataRegion': 'LATAM', 'privacyLaw': 'LFPDPPP', 'city': 'Ciudad de México', 'lat': 19.4326, 'lng': -99.1332, 'screen': 180000},
    {'code': 'AR', 'name': 'Argentina', 'locale': 'es-AR', 'currency': 'ARS', 'minorUnits': 2, 'phonePrefix': '+54', 'paymentMethods': ['MERCADO_PAGO', 'TRANSFERENCIA_3', 'CARD', 'CASH'], 'dataRegion': 'LATAM', 'privacyLaw': 'Ley 25.326', 'city': 'Buenos Aires', 'lat': -34.6037, 'lng': -58.3816, 'screen': 12000000},
    {'code': 'CL', 'name': 'Chile', 'locale': 'es-CL', 'currency': 'CLP', 'minorUnits': 0, 'phonePrefix': '+56', 'paymentMethods': ['WEBPAY', 'TRANSFERENCIA', 'CARD', 'CASH'], 'dataRegion': 'LATAM', 'privacyLaw': 'Ley 19.628', 'city': 'Santiago', 'lat': -33.4489, 'lng': -70.6693, 'screen': 90000},
    {'code': 'PE', 'name': 'Perú', 'locale': 'es-PE', 'currency': 'PEN', 'minorUnits': 2, 'phonePrefix': '+51', 'paymentMethods': ['YAPE', 'PLIN', 'PAGOEFECTIVO', 'CARD', 'CASH'], 'dataRegion': 'LATAM', 'privacyLaw': 'Ley 29733', 'city': 'Lima', 'lat': -12.0464, 'lng': -77.0428, 'screen': 35000},
    {'code': 'BR', 'name': 'Brasil', 'locale': 'pt-BR', 'currency': 'BRL', 'minorUnits': 2, 'phonePrefix': '+55', 'paymentMethods': ['PIX', 'CARD'], 'dataRegion': 'LATAM', 'privacyLaw': 'LGPD', 'city': 'São Paulo', 'lat': -23.5505, 'lng': -46.6333, 'screen': 45000},
    {'code': 'US', 'name': 'Estados Unidos', 'locale': 'en-US', 'currency': 'USD', 'minorUnits': 2, 'phonePrefix': '+1', 'paymentMethods': ['APPLE_PAY', 'CARD', 'STRIPE', 'VENMO'], 'dataRegion': 'US', 'privacyLaw': 'CCPA', 'city': 'Miami', 'lat': 25.7617, 'lng': -80.1918, 'screen': 15000},
    {'code': 'ES', 'name': 'España', 'locale': 'es-ES', 'currency': 'EUR', 'minorUnits': 2, 'phonePrefix': '+34', 'paymentMethods': ['BIZUM', 'CARD', 'STRIPE'], 'dataRegion': 'EU', 'privacyLaw': 'RGPD', 'city': 'Madrid', 'lat': 40.4168, 'lng': -3.7038, 'screen': 12000},
    {'code': 'DE', 'name': 'Alemania', 'locale': 'de-DE', 'currency': 'EUR', 'minorUnits': 2, 'phonePrefix': '+49', 'paymentMethods': ['PAYPAL', 'SEPA_DIRECT_DEBIT', 'KLARNA'], 'dataRegion': 'EU', 'privacyLaw': 'DSGVO', 'city': 'Berlín', 'lat': 52.5200, 'lng': 13.4050, 'screen': 13000},
  ];

  Map<String, dynamic> _country(String? code) =>
      _countries.firstWhere((c) => c['code'] == code, orElse: () => _countries.first);

  Map<String, dynamic> _countryPublic(Map<String, dynamic> c) => {
        for (final k in ['code', 'name', 'locale', 'currency', 'minorUnits', 'phonePrefix', 'paymentMethods', 'dataRegion', 'privacyLaw'])
          k: c[k],
      };

  String get _myCountry => '${_users[_currentUser]?['country'] ?? 'CO'}';

  // -------------------------------------------------------------- semillas
  void _seed() {
    _users[1] = {
      'id': 1, 'name': 'Juan Cliente', 'email': 'cliente@srrobot.com',
      'phone': '+573001112233', 'roles': ['CLIENT'], 'country': 'CO', 'locale': 'es-CO',
    };
    _users[2] = {
      'id': 2, 'name': 'Carlos Rodríguez', 'email': 'tecnico@srrobot.com',
      'phone': '+573004445566', 'roles': ['CLIENT', 'TECHNICIAN'], 'country': 'CO', 'locale': 'es-CO',
    };

    Map<String, dynamic> sched(String open, String close, {bool sat = true}) => {
          for (final d in ['mon', 'tue', 'wed', 'thu', 'fri'])
            d: {'enabled': true, 'open': open, 'close': close},
          'sat': {'enabled': sat, 'open': '09:00', 'close': '13:00'},
          'sun': {'enabled': false, 'open': '09:00', 'close': '13:00'},
        };

    final seedTechs = [
      (1, 'Carlos Fix Tech', ['Smartphones', 'Tablets'], 4.8, 0.012, -0.004, true, 15000, 'PRO'),
      (2, 'LapCenter Chapinero', ['Laptops', 'Consolas'], 4.6, -0.010, 0.006, false, 0, 'BASIC'),
      (3, 'TecnoHogar Express', ['Electrodomésticos', 'Televisores'], 4.9, 0.020, 0.012, true, 20000, 'PREMIUM'),
      (4, 'Audio & Cámaras Pro', ['Audio', 'Cámaras'], 4.4, -0.018, -0.015, true, 12000, 'BASIC'),
      (5, 'Game Doctor', ['Consolas', 'Smartphones'], 4.7, 0.005, 0.020, false, 0, 'PRO'),
    ];
    var svc = 1;
    for (final (id, name, cats, rating, dLat, dLng, home, fee, plan) in seedTechs) {
      _techs[id] = {
        'id': id, 'userId': id == 1 ? 2 : 50 + id, 'businessName': name,
        'description': 'Taller con más de 8 años reparando ${cats.join(' y ').toLowerCase()}. Repuestos originales y garantía por escrito.',
        'category': cats.first, 'categories': cats, 'rating': rating, 'reviewsCount': 0,
        'isVerified': true, 'verificationStatus': 'VERIFIED', 'plan': plan,
        'location': {'lat': 4.6486 + dLat, 'lng': -74.0628 + dLng, 'address': 'Calle ${50 + id} # ${10 + id}-2$id', 'city': 'Bogotá'},
        'homeService': home, 'homeExtraFee': fee, 'coverageRadiusKm': home ? 12 : 0,
        'available': true, 'responseTime': 'en menos de 1 hora',
        'schedule': sched('08:00', '18:00', sat: id != 2), 'photos': <String>[],
        'completedOrders': 20 + id * 7, 'country': 'CO', 'currency': 'COP',
        'services': [
          {'id': svc++, 'name': 'Diagnóstico general', 'priceFrom': 30000, 'estimatedTime': '30 min', 'estimatedHours': 1, 'warrantyDays': 30, 'active': true},
          {'id': svc++, 'name': cats.first == 'Smartphones' ? 'Cambio de pantalla' : 'Reparación de tarjeta', 'priceFrom': 180000, 'estimatedTime': '2 horas', 'estimatedHours': 2, 'warrantyDays': 90, 'active': true},
          {'id': svc++, 'name': cats.first == 'Smartphones' ? 'Cambio de batería' : 'Mantenimiento preventivo', 'priceFrom': 90000, 'estimatedTime': '1 hora', 'estimatedHours': 1, 'warrantyDays': 60, 'active': true},
        ],
      };
    }

    // Dos talleres por cada otro país, con precios en su moneda (unidad mínima).
    var nextTech = 6;
    for (final c in _countries.where((c) => c['code'] != 'CO')) {
      final screen = c['screen'] as int;
      final city = c['city'] as String;
      for (final (name, cats, rating, dLat, dLng, plan) in [
        ('TecnoFix $city', ['Smartphones', 'Tablets'], 4.7, 0.010, -0.006, 'PRO'),
        ('Hogar Service $city', ['Electrodomésticos', 'Televisores', 'Laptops'], 4.5, -0.012, 0.009, 'BASIC'),
      ]) {
        final id = nextTech++;
        _techs[id] = {
          'id': id, 'userId': 50 + id, 'businessName': name,
          'description': 'Servicio técnico en $city: ${cats.join(', ').toLowerCase()}.',
          'category': cats.first, 'categories': cats, 'rating': rating, 'reviewsCount': 0,
          'isVerified': true, 'verificationStatus': 'VERIFIED', 'plan': plan,
          'location': {'lat': (c['lat'] as double) + dLat, 'lng': (c['lng'] as double) + dLng, 'address': 'Centro, $city', 'city': city},
          'homeService': true, 'homeExtraFee': screen ~/ 12, 'coverageRadiusKm': 10,
          'available': true, 'responseTime': 'en menos de 2 horas',
          'schedule': sched('09:00', '18:00'), 'photos': <String>[],
          'completedOrders': 10 + id, 'country': c['code'], 'currency': c['currency'],
          'services': [
            {'id': svc++, 'name': 'Diagnóstico general', 'priceFrom': screen ~/ 6, 'estimatedTime': '30 min', 'estimatedHours': 1, 'warrantyDays': 30, 'active': true},
            {'id': svc++, 'name': cats.first == 'Smartphones' ? 'Cambio de pantalla' : 'Reparación de tarjeta', 'priceFrom': screen, 'estimatedTime': '2 horas', 'estimatedHours': 2, 'warrantyDays': 90, 'active': true},
            {'id': svc++, 'name': cats.first == 'Smartphones' ? 'Cambio de batería' : 'Mantenimiento preventivo', 'priceFrom': screen ~/ 2, 'estimatedTime': '1 hora', 'estimatedHours': 1, 'warrantyDays': 60, 'active': true},
          ],
        };
      }
    }

    // Reseñas
    final reviewSeed = [
      (1, 'Laura M.', 5, ['Puntual', 'Excelente trabajo'], 'Me cambió la pantalla en una hora. Quedó perfecto.'),
      (1, 'Andrés P.', 4, ['Precio justo'], 'Buen servicio, un poco de espera.'),
      (3, 'Marta G.', 5, ['Amable', 'Ordenado'], 'Vino a la casa y arregló la nevera el mismo día.'),
      (2, 'Felipe R.', 5, ['Rápido'], 'El portátil quedó como nuevo.'),
    ];
    for (final (tech, client, rating, tags, comment) in reviewSeed) {
      final id = _nextId();
      _reviews[id] = {
        'id': id, 'orderId': null, 'technicianId': tech, 'clientName': client,
        'rating': rating, 'tags': tags, 'comment': comment, 'hidden': false,
        'reply': tech == 1 && rating == 4
            ? {'text': '¡Gracias Andrés! Ya ampliamos el horario para atender más rápido.', 'repliedAt': _now()}
            : null,
        'createdAt': _now(Duration(days: -id % 20)),
      };
    }
    _recalcRatings();

    // Órdenes del cliente 1 con el técnico 1
    _orders[7] = _newOrder(id: 7, clientId: 1, techId: 1, service: 'Cambio de pantalla',
        base: 180000, home: true, state: 'EN_REPARACION', source: 'APPOINTMENT');
    _orders[3] = _newOrder(id: 3, clientId: 1, techId: 3, service: 'Mantenimiento preventivo',
        base: 90000, home: true, state: 'ENTREGADO', source: 'DIRECT', daysAgo: 20);
    _orders[8] = _newOrder(id: 8, clientId: 1, techId: 1, service: 'Cambio de batería',
        base: 90000, home: false, state: 'SOLICITADO', source: 'APPOINTMENT');

    _appointments[1] = {
      'id': 1, 'orderId': 8, 'technicianId': 1, 'clientId': 1, 'clientName': 'Juan Cliente',
      'serviceId': 3, 'serviceName': 'Cambio de batería', 'date': _day(0), 'time': '15:00',
      'mode': 'LOCAL', 'status': 'CONFIRMED', 'notes': 'Traigo el cargador',
    };
    _appointments[2] = {
      'id': 2, 'orderId': 7, 'technicianId': 1, 'clientId': 1, 'clientName': 'Juan Cliente',
      'serviceId': 2, 'serviceName': 'Cambio de pantalla', 'date': _day(0), 'time': '10:00',
      'mode': 'HOME', 'address': 'Cra 7 # 45-12', 'status': 'IN_PROGRESS',
    };

    // Solicitud abierta con dos ofertas
    _requests[1] = {
      'id': 1, 'clientId': 1, 'clientName': 'Juan Cliente', 'deviceType': 'Laptops',
      'brandModel': 'Lenovo IdeaPad 3', 'issueDescription': 'No enciende. Está lento',
      'urgency': 'NORMAL', 'isHomeService': false, 'address': null,
      'status': 'OPEN', 'matchedTechnicianIds': [1, 2, 5], 'targetTechnicianId': null,
      'media': <Map<String, dynamic>>[], 'expiresAt': _now(const Duration(hours: 20)),
      'createdAt': _now(const Duration(hours: -4)), 'rejectedBy': <int>[],
    };
    _addQuote(1, 2, 160000, '1 día', 24, 90, 'Puede ser la fuente; incluye diagnóstico.');
    _addQuote(1, 5, 145000, '2 días', 48, 60, null);

    // Chat
    _conversations[1] = {'id': 1, 'clientId': 1, 'technicianId': 1, 'technicianUserId': 2, 'lastMessageAt': _now(const Duration(minutes: -30))};
    _messages[1] = [
      _msg(1, 1, 'Hola Carlos, ¿cómo va mi celular?', const Duration(hours: -2)),
      _msg(1, 2, 'Hola Juan, ya desmonté el equipo. Hoy en la tarde queda listo.', const Duration(hours: -1)),
      _msg(1, 2, 'Te aviso cuando pase a pruebas de calidad.', const Duration(minutes: -30)),
    ];

    // Notificaciones
    _notify(1, 'Tu reparación avanzó', 'Carlos Fix Tech pasó tu orden a "En reparación".', 'ORDER', {'orderId': 7});
    _notify(1, 'Nueva cotización', 'LapCenter Chapinero cotizó tu Lenovo IdeaPad 3.', 'QUOTE', {'requestId': 1});
    _notify(2, 'Nueva solicitud cerca', 'Un cliente necesita reparar un Lenovo IdeaPad 3.', 'QUOTE', {'requestId': 1});

    // Repuestos
    final parts = [
      ('Pantalla iPhone 12 OLED', 'Pantallas', 260000, 8),
      ('Pantalla Samsung A54', 'Pantallas', 190000, 5),
      ('Batería iPhone 11', 'Baterías', 85000, 20),
      ('Batería Xiaomi Redmi Note 10', 'Baterías', 60000, 0),
      ('Flex de carga USB-C universal', 'Flex y conectores', 18000, 40),
      ('Teclado Lenovo IdeaPad 3', 'Laptops', 120000, 6),
      ('Pasta térmica Arctic MX-4', 'Insumos', 35000, 30),
      ('Joystick PS5 (repuesto)', 'Consolas', 45000, 12),
    ];
    for (final (name, cat, price, stock) in parts) {
      final id = _nextId();
      _products[id] = {'id': id, 'name': name, 'category': cat, 'price': price, 'stock': stock, 'supplierName': 'Repuestos Colombia SAS', 'active': true};
    }

    // Cuenta del cliente
    _equipments[1] = {'id': 1, 'type': 'Smartphones', 'brand': 'Samsung', 'model': 'A54', 'nickname': 'Mi celular', 'purchaseDate': '2024-03-10'};
    _equipments[2] = {'id': 2, 'type': 'Electrodomésticos', 'brand': 'Haceb', 'model': 'Nevera Himalaya', 'nickname': null, 'purchaseDate': null};
    _addresses[1] = {'id': 1, 'label': 'Casa', 'address': 'Cra 7 # 45-12', 'city': 'Bogotá', 'notes': 'Apto 302', 'isDefault': true};
    _payMethods[1] = {'id': 1, 'type': 'NEQUI', 'brand': 'Nequi', 'last4': '2233', 'isDefault': true};
    _payMethods[2] = {'id': 2, 'type': 'CARD', 'brand': 'Visa', 'last4': '4417', 'isDefault': false};
    _favorites.add(3);

    // Billetera del técnico
    _ledger.addAll([
      {'id': _nextId(), 'type': 'HOLD', 'amount': 195000, 'orderId': 7, 'note': null, 'createdAt': _now(const Duration(days: -1))},
      {'id': _nextId(), 'type': 'RELEASE', 'amount': 180000, 'orderId': 2, 'note': null, 'createdAt': _now(const Duration(days: -5))},
      {'id': _nextId(), 'type': 'COMMISSION', 'amount': 18000, 'orderId': 2, 'note': null, 'createdAt': _now(const Duration(days: -5))},
      {'id': _nextId(), 'type': 'WITHDRAWAL', 'amount': 150000, 'orderId': null, 'note': 'Nequi', 'createdAt': _now(const Duration(days: -9))},
    ]);
  }

  Map<String, dynamic> _msg(int conv, int sender, String text, Duration ago) => {
        'id': _nextId(), 'conversationId': conv, 'senderId': sender, 'text': text,
        'attachments': <Map<String, dynamic>>[], 'attachmentUrl': null,
        'readBy': [sender], 'createdAt': _now(ago),
      };

  void _notify(int userId, String title, String body, String type, Map<String, dynamic> meta) {
    _notifications.insert(0, {
      'id': _nextId(), 'userId': userId, 'title': title, 'body': body, 'type': type,
      'metadata': meta, 'channels': ['push'], 'read': false, 'createdAt': _now(),
    });
  }

  void _recalcRatings() {
    for (final t in _techs.values) {
      final rs = _reviews.values.where((r) => r['technicianId'] == t['id']).toList();
      t['reviewsCount'] = rs.length;
      if (rs.isNotEmpty) {
        final avg = rs.fold<int>(0, (a, r) => a + (r['rating'] as int)) / rs.length;
        t['rating'] = double.parse(avg.toStringAsFixed(1));
      }
    }
  }

  void _addQuote(int requestId, int techId, int price, String time, int hours, int warranty, String? message) {
    final id = _nextId();
    _quotes[id] = {
      'id': id, 'requestId': requestId, 'technicianId': techId,
      'technicianName': _techs[techId]!['businessName'], 'technicianRating': _techs[techId]!['rating'],
      'price': price, 'currency': _techs[techId]!['currency'],
      'estimatedTime': time, 'estimatedHours': hours, 'warrantyDays': warranty,
      'message': message, 'status': 'PENDING', 'createdAt': _now(),
    };
  }

  Map<String, dynamic> _newOrder({
    required int id, required int clientId, required int techId, required String service,
    required int base, required bool home, required String state, required String source,
    String payment = 'NEQUI', int daysAgo = 0, String? address,
  }) {
    final fee = home ? (_techs[techId]!['homeExtraFee'] as int) : 0;
    const seq = ['SOLICITADO', 'DIAGNOSTICO', 'EN_REPARACION', 'LISTO', 'ENTREGADO'];
    final reached = seq.indexOf(state);
    final timeline = [
      for (var i = 0; i <= reached; i++)
        {'state': seq[i], 'subState': null, 'note': i == 0 ? 'Orden creada' : null,
         'media': <Map<String, dynamic>>[], 'timestamp': _now(Duration(days: -daysAgo, hours: -(reached - i) * 3))},
    ];
    final delivered = state == 'ENTREGADO';
    return {
      'id': id, 'clientId': clientId, 'clientName': _users[clientId]!['name'],
      'technicianId': techId, 'technicianName': _techs[techId]!['businessName'],
      'serviceName': service, 'description': '', 'baseAmount': base, 'homeFee': fee,
      'adjustmentsTotal': 0, 'amount': base + fee, 'currency': _techs[techId]!['currency'], 'isHomeService': home,
      'address': home ? (address ?? 'Cra 7 # 45-12') : null, 'paymentMethod': payment,
      'source': source, 'state': state, 'subState': null,
      'estimatedDelivery': _now(Duration(hours: 6 - daysAgo * 24)),
      'escrowStatus': delivered ? 'RELEASED' : (payment == 'CASH' ? 'CASH_ON_DELIVERY' : 'HELD'),
      'paymentStatus': 'PAID', 'timeline': timeline, 'pendingAdjustment': null,
      'warranty': {'days': 90, 'expiresAt': delivered ? _now(Duration(days: 90 - daysAgo)) : null, 'active': delivered},
      'reviewed': false, 'createdAt': _now(Duration(days: -daysAgo)),
    };
  }

  Map<String, dynamic> _orderView(Map<String, dynamic> o) {
    final total = (o['baseAmount'] as int) + (o['homeFee'] as int) + (o['adjustmentsTotal'] as int);
    o['amount'] = total;
    o['paymentBreakdown'] = {
      'service': o['baseAmount'], 'homeFee': o['homeFee'], 'adjustments': o['adjustmentsTotal'],
      'platformFee': 0, 'total': total, 'currency': o['currency'],
    };
    return o;
  }

  Map<String, dynamic> get _me => {
        ..._users[_currentUser]!,
        'role': _activeRole,
        'activeRole': _activeRole,
      };

  Map<String, dynamic> _session() => {
        'user': _me,
        'token': 'mock-token-$_currentUser-$_activeRole',
        'refreshToken': 'mock-refresh-$_currentUser',
      };

  // -------------------------------------------------------------- respuestas
  MockResponse _ok(Object? data, {String? message, Map<String, dynamic>? extra, int status = 200}) =>
      MockResponse(status, {'success': true, if (message != null) 'message': message, 'data': data, ...?extra});

  MockResponse _list(List<Map<String, dynamic>> items, {Map<String, dynamic>? extra}) => MockResponse(200, {
        'success': true, 'count': items.length,
        'meta': {'total': items.length, 'page': 1, 'limit': 100, 'pages': 1},
        'data': items, ...?extra,
      });

  MockResponse _err(int status, String message) =>
      MockResponse(status, {'success': false, 'message': message});

  Map<String, dynamic> _fields(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is FormData) {
      final m = <String, dynamic>{};
      for (final f in data.fields) {
        m[f.key] = f.value;
      }
      m['_files'] = data.files.length;
      return m;
    }
    return {};
  }

  int _int(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;
  bool _bool(Object? v) => v == true || v == 'true';

  /// Punto de entrada: método + ruta (relativa a /api/v1) → respuesta.
  MockResponse handle(String method, String path, Map<String, dynamic> q, Object? data,
      {String? authorization}) {
    // El token simulado identifica usuario y rol (sobrevive a reinicios de la app).
    final t = RegExp(r'mock-token-(\d+)-(\w+)').firstMatch(authorization ?? '');
    if (t != null && _users.containsKey(int.parse(t.group(1)!))) {
      _currentUser = int.parse(t.group(1)!);
      _activeRole = t.group(2)!;
    }
    final b = _fields(data);
    final s = path.split('?').first.split('/').where((e) => e.isNotEmpty).toList();
    String seg(int i) => i < s.length ? s[i] : '';
    final m = method.toUpperCase();

    switch (seg(0)) {
      case 'auth':
        return _auth(m, seg(1), b);
      case 'config':
        if (seg(1) == 'categories') return _ok(_categories);
        if (seg(1) == 'countries' && seg(2).isEmpty) {
          return _ok(_countries.map(_countryPublic).toList());
        }
        final c = _country(seg(2).isEmpty ? _myCountry : seg(2).toUpperCase());
        return _ok({..._countryPublic(c), 'plans': _plans, 'commissions': {'b2bRate': 0.1}});
      case 'payments':
        // Métodos según el país del usuario (API.md §11).
        return _ok(_country(_myCountry)['paymentMethods']);
      case 'technicians':
        return _technicians(m, s, q, b);
      case 'quote-requests':
        return _quoteRequests(m, s, q, b);
      case 'appointments':
        return _appts(m, s, q, b);
      case 'orders':
        return _ordersApi(m, s, q, b);
      case 'chat':
        return _chat(m, s, b);
      case 'notifications':
        return _notificationsApi(m, s);
      case 'client':
        return _client(m, s, b);
      case 'subscriptions':
        return _subscriptions(m, seg(1), b);
      case 'supplier':
        return _supplier(m, seg(1), q, b);
      case 'disputes':
        return _disputesApi(m, s, b);
      case 'reviews':
        final r = _reviews[_int(seg(1))];
        if (r == null) return _err(404, 'Reseña no encontrada');
        if (r['reply'] != null) return _err(409, 'Ya respondiste esta reseña');
        r['reply'] = {'text': b['replyText'], 'repliedAt': _now()};
        return _ok(r);
    }
    return _err(404, 'Ruta no disponible en modo demo');
  }

  // ------------------------------------------------------------------- auth
  MockResponse _auth(String m, String action, Map<String, dynamic> b) {
    int pickUser() {
      final id = '${b['email'] ?? ''}${b['phone'] ?? ''}'.toLowerCase();
      if (id.contains('tecnico') || id.endsWith('5566')) return 2;
      return 1;
    }

    switch (action) {
      case 'otp':
      case 'password':
        return const MockResponse(200, {'success': true, 'message': 'Código enviado (demo)', 'expiresInSeconds': 300, 'otpCode': '123456'});
      case 'verify':
        if (b['code'] != '123456') return _err(400, 'Código inválido. En modo demo usa 123456');
        _currentUser = pickUser();
        _activeRole = 'CLIENT';
        return _ok(_session());
      case 'login':
        _currentUser = pickUser();
        final wanted = '${b['role'] ?? 'CLIENT'}';
        final roles = (_users[_currentUser]!['roles'] as List).cast<String>();
        _activeRole = roles.contains(wanted) ? wanted : 'CLIENT';
        return _ok(_session());
      case 'register':
        final id = _nextId();
        _users[id] = {
          'id': id, 'name': b['name'], 'email': b['email'], 'phone': b['phone'],
          'roles': [b['role'] ?? 'CLIENT'], 'country': b['country'] ?? 'CO', 'locale': b['locale'] ?? 'es-CO',
        };
        _currentUser = id;
        _activeRole = '${b['role'] ?? 'CLIENT'}';
        return _ok(_session(), status: 201);
      case 'refresh':
        return _ok(_session());
      case 'logout':
        return _ok(null, message: 'Sesión cerrada');
      case 'me':
        if (m == 'PUT') {
          for (final k in ['name', 'phone', 'locale', 'country', 'preferences']) {
            if (b.containsKey(k)) _users[_currentUser]![k] = b[k];
          }
          final code = '${_users[_currentUser]!['country']}';
          if (!_countries.any((c) => c['code'] == code)) {
            return _err(400, 'País no disponible');
          }
        }
        return _ok(_me);
      case 'switch-mode':
        final role = '${b['role']}';
        final roles = (_users[_currentUser]!['roles'] as List).cast<String>();
        if (!roles.contains(role)) {
          if (role == 'TECHNICIAN' && b['businessName'] == null) {
            return _err(400, 'Completa los datos de tu negocio para activar el modo técnico');
          }
          roles.add(role);
          _users[_currentUser]!['roles'] = roles;
        }
        _activeRole = role;
        return _ok(_session());
    }
    return _ok(null);
  }

  // ---------------------------------------------------------------- técnicos
  Map<String, dynamic> _techPublic(Map<String, dynamic> t, {bool full = false}) {
    final view = Map<String, dynamic>.from(t);
    if (full) {
      final rs = _reviews.values.where((r) => r['technicianId'] == t['id']).toList();
      view['reviews'] = rs;
      view['ratingDistribution'] = {
        for (var i = 1; i <= 5; i++) '$i': rs.where((r) => r['rating'] == i).length,
      };
      view['isFavorite'] = _favorites.contains(t['id']);
    }
    view['distanceKm'] = 1.2 + (t['id'] as int) * 0.9;
    return view;
  }

  MockResponse _technicians(String m, List<String> s, Map<String, dynamic> q, Map<String, dynamic> b) {
    if (s.length >= 2 && s[1] == 'me') return _myBusiness(m, s, q, b);
    if (s.length == 1) {
      // Como el backend real: búsqueda dentro del país del usuario.
      final country = _myCountry;
      var list = _techs.values.where((t) => t['country'] == country).toList();
      final cat = q['cat']?.toString();
      final text = q['q']?.toString().toLowerCase();
      if (cat != null && cat.isNotEmpty) {
        list = list.where((t) => (t['categories'] as List).contains(cat)).toList();
      }
      if (text != null && text.isNotEmpty) {
        list = list.where((t) =>
            '${t['businessName']} ${t['description']} ${t['categories']} ${t['services']}'
                .toLowerCase()
                .contains(text)).toList();
      }
      if (_bool(q['home'])) list = list.where((t) => t['homeService'] == true).toList();
      if (_bool(q['verified'])) list = list.where((t) => t['isVerified'] == true).toList();
      final minR = double.tryParse('${q['minRating'] ?? ''}');
      if (minR != null) list = list.where((t) => (t['rating'] as num) >= minR).toList();
      final views = list.map(_techPublic).toList();
      if (q['sort'] == 'rating') {
        views.sort((a, c) => (c['rating'] as num).compareTo(a['rating'] as num));
      } else {
        views.sort((a, c) => (a['distanceKm'] as num).compareTo(c['distanceKm'] as num));
      }
      return _list(views);
    }
    final t = _techs[_int(s[1])];
    if (t == null) return _err(404, 'Técnico no encontrado');
    if (s.length == 2) return _ok(_techPublic(t, full: true));
    if (s[2] == 'reviews') {
      return _list(_reviews.values.where((r) => r['technicianId'] == t['id']).toList());
    }
    if (s[2] == 'availability') {
      final date = '${q['date']}';
      final taken = _appointments.values
          .where((a) => a['technicianId'] == t['id'] && a['date'] == date && a['status'] != 'CANCELLED')
          .map((a) => a['time'])
          .toSet();
      final now = DateTime.now();
      final slots = [
        for (var h = 8; h < 18; h++)
          if (h != 12)
            {
              'time': '${h.toString().padLeft(2, '0')}:00',
              'available': !taken.contains('${h.toString().padLeft(2, '0')}:00') &&
                  !(date == _day(0) && h <= now.hour),
            },
      ];
      return _ok({
        'date': date, 'technicianId': t['id'], 'slots': slots,
        'availableSlots': [for (final x in slots) if (x['available'] == true) x['time']],
      });
    }
    return _err(404, 'Ruta no disponible en modo demo');
  }

  MockResponse _myBusiness(String m, List<String> s, Map<String, dynamic> q, Map<String, dynamic> b) {
    final t = _techs[_myTechId]!;
    final sub = s.length > 2 ? s[2] : '';
    switch (sub) {
      case '':
        if (m == 'PUT') {
          for (final k in ['businessName', 'description', 'categories', 'homeService', 'available', 'responseTime', 'homeExtraFee', 'coverageRadiusKm']) {
            if (b.containsKey(k)) t[k] = b[k];
          }
          final loc = Map<String, dynamic>.from(t['location'] as Map);
          if (b['address'] != null) loc['address'] = b['address'];
          if (b['city'] != null) loc['city'] = b['city'];
          t['location'] = loc;
        }
        return _ok({..._techPublic(t), 'wallet': _wallet});
      case 'schedule':
        if (m == 'PUT') {
          final sched = Map<String, dynamic>.from(t['schedule'] as Map)
            ..addAll(Map<String, dynamic>.from(b['schedule'] as Map));
          t['schedule'] = sched;
        }
        return _ok({'schedule': t['schedule'], 'blocks': <Object>[]});
      case 'services':
        final list = (t['services'] as List).cast<Map<String, dynamic>>();
        if (m == 'GET') return _ok(list);
        if (m == 'POST') {
          final svc = {'id': _nextId(), ...b, 'active': true, 'estimatedHours': 1};
          list.add(svc);
          return _ok(svc, status: 201);
        }
        final svc = list.firstWhere((x) => x['id'] == _int(s[3]), orElse: () => {});
        if (svc.isEmpty) return _err(404, 'Servicio no encontrado');
        if (m == 'PUT') svc.addAll(b);
        if (m == 'DELETE') svc['active'] = false;
        return _ok(svc);
      case 'documents':
        return _ok([{'type': b['type'], 'status': 'UPLOADED'}], status: 201);
      case 'submit-verification':
        t['verificationStatus'] = 'IN_REVIEW';
        return _ok({'verificationStatus': 'IN_REVIEW'});
      case 'wallet':
        return _ok(_wallet);
      case 'ledger':
        return _list(_ledger);
      case 'withdrawals':
        if (m == 'POST') {
          final amount = _int(b['amount']);
          if (amount > _wallet['available']!) return _err(400, 'Saldo insuficiente');
          _wallet = {..._wallet, 'available': _wallet['available']! - amount, 'withdrawn': _wallet['withdrawn']! + amount};
          _ledger.insert(0, {'id': _nextId(), 'type': 'WITHDRAWAL', 'amount': amount, 'orderId': null, 'note': '${(b['destination'] as Map?)?['type']}', 'createdAt': _now()});
          return _ok({'amount': amount, 'status': 'PROCESSING'}, extra: {'wallet': _wallet}, status: 201);
        }
        return _list(_ledger.where((l) => l['type'] == 'WITHDRAWAL').toList());
      case 'analytics':
        final done = _orders.values.where((o) => o['technicianId'] == _myTechId && o['state'] == 'ENTREGADO').length;
        final weekly = [
          for (var i = 5; i >= 0; i--)
            {'weekStart': _day(-7 * i), 'revenue': [420000, 380000, 510000, 290000, 640000, 455000][5 - i]},
        ];
        return _ok({
          'periodDays': 30, 'currency': _techs[_myTechId]!['currency'], 'totalRevenue': 1840000, 'previousRevenue': 1560000,
          'revenueChangePct': 18, 'weeklyRevenue': weekly, 'completedOrders': 27 + done,
          'profileViews': 312, 'requestsReceived': 41, 'quotesSent': 33, 'quotesAccepted': 19,
          'conversionRate': 0.58, 'rating': t['rating'], 'reviewsCount': t['reviewsCount'], 'plan': _plan,
        });
    }
    return _err(404, 'Ruta no disponible en modo demo');
  }

  // ------------------------------------------------------------ cotizaciones
  String _myStatusFor(Map<String, dynamic> r, int techId) {
    final mine = _quotes.values.where((x) => x['requestId'] == r['id'] && x['technicianId'] == techId).toList();
    if ((r['rejectedBy'] as List).contains(techId)) return 'REJECTED';
    if (mine.isNotEmpty) return mine.first['status'] == 'ACCEPTED' ? 'ACCEPTED' : 'QUOTED';
    return r['status'] == 'OPEN' ? 'NEW' : 'CLOSED';
  }

  Map<String, dynamic> _requestView(Map<String, dynamic> r, {int? forTech}) {
    final v = Map<String, dynamic>.from(r)
      ..['quotesCount'] = _quotes.values.where((x) => x['requestId'] == r['id']).length;
    if (forTech != null) {
      v['myStatus'] = _myStatusFor(r, forTech);
      v['distanceKm'] = 2.4;
      final mine = _quotes.values.where((x) => x['requestId'] == r['id'] && x['technicianId'] == forTech);
      v['myQuote'] = mine.isEmpty ? null : mine.first;
    }
    return v;
  }

  List<String> _tagsFor(List<Map<String, dynamic>> qs, Map<String, dynamic> q) {
    if (qs.length < 2) return const [];
    final tags = <String>[];
    int minBy(String k) => qs.map((x) => x[k] as int).reduce((a, b) => a < b ? a : b);
    if (q['price'] == minBy('price')) tags.add('BEST_PRICE');
    if (q['estimatedHours'] == minBy('estimatedHours')) tags.add('FASTEST');
    final best = qs.map((x) => x['technicianRating'] as num).reduce((a, b) => a > b ? a : b);
    if (q['technicianRating'] == best) tags.add('BEST_RATED');
    return tags;
  }

  MockResponse _quoteRequests(String m, List<String> s, Map<String, dynamic> q, Map<String, dynamic> b) {
    if (s.length == 1 && m == 'POST') {
      final id = _nextId();
      final target = b['targetTechnicianId'] == null ? null : _int(b['targetTechnicianId']);
      final cat = '${b['deviceType']}';
      final matched = target != null
          ? [target]
          : _techs.values
              .where((t) => t['country'] == _myCountry && (t['categories'] as List).contains(cat))
              .map((t) => t['id'] as int)
              .take(3)
              .toList();
      _requests[id] = {
        'id': id, 'clientId': _currentUser, 'clientName': _users[_currentUser]!['name'],
        'deviceType': cat, 'brandModel': b['brandModel'], 'issueDescription': b['issueDescription'],
        'urgency': b['urgency'] ?? 'NORMAL', 'isHomeService': _bool(b['isHomeService']),
        'address': b['address'], 'status': 'OPEN', 'matchedTechnicianIds': matched,
        'targetTechnicianId': target, 'media': <Map<String, dynamic>>[],
        'expiresAt': _now(const Duration(hours: 24)), 'createdAt': _now(), 'rejectedBy': <int>[],
      };
      // Simula técnicos que responden (excepto el técnico de prueba, que cotiza a mano).
      final screen = _country(_myCountry)['screen'] as int;
      var price = screen * 2 ~/ 3;
      for (final techId in matched.where((t) => t != _myTechId)) {
        _addQuote(id, techId, price, '${techId + 1} horas', techId + 1, 90, null);
        price += screen ~/ 7;
      }
      for (final techId in matched) {
        _notify(_techs[techId]!['userId'] as int, 'Nueva solicitud', '$cat · ${b['brandModel']}', 'QUOTE', {'requestId': id});
      }
      return _ok(_requestView(_requests[id]!),
          message: matched.isEmpty ? 'No hay técnicos disponibles para esta categoría' : 'Solicitud enviada',
          status: 201);
    }
    if (s.length >= 2 && s[1] == 'mine') {
      final status = q['status']?.toString();
      return _list(_requests.values
          .where((r) => r['clientId'] == _currentUser && (status == null || r['status'] == status))
          .map((r) => _requestView(r))
          .toList()
          .reversed
          .toList());
    }
    if (s.length >= 2 && s[1] == 'received') {
      final status = q['status']?.toString();
      final mine = _requests.values.where((r) => (r['matchedTechnicianIds'] as List).contains(_myTechId)).toList();
      final counts = <String, int>{};
      for (final r in mine) {
        final st = _myStatusFor(r, _myTechId);
        counts[st] = (counts[st] ?? 0) + 1;
      }
      return _list(
        mine.where((r) => status == null || _myStatusFor(r, _myTechId) == status)
            .map((r) => _requestView(r, forTech: _myTechId))
            .toList(),
        extra: {'counts': counts},
      );
    }
    final r = _requests[_int(s[1])];
    if (r == null) return _err(404, 'Solicitud no encontrada');
    if (s.length == 2) {
      return _ok(_requestView(r, forTech: _activeRole == 'TECHNICIAN' ? _myTechId : null));
    }
    switch (s[2]) {
      case 'cancel':
        r['status'] = 'CANCELLED';
        return _ok(_requestView(r));
      case 'reject':
        (r['rejectedBy'] as List).add(_myTechId);
        return _ok(_requestView(r, forTech: _myTechId));
      case 'quotes':
        if (s.length == 3 && m == 'GET') {
          final qs = _quotes.values.where((x) => x['requestId'] == r['id']).toList();
          final views = [for (final x in qs) {...x, 'tags': _tagsFor(qs, x)}];
          final labels = {'BEST_PRICE': 'Mejor precio', 'FASTEST': 'Más rápido', 'BEST_RATED': 'Mejor calificado'};
          for (final v in views) {
            v['labels'] = [for (final t in v['tags'] as List) labels[t]];
          }
          return MockResponse(200, {
            'success': true, 'count': views.length, 'status': r['status'],
            'expiresAt': r['expiresAt'], 'waiting': r['status'] == 'OPEN', 'data': views,
          });
        }
        if (s.length == 3 && m == 'POST') {
          if (_quotes.values.any((x) => x['requestId'] == r['id'] && x['technicianId'] == _myTechId)) {
            return _err(409, 'Ya enviaste una cotización para esta solicitud');
          }
          _addQuote(r['id'] as int, _myTechId, _int(b['price']), '${b['estimatedTime']}',
              _int(b['estimatedHours']) == 0 ? 2 : _int(b['estimatedHours']),
              _int(b['warrantyDays']) == 0 ? 90 : _int(b['warrantyDays']), b['message']?.toString());
          _notify(r['clientId'] as int, 'Nueva cotización', '${_techs[_myTechId]!['businessName']} cotizó tu ${r['brandModel']}', 'QUOTE', {'requestId': r['id']});
          return _ok(null, message: 'Cotización enviada', status: 201);
        }
        if (s.length == 5 && s[4] == 'accept') {
          final quote = _quotes[_int(s[3])];
          if (quote == null) return _err(404, 'Cotización no encontrada');
          quote['status'] = 'ACCEPTED';
          for (final other in _quotes.values.where((x) => x['requestId'] == r['id'] && x != quote)) {
            other['status'] = 'REJECTED';
          }
          r['status'] = 'ACCEPTED';
          final orderId = _nextId();
          _orders[orderId] = _newOrder(
            id: orderId, clientId: r['clientId'] as int, techId: quote['technicianId'] as int,
            service: '${r['deviceType']} · ${r['brandModel']}', base: quote['price'] as int,
            home: r['isHomeService'] == true, state: 'SOLICITADO', source: 'QUOTE',
            payment: '${b['paymentMethod']}', address: r['address']?.toString(),
          );
          return _ok({'order': _orderView(_orders[orderId]!), 'payment': {'status': 'APPROVED'}, 'quote': quote}, status: 201);
        }
    }
    return _err(404, 'Ruta no disponible en modo demo');
  }

  // ----------------------------------------------------------------- citas
  MockResponse _appts(String m, List<String> s, Map<String, dynamic> q, Map<String, dynamic> b) {
    if (s.length == 1 && m == 'POST') {
      final techId = _int(b['technicianId']);
      final t = _techs[techId];
      if (t == null) return _err(404, 'Técnico no encontrado');
      final svc = (t['services'] as List).cast<Map<String, dynamic>>().firstWhere(
          (x) => x['id'] == _int(b['serviceId']), orElse: () => {});
      if (svc.isEmpty) return _err(400, 'Servicio no válido');
      if (_appointments.values.any((a) => a['technicianId'] == techId && a['date'] == b['date'] && a['time'] == b['time'] && a['status'] != 'CANCELLED')) {
        return _err(409, 'Esa franja ya no está disponible');
      }
      final home = b['mode'] == 'HOME';
      final orderId = _nextId();
      _orders[orderId] = _newOrder(
        id: orderId, clientId: _currentUser, techId: techId, service: '${svc['name']}',
        base: svc['priceFrom'] as int, home: home, state: 'SOLICITADO', source: 'APPOINTMENT',
        payment: '${b['paymentMethod']}', address: b['address']?.toString(),
      );
      final apptId = _nextId();
      _appointments[apptId] = {
        'id': apptId, 'orderId': orderId, 'technicianId': techId, 'clientId': _currentUser,
        'clientName': _users[_currentUser]!['name'], 'serviceId': svc['id'], 'serviceName': svc['name'],
        'date': b['date'], 'time': b['time'], 'mode': home ? 'HOME' : 'LOCAL',
        'address': b['address'], 'notes': b['notes'], 'status': 'CONFIRMED',
      };
      _notify(t['userId'] as int, 'Nueva cita', '${svc['name']} · ${b['date']} ${b['time']}', 'APPOINTMENT', {'orderId': orderId});
      final o = _orderView(_orders[orderId]!);
      return _ok({
        'appointment': _appointments[apptId], 'order': o, 'payment': {'status': 'APPROVED'},
        'summary': {'service': o['baseAmount'], 'homeFee': o['homeFee'], 'total': o['amount'], 'currency': o['currency']},
      }, status: 201);
    }
    if (s.length == 1) {
      final date = q['date']?.toString();
      final isTech = _activeRole == 'TECHNICIAN';
      final list = _appointments.values.where((a) =>
          (isTech ? a['technicianId'] == _myTechId : a['clientId'] == _currentUser) &&
          (date == null || a['date'] == date)).map((a) {
        final o = _orders[a['orderId']];
        return {...a, 'orderState': o?['state']};
      }).toList();
      return _list(list);
    }
    final a = _appointments[_int(s[1])];
    if (a == null) return _err(404, 'Cita no encontrada');
    if (s.length > 2 && s[2] == 'cancel') a['status'] = 'CANCELLED';
    return _ok(a);
  }

  // ---------------------------------------------------------------- órdenes
  MockResponse _ordersApi(String m, List<String> s, Map<String, dynamic> q, Map<String, dynamic> b) {
    final isTech = _activeRole == 'TECHNICIAN';
    bool mine(Map<String, dynamic> o) =>
        isTech ? o['technicianId'] == _myTechId : o['clientId'] == _currentUser;

    if (s.length == 1) {
      final status = q['status']?.toString();
      const closed = ['ENTREGADO', 'CANCELADO'];
      final list = _orders.values.where(mine).where((o) {
        if (status == 'active') return !closed.contains(o['state']);
        if (status == 'history') return closed.contains(o['state']);
        return true;
      }).map(_orderView).toList()
        ..sort((a, c) => '${c['createdAt']}'.compareTo('${a['createdAt']}'));
      return _list(list);
    }
    final o = _orders[_int(s[1])];
    if (o == null) return _err(404, 'Orden no encontrada');
    if (s.length == 2) return _ok(_orderView(o));

    void push(String state, String? note, [List<Map<String, dynamic>> media = const []]) {
      o['state'] = state;
      (o['timeline'] as List).add({'state': state, 'subState': null, 'note': note, 'media': media, 'timestamp': _now()});
    }

    const seq = ['SOLICITADO', 'DIAGNOSTICO', 'EN_REPARACION', 'LISTO', 'ENTREGADO'];
    switch (s[2]) {
      case 'transitions':
        final next = '${b['newState']}';
        final cur = seq.indexOf('${o['state']}');
        if (next == 'CANCELADO' || next == 'DISPUTA') {
          push(next, b['reason']?.toString());
          return _ok(_orderView(o));
        }
        if (seq.indexOf(next) != cur + 1) return _err(409, 'Transición no permitida desde ${o['state']}');
        if (next == 'EN_REPARACION' && o['pendingAdjustment'] != null) {
          return _err(409, 'Hay un ajuste de costo pendiente de aprobación');
        }
        if (next == 'ENTREGADO' && isTech) return _err(403, 'Solo el cliente confirma la entrega');
        push(next, b['note']?.toString());
        if (next == 'LISTO') {
          _notify(o['clientId'] as int, 'Tu equipo está listo', '${o['serviceName']} · confirma la recepción', 'ORDER', {'orderId': o['id']});
        }
        return _ok(_orderView(o));
      case 'confirm-receipt':
        if (o['state'] != 'LISTO') return _err(409, 'La orden aún no está lista');
        push('ENTREGADO', b['note']?.toString() ?? 'Recibido por el cliente');
        o['escrowStatus'] = 'RELEASED';
        o['warranty'] = {'days': 90, 'expiresAt': _now(const Duration(days: 90)), 'active': true};
        return _ok(_orderView(o));
      case 'cancel':
        push('CANCELADO', b['reason']?.toString());
        o['escrowStatus'] = 'REFUNDED';
        return _ok(_orderView(o));
      case 'evidence':
        final files = _int(b['_files']);
        final last = (o['timeline'] as List).last as Map;
        last['note'] = [if (last['note'] != null) last['note'], b['note']].join(' · ');
        (last['media'] as List).addAll(List.generate(files, (_) => {'url': '/uploads/demo.jpg', 'type': 'IMAGE'}));
        return _ok(_orderView(o), status: 201);
      case 'adjustments':
        if (s.length == 3) {
          o['pendingAdjustment'] = {'id': _nextId(), 'amount': _int(b['amount']), 'reason': b['reason'], 'status': 'PENDING'};
          _notify(o['clientId'] as int, 'Ajuste de costo', '${b['reason']}', 'ADJUSTMENT', {'orderId': o['id']});
          return _ok(o['pendingAdjustment'], status: 201);
        }
        final adj = o['pendingAdjustment'] as Map<String, dynamic>?;
        if (adj == null) return _err(404, 'No hay ajuste pendiente');
        if (s[4] == 'approve') o['adjustmentsTotal'] = (o['adjustmentsTotal'] as int) + (adj['amount'] as int);
        o['pendingAdjustment'] = null;
        return _ok(_orderView(o));
      case 'reviews':
        if (o['reviewed'] == true) return _err(409, 'Ya calificaste esta orden');
        final id = _nextId();
        _reviews[id] = {
          'id': id, 'orderId': o['id'], 'technicianId': o['technicianId'],
          'clientName': _users[_currentUser]!['name'], 'rating': _int(b['rating']),
          'tags': b['tags'] ?? <String>[], 'comment': b['comment'], 'hidden': false,
          'reply': null, 'createdAt': _now(),
        };
        o['reviewed'] = true;
        _recalcRatings();
        return _ok(_reviews[id], status: 201);
      case 'disputes':
        final id = _nextId();
        _disputes[id] = {
          'id': id, 'orderId': o['id'], 'openedBy': _currentUser, 'reason': b['reason'],
          'description': b['description'], 'media': <Map<String, dynamic>>[], 'status': 'OPEN',
          'updates': [{'note': 'Disputa abierta. El pago queda retenido.', 'authorName': 'Sr Robot', 'media': <Object>[], 'createdAt': _now()}],
          'resolution': null, 'createdAt': _now(),
        };
        push('DISPUTA', '${b['reason']}');
        return _ok(_disputes[id], status: 201);
    }
    return _err(404, 'Ruta no disponible en modo demo');
  }

  // -------------------------------------------------------------------- chat
  Map<String, dynamic> _convView(Map<String, dynamic> c) {
    final msgs = _messages[c['id']] ?? const [];
    final isTech = _activeRole == 'TECHNICIAN';
    final counterpart = isTech
        ? {'userId': c['clientId'], 'name': _users[c['clientId']]?['name'] ?? 'Cliente'}
        : {'userId': c['technicianUserId'], 'name': _techs[c['technicianId']]?['businessName'] ?? ''};
    return {
      ...c, 'counterpart': counterpart,
      'lastMessage': msgs.isEmpty ? null : msgs.last['text'],
      'unread': msgs.where((x) => !(x['readBy'] as List).contains(_currentUser)).length,
    };
  }

  MockResponse _chat(String m, List<String> s, Map<String, dynamic> b) {
    final isTech = _activeRole == 'TECHNICIAN';
    if (s.length == 2 && m == 'GET') {
      final list = _conversations.values
          .where((c) => isTech ? c['technicianId'] == _myTechId : c['clientId'] == _currentUser)
          .map(_convView)
          .toList();
      final total = list.fold<int>(0, (a, c) => a + (c['unread'] as int));
      return MockResponse(200, {'success': true, 'totalUnread': total, 'data': list});
    }
    if (s.length == 2 && m == 'POST') {
      final techId = _int(b['technicianId']);
      final existing = _conversations.values.where((c) => c['clientId'] == _currentUser && c['technicianId'] == techId);
      if (existing.isNotEmpty) return _ok(_convView(existing.first));
      final id = _nextId();
      _conversations[id] = {'id': id, 'clientId': _currentUser, 'technicianId': techId, 'technicianUserId': _techs[techId]?['userId'], 'lastMessageAt': _now()};
      _messages[id] = [];
      return _ok(_convView(_conversations[id]!), status: 201);
    }
    final convId = _int(s[2]);
    final msgs = _messages.putIfAbsent(convId, () => []);
    if (s.length > 3 && s[3] == 'read') return _ok({'marked': 0});
    if (m == 'GET') {
      for (final x in msgs) {
        final r = x['readBy'] as List;
        if (!r.contains(_currentUser)) r.add(_currentUser);
      }
      return _list(msgs);
    }
    final files = _int(b['_files']);
    final msg = {
      'id': _nextId(), 'conversationId': convId, 'senderId': _currentUser,
      'text': b['text'], 'attachmentUrl': files > 0 ? '/uploads/demo.jpg' : null,
      'attachments': <Map<String, dynamic>>[], 'readBy': [_currentUser], 'createdAt': _now(),
    };
    msgs.add(msg);
    _conversations[convId]?['lastMessageAt'] = _now();
    return _ok(msg, status: 201);
  }

  // ----------------------------------------------------------- notificaciones
  MockResponse _notificationsApi(String m, List<String> s) {
    final mine = _notifications.where((n) => n['userId'] == _currentUser).toList();
    if (s.length > 1 && s[1] == 'read-all') {
      for (final n in mine) {
        n['read'] = true;
      }
      return _ok({'marked': mine.length});
    }
    if (s.length > 2 && s[2] == 'read') {
      for (final n in mine.where((n) => n['id'] == _int(s[1]))) {
        n['read'] = true;
      }
      return _ok(null);
    }
    return MockResponse(200, {
      'success': true, 'unreadCount': mine.where((n) => n['read'] != true).length,
      'meta': {'total': mine.length, 'page': 1, 'limit': 50, 'pages': 1}, 'data': mine,
    });
  }

  // ---------------------------------------------------------------- cliente
  MockResponse _crud(Map<int, Map<String, dynamic>> store, String m, List<String> s, Map<String, dynamic> b,
      {Map<String, dynamic> Function(Map<String, dynamic>)? view}) {
    final v = view ?? (Map<String, dynamic> x) => x;
    if (s.length == 2) {
      if (m == 'POST') {
        final id = _nextId();
        store[id] = {'id': id, ...b, if (store.isEmpty) 'isDefault': true};
        return _ok(v(store[id]!), status: 201);
      }
      return _ok(store.values.map(v).toList());
    }
    final id = _int(s[2]);
    if (!store.containsKey(id)) return _err(404, 'No encontrado');
    if (m == 'DELETE') {
      store.remove(id);
      return _ok(null);
    }
    if (b['isDefault'] == true) {
      for (final x in store.values) {
        x['isDefault'] = false;
      }
    }
    store[id]!.addAll(b);
    return _ok(v(store[id]!));
  }

  MockResponse _client(String m, List<String> s, Map<String, dynamic> b) {
    switch (s.length > 1 ? s[1] : '') {
      case 'equipments':
        return _crud(_equipments, m, s, b, view: (e) {
          final orders = _orders.values.where((o) => o['clientId'] == _currentUser && o['state'] == 'ENTREGADO').toList();
          final match = e['type'] == 'Electrodomésticos' && orders.isNotEmpty ? orders.first : null;
          return {
            ...e,
            'warranty': match == null
                ? {'status': 'NONE', 'expiresAt': null, 'orderId': null}
                : {'status': 'ACTIVE', 'expiresAt': (match['warranty'] as Map)['expiresAt'], 'orderId': match['id']},
            'lastService': match == null ? null : {'serviceName': match['serviceName']},
          };
        });
      case 'addresses':
        return _crud(_addresses, m, s, b);
      case 'payment-methods':
        return _crud(_payMethods, m, s, b);
      case 'favorites':
        if (s.length == 3) {
          final id = _int(s[2]);
          m == 'DELETE' ? _favorites.remove(id) : _favorites.add(id);
          return _ok(null);
        }
        return _ok([for (final id in _favorites) if (_techs[id] != null) _techPublic(_techs[id]!)]);
      case 'warranties':
        return _ok([
          for (final o in _orders.values.where((o) => o['clientId'] == _currentUser && o['state'] == 'ENTREGADO'))
            {'orderId': o['id'], 'serviceName': o['serviceName'], 'technicianId': o['technicianId'], ...(o['warranty'] as Map)},
        ]);
    }
    return _err(404, 'Ruta no disponible en modo demo');
  }

  // ------------------------------------------------------- suscripciones B2B
  MockResponse _subscriptions(String m, String sub, Map<String, dynamic> b) {
    if (sub == 'plans') return _ok(_plans);
    if (sub == 'invoices') return _ok(<Object>[]);
    if (m == 'PUT' || m == 'POST') {
      if (b['paymentMethod'] == 'CASH') return _err(400, 'Las suscripciones no se pagan en efectivo');
      _plan = '${b['plan']}';
      _subscriptionStatus = 'ACTIVE';
      _techs[_myTechId]!['plan'] = _plan;
    }
    if (m == 'DELETE') _subscriptionStatus = 'CANCELLED';
    return _ok({
      'plan': _plan,
      'planDetails': _plans.firstWhere((p) => p['code'] == _plan),
      'subscription': {'plan': _plan, 'status': _subscriptionStatus, 'nextBillingDate': _now(const Duration(days: 18))},
    });
  }

  MockResponse _supplier(String m, String sub, Map<String, dynamic> q, Map<String, dynamic> b) {
    final discount = _plan == 'PREMIUM' ? 0.15 : _plan == 'PRO' ? 0.10 : 0.0;
    Map<String, dynamic> priced(Map<String, dynamic> p) => {
          ...p, 'listPrice': p['price'], 'discount': discount,
          'price': ((p['price'] as int) * (1 - discount)).round(),
        };
    if (sub == 'products') {
      final cat = q['category']?.toString();
      final text = q['q']?.toString().toLowerCase();
      return _list(_products.values
          .where((p) => cat == null || p['category'] == cat)
          .where((p) => text == null || '${p['name']}'.toLowerCase().contains(text))
          .map(priced)
          .toList());
    }
    if (sub == 'orders' && m == 'POST') {
      var subtotal = 0;
      for (final it in (b['items'] as List).cast<Map>()) {
        final p = _products[_int(it['productId'])];
        if (p == null) return _err(404, 'Producto no encontrado');
        final qty = _int(it['quantity']);
        if ((p['stock'] as int) < qty) return _err(409, 'Sin stock suficiente de ${p['name']}');
        p['stock'] = (p['stock'] as int) - qty;
        subtotal += (priced(p)['price'] as int) * qty;
      }
      final shipping = subtotal >= 200000 ? 0 : 12000;
      return MockResponse(201, {
        'success': true, 'data': {'status': 'PROCESSING'},
        'totals': {'subtotal': subtotal, 'shipping': shipping, 'total': subtotal + shipping},
      });
    }
    return _ok(<Object>[]);
  }

  // ---------------------------------------------------------------- disputas
  MockResponse _disputesApi(String m, List<String> s, Map<String, dynamic> b) {
    if (s.length == 1) {
      return _list(_disputes.values.where((d) => d['openedBy'] == _currentUser).toList());
    }
    final d = _disputes[_int(s[1])];
    if (d == null) return _err(404, 'Disputa no encontrada');
    if (s.length > 2 && s[2] == 'comments') {
      (d['updates'] as List).add({
        'note': b['note'], 'authorName': _users[_currentUser]!['name'],
        'media': List.generate(_int(b['_files']), (_) => {'url': '/uploads/demo.jpg', 'type': 'IMAGE'}),
        'createdAt': _now(),
      });
    }
    return _ok(d);
  }
}

/// Respuesta simulada: código HTTP + cuerpo JSON.
class MockResponse {
  final int status;
  final Map<String, dynamic> body;
  const MockResponse(this.status, this.body);
}

/// Interceptor que responde desde [MockBackend] cuando el modo demo está activo.
class MockInterceptor extends Interceptor {
  MockInterceptor(this.enabled);
  final bool Function() enabled;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (!enabled()) return handler.next(options);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final r = MockBackend.instance.handle(
      options.method,
      options.path,
      options.queryParameters,
      options.data,
      authorization: options.headers['Authorization']?.toString(),
    );
    final response = Response<dynamic>(
        requestOptions: options, statusCode: r.status, data: r.body);
    if (r.status >= 400) {
      return handler.reject(DioException(
        requestOptions: options,
        response: response,
        type: DioExceptionType.badResponse,
      ));
    }
    handler.resolve(response);
  }
}
