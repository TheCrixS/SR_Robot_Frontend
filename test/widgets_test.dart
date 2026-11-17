import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sr_robot_app/shared/models/order_model.dart';
import 'package:sr_robot_app/shared/widgets/custom_button.dart';
import 'package:sr_robot_app/shared/widgets/empty_state_view.dart';
import 'package:sr_robot_app/shared/widgets/order_timeline.dart';
import 'package:sr_robot_app/shared/widgets/sr_bottom_nav.dart';

import 'test_helpers.dart';

OrderModel _order(String state) => OrderModel.fromJson({
      'id': 7,
      'state': state,
      'serviceName': 'Cambio de pantalla',
      'amount': 195000,
      'timeline': [
        {'state': 'SOLICITADO', 'note': 'Orden creada', 'timestamp': '2026-11-16T15:00:00Z'},
        {'state': 'DIAGNOSTICO', 'timestamp': '2026-11-16T16:00:00Z'},
        {'state': 'EN_REPARACION', 'timestamp': '2026-11-16T17:00:00Z'},
      ],
    });

void main() {
  setUpAll(setUpTestEnvironment);

  group('SrButton', () {
    testWidgets('muestra el texto y responde al toque', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(SrButton(label: 'Agendar cita', onPressed: () => taps++)));
      expect(find.text('Agendar cita'), findsOneWidget);
      await tester.tap(find.text('Agendar cita'));
      expect(taps, 1);
    });

    testWidgets('en carga muestra el indicador y no responde', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
          wrap(SrButton(label: 'Enviar', loading: true, onPressed: () => taps++)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Enviar'), findsNothing);
      await tester.tap(find.byType(SrButton));
      expect(taps, 0);
    });

    testWidgets('solo ícono no desborda en 56 px', (tester) async {
      await tester.pumpWidget(wrap(Center(
        child: SizedBox(
          width: 56,
          child: SrButton(label: '', icon: Icons.chat_bubble_outline_rounded, onPressed: () {}),
        ),
      )));
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    });
  });

  group('OrderTimeline', () {
    testWidgets('pinta los 5 estados y marca los completados', (tester) async {
      await tester.pumpWidget(wrap(SingleChildScrollView(
        child: OrderTimeline(order: _order('EN_REPARACION'), locale: 'es_CO'),
      )));
      for (final label in [
        'Solicitado',
        'Diagnóstico',
        'En reparación',
        'Listo para entrega',
        'Entregado',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      // Solicitado y Diagnóstico ya pasaron → 2 checks.
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
      expect(find.text('Orden creada'), findsOneWidget);
    });

    testWidgets('el badge usa el nombre del estado', (tester) async {
      await tester.pumpWidget(wrap(const OrderStatusBadge(OrderState.listo)));
      expect(find.text('Listo para entrega'), findsOneWidget);
    });
  });

  group('SrBottomNav', () {
    testWidgets('muestra insignia y cambia de pestaña', (tester) async {
      var index = 0;
      await tester.pumpWidget(wrap(StatefulBuilder(
        builder: (context, setState) => Align(
          alignment: Alignment.bottomCenter,
          child: SrBottomNav(
            currentIndex: index,
            onTap: (i) => setState(() => index = i),
            items: const [
              SrNavItem(Icons.home_outlined, Icons.home_rounded, 'Inicio'),
              SrNavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded,
                  'Mensajes', badge: 3),
            ],
          ),
        ),
      )));
      expect(find.text('3'), findsOneWidget);
      await tester.tap(find.text('Mensajes'));
      await tester.pump();
      expect(index, 1);
    });
  });

  group('EmptyStateView', () {
    testWidgets('título, cuerpo y acción', (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrap(EmptyStateView(
        title: 'Sin conversaciones',
        body: 'Escríbele a un técnico',
        actionLabel: 'Buscar técnico',
        onAction: () => pressed = true,
      )));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Sin conversaciones'), findsOneWidget);
      await tester.tap(find.text('Buscar técnico'));
      expect(pressed, isTrue);
    });
  });
}
