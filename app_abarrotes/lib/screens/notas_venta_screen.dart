import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';
import '../widgets/pdf_viewer_sheet.dart';
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
  String? _error;
  String _busqueda = '';
  String? _filtroEstado;
  String? _filtroPago;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.notasVenta);
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
      _error = 'No se pudieron cargar las ventas.';
    }
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

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((v) {
      if (_filtroEstado != null && v['estado'] != _filtroEstado) return false;
      if (_filtroPago != null && v['tipo_pago'] != _filtroPago) return false;
      if (q.isEmpty) return true;
      final cliente = (v['cliente'] as Map?)?['nombre'] ?? '';
      return '${v['serie']}-${v['numero']} $cliente'.toLowerCase().contains(q);
    }).toList();
  }

  /// El listado no trae productos ni pagos: se piden al abrir el detalle.
  Future<void> _verDetalle(Map<String, dynamic> item) async {
    Map<String, dynamic> venta = {};
    var error = false;
    try {
      venta = await _api.get(ApiEndpoints.notaVenta(item['id']));
    } catch (_) {
      error = true;
    }
    if (!mounted) return;

    final detalles = ((venta['detalles'] as List?) ?? []).whereType<Map>().toList();
    final pagos = ((venta['pagos'] as List?) ?? []).whereType<Map>().toList();

    await showAppModal<void>(
      context,
      title: 'Venta ${venta['serie'] ?? ''}-${venta['numero'] ?? ''}',
      child: error
          ? const AppMessage(text: 'No se pudo cargar el detalle.')
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente: ${(venta['cliente'] as Map?)?['nombre'] ?? 'Clientes varios'}',
                ),
                Text(
                  'Vendedor: ${(venta['vendedor'] as Map?)?['name'] ?? '—'}',
                ),
                if (venta['observaciones'] != null)
                  Text('Obs.: ${venta['observaciones']}'),
                const SizedBox(height: 12),
                const Text(
                  'Productos',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                for (final d in detalles)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${(d['presentacion'] as Map?)?['producto']?['nombre'] ?? d['producto_nombre'] ?? '—'}'
                            ' · ${(d['presentacion'] as Map?)?['nombre'] ?? ''}',
                          ),
                        ),
                        Text('${d['cantidad']} x ${_money(d['precio_unitario'])}'),
                        const SizedBox(width: 8),
                        Text(
                          _money(d['subtotal']),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                const Text('Pagos', style: TextStyle(fontWeight: FontWeight.w600)),
                for (final pg in pagos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${pg['forma_pago'] ?? '—'}'),
                        Text(_money(pg['monto'])),
                      ],
                    ),
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _money(venta['total']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (venta['motivo_anulacion'] != null) ...[
                  const SizedBox(height: 12),
                  AppMessage(text: 'Anulada: ${venta['motivo_anulacion']}'),
                ],
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Notas de Venta',
      floatingActionButton: FloatingActionButton(onPressed: _nueva, child: const Icon(Icons.add)),
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
                  hintText: 'Buscar ventas...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Estado',
                      value: _filtroEstado,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('emitida', 'Emitida'),
                        AppListFilterOption('anulada', 'Anulada'),
                      ],
                      onChanged: (v) => setState(() => _filtroEstado = v),
                    ),
                    AppListFilter(
                      label: 'Pago',
                      value: _filtroPago,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('contado', 'Contado'),
                        AppListFilterOption('credito', 'Credito'),
                      ],
                      onChanged: (v) => setState(() => _filtroPago = v),
                    ),
                  ],
                  activeFilters:
                      (_filtroEstado != null ? 1 : 0) +
                      (_filtroPago != null ? 1 : 0),
                  onClearFilters: () => setState(() {
                    _filtroEstado = null;
                    _filtroPago = null;
                  }),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(child: Text(_items.isEmpty ? 'No hay ventas' : 'Ninguna venta coincide con la busqueda'))
                      : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _visibles.length,
              itemBuilder: (context, index) {
                final item = _visibles[index];
                final cliente = item['cliente'] as Map<String, dynamic>?;
                final anulada = item['estado'] == 'anulada';
                final contado = item['tipo_pago'] == 'contado';
                return DataCard(
                  title: '${item['serie']}-${item['numero']}',
                  rows: [
                    DataCardRow.text('Cliente', cliente?['nombre'] as String? ?? 'Clientes varios'),
                    DataCardRow.text('Fecha', '${item['fecha_emision'] ?? '—'}'.split('T').first),
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
                  actions: [
                    DataCardAction(
                      icon: Icons.picture_as_pdf_outlined,
                      color: AppColors.textMuted,
                      tooltip: 'Imprimir / PDF',
                      onTap: () => mostrarPdf(context,
                          tipo: 'nota-venta',
                          id: item['id'] as int,
                          nombre: '${item['serie']}-${item['numero']}',
                          titulo: 'Nota de venta',
                          formatos: const ['a4', 'ticket']),
                    ),
                    DataCardAction(
                      icon: Icons.visibility_outlined,
                      color: AppColors.info,
                      tooltip: 'Ver detalle',
                      onTap: () => _verDetalle(item),
                    ),
                    if (!anulada) ...[
                          DataCardAction(
                            icon: Icons.block,
                            color: AppColors.danger,
                            tooltip: 'Anular',
                            onTap: () => _anular(item),
                          ),
                    ],
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
