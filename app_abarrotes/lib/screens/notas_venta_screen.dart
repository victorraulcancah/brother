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

String _fecha(dynamic v) {
  final d = DateTime.tryParse('${v ?? ''}');
  if (d == null) return '—';
  return '${d.day}/${d.month}/${d.year}';
}

const _formaLabel = {
  'efectivo': 'Efectivo',
  'transferencia': 'Transferencia',
  'billetera': 'Billetera digital',
  'tarjeta': 'Tarjeta',
  'credito': 'Crédito',
};

/// Fila "etiqueta: valor" de la cabecera del detalle.
Widget _dato(String etiqueta, String valor) => Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              etiqueta,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );

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


  /// Una línea de la venta, con el mismo formato que el detalle de Compras.
  Widget _detalleCard(Map<String, dynamic> d) {
    final pres = d['presentacion'] as Map<String, dynamic>?;
    final producto = pres?['producto'] as Map<String, dynamic>?;
    final descuento = double.tryParse('${d['descuento'] ?? 0}') ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              producto?['nombre']?.toString() ?? d['producto_nombre']?.toString() ?? '-',
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
                _colDato('Cant.', '${d['cantidad']}'),
                _colDato('Precio', _money(d['precio_unitario'])),
                _colDato('Subtotal', _money(d['subtotal'])),
              ],
            ),
            if (descuento > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  _colDato('Descuento', _money(descuento), color: AppColors.warning),
                  const Spacer(),
                  const Spacer(),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _colDato(String label, String valor, {Color? color}) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            Text(
              valor,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      );

  /// El listado no trae productos ni pagos: se piden al abrir el detalle.
  Future<void> _verDetalle(Map<String, dynamic> item) async {
    Map<String, dynamic> venta = {};
    var error = false;
    try {
      // Laravel envuelve los Resource en {"data": {...}}: sin desempaquetar,
      // todos los campos salían vacíos.
      final res = await _api.get(ApiEndpoints.notaVenta(item['id']));
      final cuerpo = (res is Map && res['data'] is Map) ? res['data'] : res;
      venta = Map<String, dynamic>.from(cuerpo as Map);
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
                // Mismos datos que el detalle de la web.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dato('Cliente',
                          (venta['cliente'] as Map?)?['nombre']?.toString() ?? 'Clientes varios'),
                      _dato('Fecha', _fecha(venta['fecha_emision'])),
                      _dato('Vendedor',
                          (venta['vendedor'] as Map?)?['name']?.toString() ?? '—'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AppBadge(
                            venta['estado'] == 'anulada' ? 'Anulada' : 'Emitida',
                            type: venta['estado'] == 'anulada'
                                ? AppBadgeType.danger
                                : AppBadgeType.success,
                          ),
                          const SizedBox(width: 6),
                          AppBadge(
                            venta['tipo_pago'] == 'contado' ? 'Contado' : 'Crédito',
                            type: venta['tipo_pago'] == 'contado'
                                ? AppBadgeType.success
                                : AppBadgeType.warning,
                          ),
                        ],
                      ),
                      if (venta['observaciones'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Obs.: ${venta['observaciones']}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'PRODUCTOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                for (final d in detalles)
                  _detalleCard(d.cast<String, dynamic>()),

                const SizedBox(height: 6),
                const Text(
                  'PAGOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                if (pagos.isEmpty)
                  const Text(
                    'Sin pagos registrados.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                for (final pg in pagos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formaLabel['${pg['forma_pago']}'] ?? '${pg['forma_pago'] ?? '—'}'),
                        Text(_money(pg['monto'])),
                      ],
                    ),
                  ),

                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal', style: TextStyle(color: AppColors.textMuted)),
                    Text(_money(venta['subtotal'])),
                  ],
                ),
                if ((double.tryParse('${venta['descuento_total'] ?? 0}') ?? 0) > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Descuento', style: TextStyle(color: AppColors.textMuted)),
                      Text('− ${_money(venta['descuento_total'])}'),
                    ],
                  ),
                const SizedBox(height: 4),
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
                  // Tocar la tarjeta abre el detalle, igual que en Compras.
                  onTap: () => _verDetalle(item),
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
