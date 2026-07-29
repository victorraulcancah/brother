/// Nombres de ruta de la app en un solo lugar.
///
/// Se usan en `main.dart` (registro) y en el menú lateral. Nunca
/// escribas el string de la ruta a mano ('/home'): usa `AppRoutes.home`.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  static const String home = '/home';
  static const String usuarios = '/usuarios';
  static const String productos = '/productos';
  static const String ventas = '/ventas';
  static const String inventario = '/inventario';
  static const String clientes = '/clientes';
  static const String configuracion = '/configuracion';
}
