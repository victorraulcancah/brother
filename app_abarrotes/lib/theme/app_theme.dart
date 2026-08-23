import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tema único de la app (Material 3, marca BRAVA).
///
/// Aquí se define UNA sola vez el estilo de inputs, botones, tarjetas,
/// etc. Los widgets reutilizables de `lib/widgets/` no repiten estilos:
/// heredan de este tema vía `Theme.of(context)`.
class AppTheme {
  AppTheme._();

  // Radios y medidas compartidas
  static const double radius = 12;
  static const double controlHeight = 52;

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(primary: AppColors.primary, error: AppColors.danger);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    OutlineInputBorder borderWith(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textStrong,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textStrong,
        ),
      ),
      // Material 3 tiñe las superficies con el color semilla y los diálogos
      // salían anaranjados; se fuerzan en blanco.
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      // Los selectores de fecha y hora no heredan `dialogTheme`: traen el suyo,
      // que por defecto usa `surfaceContainerHigh` (crema teñido de naranja).
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: Colors.white,
        headerForegroundColor: AppColors.textStrong,
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textStrong,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.field,
        border: borderWith(AppColors.border),
        enabledBorder: borderWith(AppColors.border),
        focusedBorder: borderWith(AppColors.primary, 2),
        errorBorder: borderWith(AppColors.danger),
        focusedErrorBorder: borderWith(AppColors.danger, 2),
        prefixIconColor: AppColors.textMuted,
        labelStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(controlHeight),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(controlHeight),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
