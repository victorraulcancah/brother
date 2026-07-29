import 'api_service.dart';

class CrudService {
  final ApiService _api;
  final String _endpoint;

  CrudService(this._api, this._endpoint);

  Future<List<Map<String, dynamic>>> getAll() async {
    final data = await _api.get(_endpoint);
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final data = await _api.get('$_endpoint/$id');
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    return await _api.post(_endpoint, body: body);
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    return await _api.put('$_endpoint/$id', body: body);
  }

  Future<void> delete(int id) async {
    await _api.delete('$_endpoint/$id');
  }
}
