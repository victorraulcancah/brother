import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _alertas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get(ApiEndpoints.alertas);
      _alertas = ((res is Map ? res['alertas'] : null) as List? ?? []).cast<Map<String, dynamic>>();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  ({Color color, IconData icon}) _estilo(String? nivel) {
    switch (nivel) {
      case 'danger':
        return (color: AppColors.danger, icon: Icons.error_outline);
      case 'warning':
        return (color: AppColors.warning, icon: Icons.warning_amber_outlined);
      default:
        return (color: AppColors.info, icon: Icons.info_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Alertas',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _alertas.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.notifications_none, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Center(child: Text('No hay alertas por ahora 🎉')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _alertas.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final a = _alertas[i];
                        final e = _estilo(a['nivel'] as String?);
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: e.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: e.color.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(e.icon, color: e.color, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${a['titulo'] ?? ''}',
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                    if ((a['detalle'] ?? '').toString().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text('${a['detalle']}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
