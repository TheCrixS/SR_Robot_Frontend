import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sr_robot_app/app.dart';
import 'package:sr_robot_app/core/config/env_config.dart';
import 'package:sr_robot_app/core/network/token_storage.dart';

import 'test_helpers.dart';

/// Recorre la app completa contra el backend simulado (modo demo).
void main() {
  setUpAll(() async {
    await setUpTestEnvironment();
    EnvConfig.mockMode = true;
  });

  Future<void> settle(WidgetTester tester, [int steps = 12]) async {
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> signIn(WidgetTester tester, String email, {bool technician = false}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [tokenStorageProvider.overrideWithValue(TokenStorage.inMemory())],
      child: const SrRobotApp(),
    ));
    await settle(tester);
    expect(find.text('Necesito reparar'), findsOneWidget);

    if (technician) await tester.tap(find.text('Soy técnico'));
    await tester.tap(find.text('Correo'));
    await tester.pump();
    await tester.tap(find.text('Entrar con contraseña'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), email);
    await tester.enterText(find.byType(TextField).at(1), 'Password123!');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await settle(tester, 20);
  }

  testWidgets('cliente: login demo → inicio con técnicos y reparación en curso',
      (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await signIn(tester, 'cliente@srrobot.com');

    expect(find.textContaining('Hola, Juan'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Reparación en curso'), findsOneWidget);

    // Pestaña Reparaciones
    await tester.tap(find.text('Reparaciones'));
    await settle(tester);
    expect(find.text('Mis reparaciones'), findsOneWidget);
    expect(find.text('Cotizaciones abiertas'), findsOneWidget);
  });

  testWidgets('técnico: login demo → panel con métricas', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await signIn(tester, 'tecnico@srrobot.com', technician: true);

    expect(find.text('Carlos Fix Tech'), findsWidgets);
    expect(find.text('Ingresos del mes'), findsOneWidget);
    expect(find.text('Disponible a domicilio'), findsOneWidget);

    await tester.tap(find.text('Agenda'));
    await settle(tester);
    expect(find.text('Cambio de batería'), findsWidgets);
  });
}
