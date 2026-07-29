import 'package:flutter/material.dart';

/// Paleta de marca BRAVA.
///
/// Única fuente de color de toda la app. Ningún widget debe usar
/// colores "quemados" (Colors.red, 0xFF...): siempre a través de
/// [AppColors] o del [Theme] construido en app_theme.dart.
class AppColors {
  AppColors._();

  // Marca
  static const Color primary = Color(0xFFEF6C00); // naranja BRAVA
  static const Color primaryDark = Color(0xFFE65100);
  static const Color primaryLight = Color(0xFFFB8C00);
  static const Color accent = Color(0xFFFFB74D);

  // Texto
  static const Color textStrong = Color(0xFF5D2E00); // marrón cálido (títulos)
  static const Color textMuted = Color(0xFFA9866A); // secundario

  // Superficies
  static const Color surface = Color(0xFFFDF6EF); // fondo cálido
  static const Color field = Color(0xFFFAFAFA); // relleno de inputs
  static const Color border = Color(0xFFE0DAD2);

  // Estados
  static const Color danger = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
}
