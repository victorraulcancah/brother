import 'package:flutter/material.dart';

/// Paleta de marca BRAVA: acento azul sobre fondo gris (igual que la web).
///
/// Única fuente de color de toda la app. Ningún widget debe usar
/// colores "quemados" (Colors.red, 0xFF...): siempre a través de
/// [AppColors] o del [Theme] construido en app_theme.dart.
class AppColors {
  AppColors._();

  // Marca (azul de Tailwind)
  static const Color primary = Color(0xFF2563EB); // blue 600
  static const Color primaryLight = Color(0xFF3B82F6); // blue 500
  static const Color primaryDark = Color(0xFF1D4ED8); // blue 700
  static const Color primary800 = Color(0xFF1E40AF);
  static const Color primary900 = Color(0xFF1E3A8A);
  static const Color primary50 = Color(0xFFEFF6FF);
  static const Color primary100 = Color(0xFFDBEAFE);
  static const Color primary200 = Color(0xFFBFDBFE);
  static const Color accent = primary200;

  // Texto
  static const Color textStrong = Color(0xFF1F2937); // gris oscuro (títulos)
  static const Color textMuted = Color(0xFF6B7280); // secundario

  // Superficies
  static const Color background = Color(0xFFE9ECF0); // fondo de pantallas
  static const Color surface = Color(0xFFF3F4F6); // cajas internas sobre blanco
  static const Color field = Colors.white; // relleno de inputs
  static const Color border = Color(0xFFD4D8DE);

  // Estados
  static const Color danger = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color info = Color(0xFF0891B2); // cian: distinto del azul de marca
  static const Color warning = Color(0xFFF9A825);
}
