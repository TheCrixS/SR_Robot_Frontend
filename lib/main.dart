import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_settings.dart';
import 'core/config/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carga los símbolos de fecha de todos los idiomas soportados.
  await initializeDateFormatting();
  // El modo demo se decide antes de restaurar la sesión.
  try {
    final prefs = await SharedPreferences.getInstance();
    EnvConfig.mockMode =
        prefs.getBool(AppSettingsNotifier.kDemo) ?? EnvConfig.mockMode;
  } catch (_) {/* primera ejecución */}
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ProviderScope(child: SrRobotApp()));
}
