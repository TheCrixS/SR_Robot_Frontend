import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/l10n_ext.dart';

/// Pantalla de arranque: mismo fondo y logo que el splash nativo de Android
/// (120 dp centrado) para que la transición sea imperceptible.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const logoAsset = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SrRobotColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Semantics(
            label: context.l10n.appName,
            image: true,
            child: Image.asset(logoAsset, width: 120, height: 120),
          ),
          const Positioned(
            bottom: 96,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: SrRobotColors.primaryTeal),
            ),
          ),
        ],
      ),
    );
  }
}
