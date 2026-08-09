import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/data_card.dart';

String _fecha(dynamic v) =>
    v == null ? '—' : '$v'.split('T').first.split(' ').first;

/// Etiqueta y color del estado de la recepción.
({String label, AppBadgeType type}) _estadoInfo(Map<String, dynamic> r) {
  if (r['activo'] == false) {
    return (label: 'Inactiva', type: AppBadgeType.danger);
  }
  return switch (r['estado']) {
    'completa' => (label: 'Completa', type: AppBadgeType.success),
    'deshecha' => (label: 'Deshecha', type: AppBadgeType.danger),
    _ => (label: 'Parcial', type: AppBadgeType.warning),
  };
}

/// Registro de recepciones. No se crean aquí: se generan desde cada compra,
/// que es donde se sabe qué queda pendiente de recibir.
class RecepcionesCompraScreen extends StatefulWidget {
  const RecepcionesCompraScreen({super.key});

  @override
  State<RecepcionesCompraScreen> createState() =>
      _RecepcionesCompraScreenState();
}

class _RecepcionesCompraScreenState extends State<RecepcionesCompraScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _busqueda = '';
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.recepciones);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await _crud.getAll();
    } catch (_) {
      _error = 'No se pudieron cargar las recepciones.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((r) {
      if (_filtroEstado == 'activas' && r['activo'] == false) return false;
      if (_filtroEstado == 'inactivas' && r['activo'] != false) return false;
      if (q.isEmpty) return true;

      final prov = (r['proveedor'] as Map?)?['nombre'] ?? '';
      final compra = (r['compra'] as Map?)?['numero_compra'] ?? '';
      return '${r['documento'] ?? ''} $prov $compra'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _deshacer(Map<String, dynamic> item) async {
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Deshacer ${item['documento'] ?? ''}',
      message:
          'Se dará salida del stock que esta recepción ingresó al almacén, y '
          'sus cantidades volverán a quedar pendientes en la compra.',
    );
    if (!confirmado) return;

    try {
      await _api.post(ApiEndpoints.recepcionDeshacer(item['id']), body: {});
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Recepción deshecha: el stock fue revertido',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  /// Total recibido de una línea sumando las recepciones vigentes de la
  /// misma compra, no solo la que se está viendo.
  double _totalRecepcionado(Map<String, dynamic> recepcion, int? compraDetalleId) {
    if (compraDetalleId == null) return 0;
    return _items
        .where(
          (r) =>
              r['activo'] != false &&
              r['compra_id'] == recepcion['compra_id'],
        )
        .expand((r) => (r['detalles'] as List?) ?? [])
        .whereType<Map>()
        .where((d) => d['compra_detalle_id'] == compraDetalleId)
        .fold<double>(
          0,
          (acc, d) => acc + (double.tryParse('${d['cantidad_recibida']}') ?? 0),
        );
  }

  Future<void> _verDetalle(Map<String, dynamic> item) async {
    final detalles = ((item['detalles'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();

    await showAppModal<void>(
      context,
      title: 'Detalle ${item['documento'] ?? ''}',
      child: detalles.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Esta recepción no tiene líneas.')),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final d in detalles) _detalleCard(item, d),
              ],
            ),
    );
  }

  Widget _detalleCard(Map<String, dynamic> recepcion, Map<String, dynamic> d) {
    final pres = d['presentacion'] as Map<String, dynamic>?;
    final producto = pres?['producto'] as Map<String, dynamic>?;
    final compraDetalle = d['compra_detalle'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              producto?['nombre']?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${producto?['codigo'] ?? '-'} · ${pres?['nombre'] ?? '-'}'
              '${producto?['marca'] is Map ? ' · ${producto!['marca']['nombre']}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _dato('Cant.', '${d['cantidad_recibida']}', destacado: true),
                _dato('Pedida', '${d['cantidad_pedida']}'),
                _dato(
                  'Total recep.',
                  '${_totalRecepcionado(recepcion, d['compra_detalle_id'] as int?)}',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _dato('Finalizada', '${compraDetalle?['cantidad_finalizada'] ?? 0}'),
                _dato('Stock ant.', '${d['stock_anterior'] ?? 0}'),
                _dato('Stock nuevo', '${d['stock_nuevo'] ?? 0}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato(String label, String valor, {bool destacado = false}) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: destacado ? AppColors.primary : null,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Recepciones de Compra',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AppMessage(text: _error!),
                  ),
                AppListHeader(
                  hintText: 'Buscar recepciones...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Estado',
                      value: _filtroEstado,
                      options: const [
                        AppListFilterOption(null, 'Todas'),
                        AppListFilterOption('activas', 'Activas'),
                        AppListFilterOption('inactivas', 'Deshechas'),
                      ],
                      onChanged: (v) => setState(() => _filtroEstado = v),
                    ),
                  ],
                  activeFilters: _filtroEstado != null ? 1 : 0,
                  onClearFilters: () => setState(() => _filtroEstado = null),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _items.isEmpty
                                  ? 'No hay recepciones.\nSe registran desde el botón '
                                        'Recepcionar de cada compra.'
                                  : 'Ninguna recepción coincide con la búsqueda',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _visibles.length,
                          itemBuilder: (context, index) {
                            final item = _visibles[index];
                            final compra = item['compra'] as Map?;
                            final info = _estadoInfo(item);
                            final activa = item['activo'] != false;
                            final finalizada = compra?['finalizado'] == true;

                            return DataCard(
                              title: item['documento']?.toString() ?? '#${item['id']}',
                              subtitle:
                                  (item['proveedor'] as Map?)?['nombre']
                                      ?.toString(),
                              onTap: () => _verDetalle(item),
                              rows: [
                                DataCardRow.text(
                                  'Fecha',
                                  _fecha(item['fecha_recepcion']),
                                ),
                                DataCardRow.text(
                                  'Registró',
                                  (item['usuario_recibe']
                                          as Map?)?['name']
                                      ?.toString() ??
                                      '—',
                                ),
                                DataCardRow.text(
                                  'Almacén',
                                  (item['almacen'] as Map?)?['nombre']
                                          ?.toString() ??
                                      '—',
                                ),
                                DataCardRow.text(
                                  'Compra',
                                  compra?['numero_compra']?.toString() ?? '—',
                                ),
                                DataCardRow(
                                  label: 'Estado',
                                  value: AppBadge(info.label, type: info.type),
                                ),
                                DataCardRow(
                                  label: 'Finalización',
                                  value: AppBadge(
                                    finalizada ? 'Sí' : 'No',
                                    type: finalizada
                                        ? AppBadgeType.info
                                        : AppBadgeType.neutral,
                                  ),
                                ),
                                if (finalizada &&
                                    compra?['motivo_finalizacion'] != null)
                                  DataCardRow.text(
                                    'Motivo',
                                    compra!['motivo_finalizacion'].toString(),
                                  ),
                                if (finalizada)
                                  DataCardRow.text(
                                    'F. finalización',
                                    _fecha(compra?['fecha_finalizacion']),
                                  ),
                              ],
                              actions: [
                                if (activa)
                                  DataCardAction(
                                    icon: Icons.undo,
                                    color: AppColors.danger,
                                    tooltip: 'Deshacer',
                                    onTap: () => _deshacer(item),
                                  ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
