import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Escala tipográfica Outfit del sistema de diseño.
class AppText {
  AppText._();

  /// En pruebas se desactiva para no descargar fuentes por red.
  static bool useGoogleFonts = true;

  static TextStyle _outfit(
          {required double fontSize,
          required FontWeight fontWeight,
          required Color color}) =>
      useGoogleFonts
          ? GoogleFonts.outfit(
              fontSize: fontSize, fontWeight: fontWeight, color: color)
          : TextStyle(
              fontFamily: 'Outfit',
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color);

  static TextStyle get h1 => _outfit(
      fontSize: 25, fontWeight: FontWeight.w700, color: SrRobotColors.textInk);
  static TextStyle get h2 => _outfit(
      fontSize: 20, fontWeight: FontWeight.w700, color: SrRobotColors.textInk);
  static TextStyle get h3 => _outfit(
      fontSize: 18, fontWeight: FontWeight.w700, color: SrRobotColors.textInk);
  static TextStyle get body => _outfit(
      fontSize: 15, fontWeight: FontWeight.w400, color: SrRobotColors.textInk);
  static TextStyle get bodyMedium => _outfit(
      fontSize: 15, fontWeight: FontWeight.w500, color: SrRobotColors.textInk);
  static TextStyle get bodyGray => _outfit(
      fontSize: 15, fontWeight: FontWeight.w400, color: SrRobotColors.textGray);
  static TextStyle get meta => _outfit(
      fontSize: 13, fontWeight: FontWeight.w400, color: SrRobotColors.textGray);
  static TextStyle get small => _outfit(
      fontSize: 12, fontWeight: FontWeight.w400, color: SrRobotColors.textGray);
  static TextStyle get tag => _outfit(
      fontSize: 11, fontWeight: FontWeight.w500, color: SrRobotColors.textInk);
  static TextStyle get button => _outfit(
      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SrRobotColors.primaryTeal,
        primary: SrRobotColors.primaryTeal,
        secondary: SrRobotColors.lime,
        error: SrRobotColors.alertRed,
        surface: SrRobotColors.surfaceWhite,
      ),
      scaffoldBackgroundColor: SrRobotColors.background,
    );

    return base.copyWith(
      textTheme: (AppText.useGoogleFonts
              ? GoogleFonts.outfitTextTheme(base.textTheme)
              : base.textTheme)
          .apply(
        bodyColor: SrRobotColors.textInk,
        displayColor: SrRobotColors.textInk,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SrRobotColors.background,
        foregroundColor: SrRobotColors.textInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.h2,
      ),
      dividerTheme: const DividerThemeData(
        color: SrRobotColors.lineBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SrRobotColors.surfaceWhite,
        hintStyle: AppText.bodyGray,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SrRobotColors.lineBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SrRobotColors.lineBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: SrRobotColors.primaryTeal, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SrRobotColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleSize: Size(32, 4),
        dragHandleColor: SrRobotColors.lineBorder,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SrRobotColors.textInk,
        contentTextStyle: AppText.body.copyWith(color: Colors.white),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? SrRobotColors.primaryTeal
                : SrRobotColors.lineBorder),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: SrRobotColors.primaryTeal,
        unselectedLabelColor: SrRobotColors.textGray,
        labelStyle: AppText.bodyMedium,
        unselectedLabelStyle: AppText.body,
        indicatorColor: SrRobotColors.primaryTeal,
        dividerColor: SrRobotColors.lineBorder,
      ),
    );
  }
}
