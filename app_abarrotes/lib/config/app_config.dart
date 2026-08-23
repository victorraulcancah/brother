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
  /// IP de la PC en la red WiFi, para probar desde un celular real. No sirve
  /// `127.0.0.1` (apunta al propio celular) ni `10.0.2.2` (solo emulador).
  /// Si cambias de red, la IP cambia: revísala con `ipconfig`.
  ///
  /// Laravel debe correr con: php artisan serve --host=0.0.0.0 --port=8000
  static const String apiBaseUrl = 'http://192.168.18.23:8000/api';
}
