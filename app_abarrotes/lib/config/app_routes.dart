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

  // Gestión
  static const String roles = '/roles';
  static const String usuarios = '/usuarios';
  static const String empresa = '/empresa';

  // Catálogo
  static const String productos = '/productos';
  static const String categorias = '/categorias';
  static const String marcas = '/marcas';
  static const String unidades = '/unidades';

  // Compras
  static const String proveedores = '/proveedores';
  static const String ordenesCompra = '/ordenes-compra';
  static const String solicitudesCompra = '/solicitudes-compra';
  static const String recepcionesCompra = '/recepciones-compra';

  // Inventario
  static const String almacenes = '/almacenes';
  static const String movimientos = '/movimientos';
  static const String tomasInventario = '/tomas-inventario';
}
