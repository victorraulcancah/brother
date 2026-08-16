import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_search_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_area.dart';
import '../widgets/data_card.dart';
import '../widgets/pdf_viewer_sheet.dart';
import '../widgets/producto_lineas_panel.dart';
import 'crear_compra_screen.dart';

String _money(dynamic v) => 'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';
String _fecha(dynamic v) => v == null ? '—' : '$v'.split('T').first;
String _num(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
}

/// Etiqueta y color de cada estado de la orden, igual que en la web.
({String label, AppBadgeType type}) _estadoInfo(String? estado) => switch (estado) {
  'aprobada' => (label: 'Aprobada', type: AppBadgeType.success),
  'enviada' => (label: 'Enviada', type: AppBadgeType.info),
  'parcial' => (label: 'Parcial', type: AppBadgeType.warning),
  'completada' => (label: 'Completada', type: AppBadgeType.success),
  'anulada' => (label: 'Anulada', type: AppBadgeType.danger),
  _ => (label: 'Pendiente', type: AppBadgeType.warning),
};

class OrdenesCompraScreen extends StatefulWidget {
  const OrdenesCompraScreen({super.key});

  @override
  State<OrdenesCompraScreen> createState() => _OrdenesCompraScreenState();
}

class _OrdenesCompraScreenState extends State<OrdenesCompraScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _proveedores = [];
  bool _loading = true;
  String? _error;

  String _busqueda = '';
  String? _filtroEstado;
  String? _filtroCompra;
  String? _filtroProveedor;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.ordenes);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Future.wait([
        _crud.getAll(),
        CrudService(_api, ApiEndpoints.proveedores).getAll(),
      ]);
      _items = r[0];
      _proveedores = r[1];
    } catch (e) {
      _error = 'No se pudieron cargar las órdenes: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  bool _transformada(Map item) => ((item['compras_count'] ?? 0) as num) > 0;

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((o) {
      if (_filtroEstado != null && (o['estado'] ?? 'pendiente') != _filtroEstado) return false;
      if (_filtroCompra == 'si' && !_transformada(o)) return false;
      if (_filtroCompra == 'no' && _transformada(o)) return false;
      if (_filtroProveedor != null && '${o['proveedor_id']}' != _filtroProveedor) return false;
      if (q.isEmpty) return true;
      final prov = (o['proveedor'] as Map?)?['nombre'] ?? '';
      return '${o['codigo'] ?? ''} $prov ${o['observaciones'] ?? ''}'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _nueva() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CrearOrdenCompraScreen()));
    if (ok == true) _load();
  }

  Future<void> _editar(Map<String, dynamic> item) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CrearOrdenCompraScreen(ordenId: item['id'] as int)),
    );
    if (ok == true) _load();
  }

  /// La compra nace de la orden: se copian proveedor y líneas.
  Future<void> _transformar(Map<String, dynamic> item) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CrearCompraScreen(ordenId: item['id'] as int)),
    );
    if (ok == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Eliminar orden',
      message: '¿Eliminar la orden ${item['codigo']}? Se eliminará permanentemente.',
    );
    if (!ok) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Orden eliminada', type: AppSnackbarType.error);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  /// Detalle de la orden (se carga completo: la lista no trae las líneas).
  Future<void> _verDetalle(Map<String, dynamic> item) async {
    Map<String, dynamic> orden;
    try {
      orden = await _api.get(ApiEndpoints.orden(item['id'] as int));
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'No se pudo cargar la orden: $e', type: AppSnackbarType.error);
      return;
    }
    if (!mounted) return;
    final detalles = ((orden['detalles'] as List?) ?? []).whereType<Map>().toList();
    final total = detalles.fold<double>(
      0,
      (s, d) => s + (double.tryParse('${d['cantidad']}') ?? 0) * (double.tryParse('${d['precio_unitario']}') ?? 0),
    );
    final compras = ((item['compras'] as List?) ?? []).whereType<Map>().toList();

    await showAppModal<void>(
      context,
      title: 'Orden ${orden['codigo'] ?? ''}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Proveedor: ${(orden['proveedor'] as Map?)?['nombre'] ?? '—'}'),
          Text('Emisión: ${_fecha(orden['fecha_emision'])} · Entrega estimada: ${_fecha(orden['fecha_entrega_estimada'])}'),
          if (orden['observaciones'] != null && '${orden['observaciones']}'.isNotEmpty) Text('Obs.: ${orden['observaciones']}'),
          if (compras.isNotEmpty)
            Text('Compra: ${compras.map((c) => c['correlativo'] ?? '#${c['id']}').join(', ')}', style: const TextStyle(color: AppColors.success)),
          const SizedBox(height: 12),
          if (detalles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Esta orden no tiene productos.')),
            ),
          for (final d in detalles) _detalleCard(d),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              Text(_money(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detalleCard(Map d) {
    final pres = d['presentacion'] as Map?;
    final producto = pres?['producto'] as Map?;
    final subtotal = (double.tryParse('${d['cantidad']}') ?? 0) * (double.tryParse('${d['precio_unitario']}') ?? 0);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(producto?['nombre']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${producto?['codigo'] ?? '—'} · ${pres?['nombre'] ?? '—'}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: Text('Cant.: ${_num(d['cantidad'])}')),
                Expanded(child: Text('P. unit.: ${_money(d['precio_unitario'])}')),
                Expanded(child: Text(_money(subtotal), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Órdenes de Compra',
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
                  hintText: 'Buscar por código o proveedor...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Estado',
                      value: _filtroEstado,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('pendiente', 'Pendiente'),
                        AppListFilterOption('aprobada', 'Aprobada'),
                        AppListFilterOption('enviada', 'Enviada'),
                        AppListFilterOption('parcial', 'Parcial'),
                        AppListFilterOption('completada', 'Completada'),
                        AppListFilterOption('anulada', 'Anulada'),
                      ],
                      onChanged: (v) => setState(() => _filtroEstado = v),
                    ),
                    AppListFilter(
                      label: 'Compra',
                      value: _filtroCompra,
                      options: const [
                        AppListFilterOption(null, 'Todas'),
                        AppListFilterOption('no', 'Sin compra'),
                        AppListFilterOption('si', 'Transformadas'),
                      ],
                      onChanged: (v) => setState(() => _filtroCompra = v),
                    ),
                    AppListFilter(
                      label: 'Proveedor',
                      value: _filtroProveedor,
                      options: [
                        const AppListFilterOption(null, 'Todos'),
                        for (final p in _proveedores) AppListFilterOption('${p['id']}', p['nombre']?.toString() ?? ''),
                      ],
                      onChanged: (v) => setState(() => _filtroProveedor = v),
                    ),
                  ],
                  activeFilters: (_filtroEstado != null ? 1 : 0) + (_filtroCompra != null ? 1 : 0) + (_filtroProveedor != null ? 1 : 0),
                  onClearFilters: () => setState(() {
                    _filtroEstado = null;
                    _filtroCompra = null;
                    _filtroProveedor = null;
                  }),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(child: Text(_items.isEmpty ? 'No hay órdenes' : 'Ninguna orden coincide con la búsqueda'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _visibles.length,
                          itemBuilder: (context, index) {
                            final item = _visibles[index];
                            final prov = item['proveedor'] as Map?;
                            final estado = _estadoInfo(item['estado']?.toString());
                            final bloqueada = _transformada(item);
                            final compras = ((item['compras'] as List?) ?? []).whereType<Map>().toList();

                            return DataCard(
                              title: item['codigo']?.toString() ?? 'Orden #${item['id']}',
                              subtitle: prov?['nombre']?.toString(),
                              onTap: () => _verDetalle(item),
                              rows: [
                                DataCardRow.text('Emisión', _fecha(item['fecha_emision'])),
                                DataCardRow.text('Entrega est.', _fecha(item['fecha_entrega_estimada'])),
                                DataCardRow.text('Ítems', '${item['detalles_count'] ?? 0}'),
                                DataCardRow(label: 'Estado', value: AppBadge(estado.label, type: estado.type)),
                                DataCardRow(
                                  label: 'Compra',
                                  value: AppBadge(
                                    bloqueada
                                        ? 'Transformada${compras.isNotEmpty && compras.first['correlativo'] != null ? ' · ${compras.first['correlativo']}' : ''}'
                                        : 'Sin compra',
                                    type: bloqueada ? AppBadgeType.success : AppBadgeType.neutral,
                                  ),
                                ),
                              ],
                              actions: [
                              DataCardAction(
                                icon: Icons.picture_as_pdf_outlined,
                                color: AppColors.textMuted,
                                tooltip: 'Imprimir / PDF',
                                onTap: () => mostrarPdf(context,
                                    tipo: 'orden-compra',
                                    id: item['id'] as int,
                                    nombre: item['codigo']?.toString() ?? '#${item['id']}',
                                    titulo: 'Orden de compra',
                                    formatos: const ['a4', 'ticket']),
                              ),
                              // Una orden ya transformada en compra queda congelada
                              // (solo se puede imprimir).
                              if (!bloqueada) ...[
                                      DataCardAction(
                                        icon: Icons.shopping_bag_outlined,
                                        color: AppColors.success,
                                        tooltip: 'Transformar a compra',
                                        onTap: () => _transformar(item),
                                      ),
                                      DataCardAction(
                                        icon: Icons.edit_outlined,
                                        color: AppColors.primary,
                                        tooltip: 'Editar',
                                        onTap: () => _editar(item),
                                      ),
                                      DataCardAction(
                                        icon: Icons.delete_outline,
                                        color: AppColors.danger,
                                        tooltip: 'Eliminar',
                                        onTap: () => _delete(item),
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

// ═══════════════════ Crear / editar orden de compra ═══════════════════

/// Pantalla completa de orden de compra, igual que la web: datos de la orden,
/// panel de búsqueda de producto (con lupa avanzada), tabla de productos,
/// observaciones y total. Con [ordenId] edita una orden existente.
class CrearOrdenCompraScreen extends StatefulWidget {
  final int? ordenId;
  const CrearOrdenCompraScreen({super.key, this.ordenId});

  @override
  State<CrearOrdenCompraScreen> createState() => _CrearOrdenCompraScreenState();
}

class _CrearOrdenCompraScreenState extends State<CrearOrdenCompraScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _codigo;

  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _productos = [];
  Map<int, double> _stockPorProducto = {};

  int? _proveedorId;
  DateTime _fechaEmision = DateTime.now();
  DateTime? _fechaEntrega;
  final _observaciones = TextEditingController();
  final List<LineaProducto> _lineas = [];

  bool get _editando => widget.ordenId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _observaciones.dispose();
    for (final l in _lineas) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([
        CrudService(_api, ApiEndpoints.proveedores).getAll(),
        // Sin per_page el backend pagina a 15 y el resto del catálogo no aparece.
        CrudService(_api, '${ApiEndpoints.productos}?per_page=500').getAll(),
        CrudService(_api, ApiEndpoints.existencias).getAll(),
      ]);
      _proveedores = r[0];
      _productos = r[1];
      // El stock vive por almacén: se acumula por producto (unidad base).
      final st = <int, double>{};
      for (final e in r[2]) {
        final pid = e['producto_id'] as int;
        st[pid] = (st[pid] ?? 0) + (double.tryParse('${e['stock_actual']}') ?? 0);
      }
      _stockPorProducto = st;

      if (_editando) {
        final orden = await _api.get(ApiEndpoints.orden(widget.ordenId!));
        _codigo = orden['codigo']?.toString();
        _proveedorId = int.tryParse('${orden['proveedor_id']}');
        _fechaEmision = DateTime.tryParse('${orden['fecha_emision']}') ?? DateTime.now();
        _fechaEntrega = orden['fecha_entrega_estimada'] == null ? null : DateTime.tryParse('${orden['fecha_entrega_estimada']}');
        _observaciones.text = orden['observaciones']?.toString() ?? '';
        for (final d in ((orden['detalles'] as List?) ?? []).whereType<Map>()) {
          final pres = d['presentacion'] as Map?;
          final productoId = int.tryParse('${pres?['producto_id'] ?? (pres?['producto'] as Map?)?['id']}');
          if (productoId == null) continue;
          _lineas.add(LineaProducto(
            productoId: productoId,
            presentacionId: int.tryParse('${d['producto_presentacion_id']}'),
            cantidad: _num(d['cantidad']),
            precio: '${double.tryParse('${d['precio_unitario']}') ?? 0}',
          ));
        }
      }
    } catch (e) {
      _error = 'No se pudieron cargar los datos: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  double get _total => _lineas.fold(0, (a, l) => a + l.subtotal);

  Future<void> _elegirFecha({required bool entrega}) async {
    final d = await showDatePicker(
      context: context,
      initialDate: entrega ? (_fechaEntrega ?? _fechaEmision) : _fechaEmision,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      if (entrega) {
        _fechaEntrega = d;
      } else {
        _fechaEmision = d;
      }
    });
  }

  Future<void> _guardar() async {
    final lineas = _lineas.where((l) => l.presentacionId != null && l.cant > 0).toList();
    if (_proveedorId == null) return showAppSnackbar(context, 'Selecciona el proveedor.', type: AppSnackbarType.error);
    if (lineas.isEmpty) return showAppSnackbar(context, 'Agrega al menos un producto.', type: AppSnackbarType.error);

    setState(() => _saving = true);
    // El código es correlativo interno: lo asigna el backend.
    final payload = {
      'proveedor_id': _proveedorId,
      'fecha_emision': _fechaEmision.toIso8601String().substring(0, 10),
      'fecha_entrega_estimada': _fechaEntrega?.toIso8601String().substring(0, 10),
      'moneda': 'PEN',
      'observaciones': _observaciones.text.trim().isEmpty ? null : _observaciones.text.trim(),
      'detalles': lineas
          .map((l) => {'producto_presentacion_id': l.presentacionId, 'cantidad': l.cant, 'precio_unitario': l.precioVal})
          .toList(),
    };
    try {
      if (_editando) {
        await _api.put(ApiEndpoints.orden(widget.ordenId!), body: payload);
      } else {
        await _api.post(ApiEndpoints.ordenes, body: payload);
      }
      if (mounted) {
        showAppSnackbar(context, _editando ? 'Orden actualizada.' : 'Orden de compra creada.', type: AppSnackbarType.success);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _editando ? 'Editar Orden ${_codigo ?? ''}' : 'Nueva Orden de Compra',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    AppMessage(text: _error!),
                    const SizedBox(height: 12),
                  ],
                  AppFormSection(
                    title: 'Datos de la orden',
                    description: 'Pedido formal de productos al proveedor',
                    children: [
                      // Al crear no se muestra el código: lo asigna el backend.
                      if (_editando && _codigo != null)
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(text: _codigo),
                          decoration: const InputDecoration(labelText: 'Código', prefixIcon: Icon(Icons.tag)),
                        ),
                      AppSearchSelect<int>(
                        label: 'Proveedor',
                        hint: 'Buscar proveedor…',
                        icon: Icons.local_shipping_outlined,
                        value: _proveedorId,
                        options: [
                          for (final p in _proveedores)
                            AppSearchOption<int>(p['id'] as int, p['nombre']?.toString() ?? '', keywords: '${p['ruc'] ?? ''}'),
                        ],
                        onChanged: (v) => setState(() => _proveedorId = v),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.today_outlined),
                        title: const Text('Fecha de emisión'),
                        subtitle: Text(_fechaEmision.toIso8601String().substring(0, 10)),
                        onTap: () => _elegirFecha(entrega: false),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_available_outlined),
                        title: const Text('Entrega estimada'),
                        subtitle: Text(_fechaEntrega?.toIso8601String().substring(0, 10) ?? 'Sin fecha'),
                        trailing: _fechaEntrega == null
                            ? null
                            : IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _fechaEntrega = null)),
                        onTap: () => _elegirFecha(entrega: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppFormSection(
                    title: 'Buscar producto',
                    children: [
                      ProductoLineasPanel(
                        productos: _productos,
                        stockPorProducto: _stockPorProducto,
                        lineas: _lineas,
                        priceLabel: 'Precio',
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppFormSection(
                    title: 'Observaciones',
                    children: [AppTextArea(controller: _observaciones, label: 'Notas para el proveedor o internas…')],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Text(_money(_total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(label: _editando ? 'Guardar cambios' : 'Crear orden', loading: _saving, onPressed: _guardar),
                  const SizedBox(height: 8),
                  SecondaryButton(label: 'Cancelar', onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
    );
  }
}
