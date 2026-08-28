/// Configuración global de la app.
///
/// Única fuente de la URL base de la API. Ningún servicio debe
/// escribir la URL "a mano": todos la heredan de aquí (o de la que
/// el usuario guarde en preferencias, ver [ApiService]).
class AppConfig {
  AppConfig._();

  static const String appName = 'BRAVA';

  /// Base de la API (Laravel).
  ///
  /// PRODUCCIÓN: el VPS con su IP dedicada, en el puerto 80 estándar.
  ///
  /// Para volver a probar en local, cámbiala por la IP de tu PC en la WiFi
  /// (p. ej. 'http://192.168.18.23:8000/api') y levanta Laravel con
  /// `php artisan serve --host=0.0.0.0 --port=8000`. No sirven `127.0.0.1`
  /// (apunta al propio celular) ni `10.0.2.2` (solo emulador).
  static const String apiBaseUrl = 'http://83.147.39.5/api';
}
