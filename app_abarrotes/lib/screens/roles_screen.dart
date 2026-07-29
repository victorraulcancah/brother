import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/data_card.dart';

/// Roles del sistema (spatie/permission).
///
/// El backend expone solo `GET /roles`, que devuelve una lista de
/// NOMBRES (strings), no objetos: `["super-admin","admin","user"]`.
/// Por eso aquí se consume como lista de strings.
class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final ApiService _api = ApiService();
  List<String> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.get(ApiEndpoints.roles);
      final List raw = data is List
          ? data
          : (data is Map && data['data'] is List
                ? data['data'] as List
                : const []);
      _items = raw
          .map((e) => e is Map ? (e['name']?.toString() ?? '') : e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Roles',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: AppColors.danger),
              ),
            )
          : _items.isEmpty
          ? const Center(child: Text('No hay roles'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, index) => DataCard(
                  title: _items[index],
                  rows: [DataCardRow.text('Nombre', _items[index])],
                ),
              ),
            ),
    );
  }
}
