/// Configuración global de la app.
///
/// Única fuente de la URL base de la API. Ningún servicio debe
/// escribir la URL "a mano": todos la heredan de aquí (o de la que
/// el usuario guarde en preferencias, ver [ApiService]).
class AppConfig {
  AppConfig._();

  static const String appName = 'BRAVA';

  /// Base de la API (Laravel). En producción se cambia solo aquí.
  static const String apiBaseUrl = 'http://83.147.39.58:10066/api';
}
