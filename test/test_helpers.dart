import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sr_robot_app/core/network/token_storage.dart';
import 'package:sr_robot_app/core/theme/app_theme.dart';
import 'package:sr_robot_app/l10n/app_localizations.dart';

/// Configuración común: sin fuentes por red, preferencias en memoria
/// y símbolos de fecha cargados.
Future<void> setUpTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppText.useGoogleFonts = false;
  SharedPreferences.setMockInitialValues({});
  await initializeDateFormatting();
}

/// Envuelve un widget con tema, localización (es) y Riverpod.
Widget wrap(Widget child, {List<Override> overrides = const []}) => ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(TokenStorage.inMemory()),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    );
