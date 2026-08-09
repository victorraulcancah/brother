import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static const String _baseUrlKey = 'api_base_url';
  static const String _tokenKey = 'auth_token';
  static const String defaultBaseUrl = AppConfig.apiBaseUrl;

  String _baseUrl = defaultBaseUrl;
  String? _token;
  final http.Client _client = http.Client();

  ApiService() {
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
    _token = prefs.getString(_tokenKey);
  }

  String get baseUrl => _baseUrl;

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> hasToken() async {
    if (_token != null) return true;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    return _token != null;
  }

  Map<String, String> get _headers => {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.acceptHeader: 'application/json',
    if (_token != null) HttpHeaders.authorizationHeader: 'Bearer $_token',
  };

  Future<dynamic> get(String path) async {
    await _loadSavedData();
    final response = await _client.get(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    await _loadSavedData();
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    final result = _handleResponse(response);
    return result is Map<String, dynamic> ? result : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    await _loadSavedData();
    final response = await _client.put(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    final result = _handleResponse(response);
    return result is Map<String, dynamic> ? result : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> delete(String path) async {
    await _loadSavedData();
    final response = await _client.delete(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
    );
    final result = _handleResponse(response);
    return result is Map<String, dynamic> ? result : <String, dynamic>{};
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      return jsonDecode(response.body);
    }
    final errorBody = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : {'error': 'Error ${response.statusCode}'};
    throw ApiException(
      statusCode: response.statusCode,
      message:
          errorBody['error']?.toString() ??
          errorBody['message']?.toString() ??
          'Error desconocido',
      errors: errorBody is Map<String, dynamic> ? errorBody : null,
    );
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException({required this.statusCode, required this.message, this.errors});

  /// Mensaje legible. En un 422 el `message` de Laravel es genérico
  /// ("validation.required"), así que se prefiere el primer error de campo,
  /// que sí dice qué está mal.
  String get detalle {
    final campos = errors?['errors'];
    if (campos is Map && campos.isNotEmpty) {
      final primero = campos.values.first;
      if (primero is List && primero.isNotEmpty) {
        return primero.first.toString();
      }
      if (primero is String) return primero;
    }
    return message;
  }

  @override
  String toString() => detalle;
}
