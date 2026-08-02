import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';
import 'crear_venta_screen.dart';

String _money(dynamic v) => 'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';

class NotasVentaScreen extends StatefulWidget {
  const NotasVentaScreen({super.key});

  @override
  State<NotasVentaScreen> createState() => _NotasVentaScreenState();
}

class _NotasVentaScreenState extends State<NotasVentaScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.notasVenta);
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
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CrearVentaScreen()),
    );
    if (ok == true) _load();
  }

  Future<void> _anular(Map<String, dynamic> item) async {
    final motivo = await showAppModal<String>(
      context,
      title: 'Anular venta',
      child: _MotivoSheet(),
    );
    if (motivo == null || motivo.trim().isEmpty) return;
    try {
      await _api.post('${ApiEndpoints.notasVenta}/${item['id']}/anular', body: {'motivo_anulacion': motivo});
      await _load();
      if (mounted) showAppSnackbar(context, 'Venta anulada. Stock devuelto.', type: AppSnackbarType.success);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Notas de Venta',
      floatingActionButton: FloatingActionButton(onPressed: _nueva, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay ventas'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final cliente = item['cliente'] as Map<String, dynamic>?;
                final anulada = item['estado'] == 'anulada';
                final contado = item['tipo_pago'] == 'contado';
                return DataCard(
                  title: '${item['serie']}-${item['numero']}',
                  rows: [
                    DataCardRow.text('Cliente', cliente?['nombre'] as String? ?? 'Público general'),
                    DataCardRow.text('Fecha', '${item['fecha_emision'] ?? '—'}'),
                    DataCardRow(
                      label: 'Pago',
                      value: AppBadge(contado ? 'Contado' : 'Crédito',
                          type: contado ? AppBadgeType.success : AppBadgeType.warning),
                    ),
                    DataCardRow.text('Total', _money(item['total'])),
                    DataCardRow(
                      label: 'Estado',
                      value: AppBadge(anulada ? 'Anulada' : 'Emitida',
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

class _MotivoSheet extends StatefulWidget {
  @override
  State<_MotivoSheet> createState() => _MotivoSheetState();
}

class _MotivoSheetState extends State<_MotivoSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(controller: _ctrl, label: 'Motivo de anulación', icon: Icons.edit_note),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SecondaryButton(label: 'Cancelar', onPressed: () => Navigator.pop(context))),
            const SizedBox(width: 12),
            Expanded(child: PrimaryButton(label: 'Anular', onPressed: () => Navigator.pop(context, _ctrl.text))),
          ],
        ),
      ],
    );
  }
}
