import 'package:flutter/material.dart';

/// Tokens de color oficiales de Sr Robot (mockup congelado).
class SrRobotColors {
  SrRobotColors._();

  // Marca y primarios
  static const Color primaryTeal = Color(0xFF2FB8AD);
  static const Color darkTeal = Color(0xFF1F9A90);
  static const Color lime = Color(0xFFA5D46A);
  static const Color yellowAccent = Color(0xFFFFD84D);

  // Superficies y textos
  static const Color textInk = Color(0xFF18202B);
  static const Color textGray = Color(0xFF6B7480);
  static const Color lineBorder = Color(0xFFE8ECEF);
  static const Color background = Color(0xFFF4F7F6);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color softTeal = Color(0xFFE4F6F3);

  // Semántica y alertas
  static const Color alertRed = Color(0xFFEF5B5B);
  static const Color starOrange = Color(0xFFF5A524);
  static const Color infoBlue = Color(0xFF4C8DF6);

  // Degradado corporativo (135°)
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
    colors: [
      Color(0xFF2FB8AD),
      Color(0xFF6FCB93),
      Color(0xFFC9DC61),
    ],
  );

  // Estados de reparación
  static const Color statusSolicitado = Color(0xFF6B7480);
  static const Color statusDiagnostico = Color(0xFF4C8DF6);
  static const Color statusEnReparacion = Color(0xFFFFD84D);
  static const Color statusListo = Color(0xFFA5D46A);
  static const Color statusEntregado = Color(0xFF2FB8AD);

  /// Sombra estándar de tarjetas.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromRGBO(20, 40, 40, 0.05),
      blurRadius: 14,
      offset: Offset(0, 3),
    ),
  ];

  /// Fondos pastel para contenedores de iconos/categorías.
  static const List<Color> pastels = [
    Color(0xFFE4F6F3),
    Color(0xFFEFF7E2),
    Color(0xFFFFF6D6),
    Color(0xFFE6EFFE),
    Color(0xFFFDE8E8),
    Color(0xFFF1EAFB),
    Color(0xFFFFEEDC),
    Color(0xFFE8F4F8),
  ];

  /// Colores sólidos para avatares con iniciales.
  static const List<Color> avatarColors = [
    primaryTeal,
    infoBlue,
    Color(0xFF8B6CF6),
    starOrange,
    darkTeal,
    alertRed,
  ];

  static Color avatarColorFor(String seed) =>
      avatarColors[seed.hashCode.abs() % avatarColors.length];
}
