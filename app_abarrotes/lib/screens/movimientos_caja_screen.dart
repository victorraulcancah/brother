import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/data_card.dart';

String _money(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return 'S/ ${n.toStringAsFixed(2)}';
}

class MovimientosCajaScreen extends StatefulWidget {
  const MovimientosCajaScreen({super.key});

  @override
  State<MovimientosCajaScreen> createState() => _MovimientosCajaScreenState();
}

class _MovimientosCajaScreenState extends State<MovimientosCajaScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.movimientosCaja);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Movimientos de Caja',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay movimientos de caja'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final esIngreso = item['tipo'] == 'ingreso';
                final apertura = item['apertura'] as Map<String, dynamic>?;
                final caja = apertura?['caja'] as Map<String, dynamic>?;
                final metodo = item['metodo_pago'] as Map<String, dynamic>?;
                return DataCard(
                  title: '${item['fecha'] ?? ''}',
                  rows: [
                    DataCardRow(
                      label: 'Tipo',
                      value: AppBadge(
                        esIngreso ? 'Ingreso' : 'Egreso',
                        type: esIngreso ? AppBadgeType.success : AppBadgeType.danger,
                      ),
                    ),
                    DataCardRow.text('Caja', caja?['nombre'] as String? ?? '—'),
                    DataCardRow.text('Método', metodo?['nombre'] as String? ?? '—'),
                    DataCardRow.text('Monto', _money(item['monto'])),
                  ],
                );
              },
            ),
    );
  }
}
