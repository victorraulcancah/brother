/// Rutas de la API, relativas a [AppConfig.apiBaseUrl].
///
/// Se pasan a `ApiService` (que antepone la URL base). Así, si un
/// endpoint cambia, se corrige en UN solo sitio. Nunca escribas la
/// ruta completa dentro de un servicio o pantalla.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String me = '/me';
  static const String logout = '/logout';

  // Empresa
  static const String empresa = '/empresa';

  // Aquí se agregan los próximos módulos (productos, ventas, stock...):
  // static const String productos = '/productos';
  // static String producto(int id) => '/productos/$id';
}
