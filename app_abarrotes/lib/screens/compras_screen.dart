import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/data_card.dart';
import 'crear_compra_screen.dart';

String _money(dynamic v) => 'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';

class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.compras);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _nueva() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CrearCompraScreen()));
    if (ok == true) _load();
  }

  Future<void> _anular(Map<String, dynamic> item) async {
    try {
      await _api.post('${ApiEndpoints.compras}/${item['id']}/anular', body: {});
      await _load();
      if (mounted) showAppSnackbar(context, 'Compra anulada', type: AppSnackbarType.success);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Compras',
      floatingActionButton: FloatingActionButton(onPressed: _nueva, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay compras'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final prov = item['proveedor'] as Map<String, dynamic>?;
                final anulada = item['estado'] == 'anulada';
                final contado = item['forma_pago'] == 'contado';
                return DataCard(
                  title: prov?['nombre'] as String? ?? 'Proveedor',
                  rows: [
                    DataCardRow.text('Documento',
                        '${item['tipo_documento'] ?? ''} ${item['serie'] ?? ''}-${item['numero'] ?? ''}'),
                    DataCardRow.text('Fecha', '${item['fecha'] ?? '—'}'),
                    DataCardRow(
                      label: 'Pago',
                      value: AppBadge(contado ? 'Contado' : 'Crédito',
                          type: contado ? AppBadgeType.success : AppBadgeType.warning),
                    ),
                    DataCardRow.text('Total', _money(item['total'])),
                    DataCardRow(
                      label: 'Estado',
                      value: AppBadge(anulada ? 'Anulada' : 'Registrada',
                          type: anulada ? AppBadgeType.danger : AppBadgeType.success),
                    ),
                  ],
                  actions: anulada
                      ? []
                      : [
                          DataCardAction(
                            icon: Icons.block,
                            color: AppColors.danger,
                            tooltip: 'Anular',
                            onTap: () => _anular(item),
                          ),
                        ],
                );
              },
            ),
    );
  }
}
