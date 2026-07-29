import '../config/api_endpoints.dart';
import '../models/login_response.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api;

  AuthService(this._api);

  Future<LoginResponse> login(String email, String password) async {
    final data = await _api.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );
    await _api.saveToken(data['access_token']);
    return LoginResponse.fromJson(data);
  }

  Future<LoginResponse> register(
    String name,
    String email,
    String password,
    String passwordConfirmation, {
    int? empresaId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
    if (empresaId != null) body['empresa_id'] = empresaId;

    final data = await _api.post(ApiEndpoints.register, body: body);
    await _api.saveToken(data['access_token']);
    return LoginResponse.fromJson(data);
  }

  Future<User> getProfile() async {
    final data = await _api.get(ApiEndpoints.me);
    return User.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {}
    await _api.clearToken();
  }

  Future<bool> isLoggedIn() => _api.hasToken();
}
