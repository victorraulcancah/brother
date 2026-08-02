import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../screens/alertas_screen.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

/// Campana de alertas para la AppBar: muestra el conteo y abre la pantalla de alertas.
class AlertsBellButton extends StatefulWidget {
  const AlertsBellButton({super.key});

  @override
  State<AlertsBellButton> createState() => _AlertsBellButtonState();
}

class _AlertsBellButtonState extends State<AlertsBellButton> {
  final ApiService _api = ApiService();
  int _total = 0;
  Map<String, dynamic> _porNivel = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get(ApiEndpoints.alertas);
      if (res is Map) {
        _total = (res['total'] as int?) ?? 0;
        _porNivel = (res['por_nivel'] as Map?)?.cast<String, dynamic>() ?? {};
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Color get _badgeColor {
    if (((_porNivel['danger'] as int?) ?? 0) > 0) return AppColors.danger;
    if (((_porNivel['warning'] as int?) ?? 0) > 0) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Alertas',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertasScreen()),
            );
            _load(); // refresca el conteo al volver
          },
        ),
        if (_total > 0)
          Positioned(
            top: 8,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: _badgeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _total > 99 ? '99+' : '$_total',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
