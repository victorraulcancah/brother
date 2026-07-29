import 'package:flutter/material.dart';

/// Puntos de quiebre para adaptar la UI a los distintos tamaños de móvil.
class Breakpoints {
  Breakpoints._();

  static const double smallPhone = 360; // móviles chicos (ej. Galaxy A0x)
  static const double phone = 400; // móvil estándar
  static const double largePhone = 480; // móvil grande / phablet
  static const double tablet = 600; // tablet
}

/// Utilidades responsivas sobre el `context`.
///
/// Uso:
///   context.isSmallPhone
///   context.responsive(mobile: 80, smallPhone: 64, tablet: 96)
extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  bool get isSmallPhone => screenWidth < Breakpoints.smallPhone;
  bool get isLargePhone => screenWidth >= Breakpoints.largePhone;
  bool get isTablet => screenWidth >= Breakpoints.tablet;

  /// Devuelve un valor según el ancho de pantalla.
  /// `mobile` es el valor por defecto; los otros son opcionales.
  T responsive<T>({required T mobile, T? smallPhone, T? tablet}) {
    if (isSmallPhone && smallPhone != null) return smallPhone;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}
