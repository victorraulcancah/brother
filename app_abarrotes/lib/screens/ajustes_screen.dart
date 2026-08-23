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
import '../widgets/app_segmented.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle.dart';
import '../widgets/data_card.dart';
import '../widgets/pdf_viewer_sheet.dart';
import '../utils/almacenes.dart';

String _money(dynamic v) =>
    'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';

String _num(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
}

String _fecha(dynamic v) => v == null ? '—' : '$v'.split('T').first;

({String label, AppBadgeType type}) _estadoInfo(String? e) => switch (e) {
  'aprobado' => (label: 'Aprobado', type: AppBadgeType.success),
  'rechazado' => (label: 'Rechazado', type: AppBadgeType.danger),
  _ => (label: 'Pendiente', type: AppBadgeType.warning),
};

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _almacenes = [];
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _existencias = [];
  List<Map<String, dynamic>> _motivos = [];
  List<Map<String, dynamic>> _proveedores = [];

  bool _loading = true;
  String? _error;
  String _busqueda = '';
  String? _filtroTipo;
  String? _filtroEstado;

  /// 0 = ajustes, 1 = motivos de movimiento de inventario.
  int _tab = 0;
  String _busquedaMotivo = '';
  String? _filtroMotivoTipo;
  String? _filtroMotivoEstado;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.ajustes);
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
        CrudService(_api, ApiEndpoints.almacenes).getAll(),
        CrudService(_api, '${ApiEndpoints.productos}?per_page=500').getAll(),
        CrudService(_api, ApiEndpoints.existencias).getAll(),
        CrudService(_api, '${ApiEndpoints.motivosMovimiento}?ambito=inventario').getAll(),
        CrudService(_api, ApiEndpoints.proveedores).getAll(),
      ]);
      _items = r[0];
      _almacenes = r[1];
      _productos = r[2];
      _existencias = r[3];
      _motivos = r[4];
      _proveedores = r[5];
    } catch (_) {
      _error = 'No se pudieron cargar los ajustes.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((a) {
      if (_filtroTipo != null && a['tipo'] != _filtroTipo) return false;
      if (_filtroEstado != null && a['estado'] != _filtroEstado) return false;
      if (q.isEmpty) return true;

      final almacen = (a['almacen'] as Map?)?['nombre'] ?? '';
      final prov = (a['proveedor'] as Map?)?['nombre'] ?? '';
      return '${a['documento'] ?? ''} ${a['motivo'] ?? ''} $almacen $prov'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  Future<void> _nuevo() async {
    final data = await showAppModal<Map<String, dynamic>>(
      context,
      title: 'Nuevo ajuste',
      child: _AjusteFormSheet(
        almacenes: _almacenes,
        productos: _productos,
        existencias: _existencias,
        motivos: _motivos,
        proveedores: _proveedores,
      ),
    );
    if (data == null) return;

    try {
      await _crud.create(data);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Ajuste creado y stock actualizado',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  /// El ajuste ya movió stock: solo se editan los datos descriptivos.
  /// Para cambiar almacén, tipo o cantidades hay que eliminarlo y rehacerlo.
  Future<void> _editar(Map<String, dynamic> item) async {
    final data = await showAppModal<Map<String, dynamic>>(
      context,
      title: 'Editar ${item['documento'] ?? 'ajuste'}',
      child: _EditarAjusteSheet(initial: item),
    );
    if (data == null) return;

    try {
      await _crud.update(item['id'], data);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Ajuste actualizado',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  Future<void> _eliminar(Map<String, dynamic> item) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Eliminar ajuste',
      message:
          '¿Eliminar ${item['documento'] ?? 'el ajuste'}? '
          'Se revertirá el stock que movió.',
    );
    if (!ok) return;

    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Ajuste eliminado y stock revertido',
          type: AppSnackbarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  Future<void> _verDetalle(Map<String, dynamic> item) async {
    final detalles = ((item['detalles'] as List?) ?? [])
        .whereType<Map>()
        .toList();

    await showAppModal<void>(
      context,
      title: 'Detalle ${item['documento'] ?? ''}',
      child: detalles.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Este ajuste no tiene productos.')),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final d in detalles) _detalleCard(d),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total'),
                      Text(
                        _money(item['total']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ─────────────────── Motivos de movimiento ───────────────────

  Future<void> _recargarMotivos() async {
    try {
      _motivos = await CrudService(_api, '${ApiEndpoints.motivosMovimiento}?ambito=inventario').getAll();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _motivosVisibles {
    final q = _busquedaMotivo.trim().toLowerCase();
    return _motivos.where((m) {
      if (_filtroMotivoTipo != null && m['tipo'] != _filtroMotivoTipo) return false;
      if (_filtroMotivoEstado != null) {
        final activo = m['activo'] != false;
        if ((_filtroMotivoEstado == 'activo') != activo) return false;
      }
      if (q.isEmpty) return true;
      return '${m['nombre'] ?? ''}'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _formMotivo({Map<String, dynamic>? item}) async {
    final data = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo motivo' : 'Editar motivo',
      child: _MotivoFormSheet(initial: item),
    );
    if (data == null) return;
    try {
      final crud = CrudService(_api, ApiEndpoints.motivosMovimiento);
      if (item != null) {
        await crud.update(item['id'], data);
      } else {
        await crud.create(data);
      }
      await _recargarMotivos();
      if (mounted) {
        showAppSnackbar(
          context,
          item == null ? 'Motivo creado' : 'Motivo actualizado',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  Future<void> _eliminarMotivo(Map<String, dynamic> m) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Eliminar motivo',
      message: '¿Eliminar el motivo "${m['nombre']}"?',
    );
    if (!ok) return;
    try {
      await CrudService(_api, ApiEndpoints.motivosMovimiento).delete(m['id']);
      await _recargarMotivos();
      if (mounted) {
        showAppSnackbar(context, 'Motivo eliminado', type: AppSnackbarType.error);
      }
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  Widget _listaMotivos() {
    return Column(
      children: [
        AppListHeader(
          hintText: 'Buscar motivos...',
          searchValue: _busquedaMotivo,
          onSearch: (v) => setState(() => _busquedaMotivo = v),
          filters: [
            AppListFilter(
              label: 'Tipo',
              value: _filtroMotivoTipo,
              options: const [
                AppListFilterOption(null, 'Todos'),
                AppListFilterOption('entrada', 'Entrada'),
                AppListFilterOption('salida', 'Salida'),
              ],
              onChanged: (v) => setState(() => _filtroMotivoTipo = v),
            ),
            AppListFilter(
              label: 'Estado',
              value: _filtroMotivoEstado,
              options: const [
                AppListFilterOption(null, 'Todos'),
                AppListFilterOption('activo', 'Activo'),
                AppListFilterOption('inactivo', 'Inactivo'),
              ],
              onChanged: (v) => setState(() => _filtroMotivoEstado = v),
            ),
          ],
          activeFilters:
              (_filtroMotivoTipo != null ? 1 : 0) +
              (_filtroMotivoEstado != null ? 1 : 0),
          onClearFilters: () => setState(() {
            _filtroMotivoTipo = null;
            _filtroMotivoEstado = null;
          }),
          resultCount: _motivosVisibles.length,
        ),
        Expanded(
          child: _motivosVisibles.isEmpty
              ? Center(
                  child: Text(
                    _motivos.isEmpty ? 'No hay motivos' : 'Ningún motivo coincide con la búsqueda',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _motivosVisibles.length,
                  itemBuilder: (context, index) {
                    final m = _motivosVisibles[index];
                    final sistema = m['es_sistema'] == true;
                    final activo = m['activo'] != false;
                    final esEntrada = m['tipo'] == 'entrada';
                    return DataCard(
                      title: m['nombre']?.toString() ?? '',
                      subtitle: '#${m['id'].toString().padLeft(3, '0')}',
                      rows: [
                        DataCardRow(
                          label: 'Tipo',
                          value: AppBadge(
                            esEntrada ? 'Entrada' : 'Salida',
                            type: esEntrada ? AppBadgeType.success : AppBadgeType.danger,
                          ),
                        ),
                        DataCardRow(
                          label: 'Origen',
                          value: AppBadge(
                            sistema ? 'Sistema' : 'Manual',
                            type: sistema ? AppBadgeType.info : AppBadgeType.neutral,
                          ),
                        ),
                        DataCardRow(
                          label: 'Estado',
                          value: AppBadge(
                            activo ? 'Activo' : 'Inactivo',
                            type: activo ? AppBadgeType.success : AppBadgeType.danger,
                          ),
                        ),
                      ],
                      // Los motivos del sistema son fijos: sin editar ni eliminar (igual que la web).
                      actions: sistema
                          ? const []
                          : [
                              DataCardAction(
                                icon: Icons.edit_outlined,
                                color: AppColors.primary,
                                tooltip: 'Editar',
                                onTap: () => _formMotivo(item: m),
                              ),
                              DataCardAction(
                                icon: Icons.delete_outline,
                                color: AppColors.danger,
                                tooltip: 'Eliminar',
                                onTap: () => _eliminarMotivo(m),
                              ),
                            ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _detalleCard(Map d) {
    final pres = d['presentacion'] as Map?;
    final producto = pres?['producto'] as Map?;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              producto?['nombre']?.toString() ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${producto?['codigo'] ?? '—'} · ${pres?['nombre'] ?? '—'}'
              '${(producto?['marca'] as Map?)?['nombre'] != null ? ' · ${(producto!['marca'] as Map)['nombre']}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: Text('Cant.: ${_num(d['cantidad'])}')),
                Expanded(child: Text('Costo: ${_money(d['costo_unitario'])}')),
                Expanded(
                  child: Text(
                    _money(d['subtotal']),
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
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
      title: 'Ajustes de Inventario',
      floatingActionButton: FloatingActionButton(
        onPressed: _tab == 0 ? _nuevo : () => _formMotivo(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AppMessage(text: _error!),
                  ),
                AppSegmented(
                  items: const ['Ajustes', 'Motivos'],
                  icons: const [Icons.tune_outlined, Icons.label_outline],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                Expanded(child: _tab == 0 ? _listaAjustes() : _listaMotivos()),
              ],
            ),
    );
  }

  Widget _listaAjustes() {
    return Column(
              children: [
                AppListHeader(
                  hintText: 'Buscar ajustes...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Tipo',
                      value: _filtroTipo,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('entrada', 'Entrada'),
                        AppListFilterOption('salida', 'Salida'),
                      ],
                      onChanged: (v) => setState(() => _filtroTipo = v),
                    ),
                    AppListFilter(
                      label: 'Estado',
                      value: _filtroEstado,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('pendiente', 'Pendiente'),
                        AppListFilterOption('aprobado', 'Aprobado'),
                        AppListFilterOption('rechazado', 'Rechazado'),
                      ],
                      onChanged: (v) => setState(() => _filtroEstado = v),
                    ),
                  ],
                  activeFilters:
                      (_filtroTipo != null ? 1 : 0) +
                      (_filtroEstado != null ? 1 : 0),
                  onClearFilters: () => setState(() {
                    _filtroTipo = null;
                    _filtroEstado = null;
                  }),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(
                          child: Text(
                            _items.isEmpty
                                ? 'No hay ajustes'
                                : 'Ningún ajuste coincide con la búsqueda',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _visibles.length,
                          itemBuilder: (context, index) {
                            final item = _visibles[index];
                            final esEntrada = item['tipo'] == 'entrada';
                            final estado = _estadoInfo(
                              item['estado']?.toString(),
                            );

                            return DataCard(
                              title:
                                  item['documento']?.toString() ??
                                  'Ajuste #${item['id']}',
                              subtitle: (item['almacen'] as Map?)?['nombre']
                                  ?.toString(),
                              onTap: () => _verDetalle(item),
                              rows: [
                                DataCardRow.text('Fecha', _fecha(item['fecha'])),
                                DataCardRow(
                                  label: 'T. Ingreso',
                                  value: AppBadge(
                                    esEntrada ? 'Entrada' : 'Salida',
                                    type: esEntrada
                                        ? AppBadgeType.success
                                        : AppBadgeType.danger,
                                  ),
                                ),
                                DataCardRow.text(
                                  'Motivo',
                                  item['motivo']?.toString() ?? '—',
                                ),
                                DataCardRow.text(
                                  'Proveedor',
                                  (item['proveedor'] as Map?)?['nombre']
                                          ?.toString() ??
                                      '—',
                                ),
                                DataCardRow.text(
                                  'Registra',
                                  (item['usuario_solicita']
                                          as Map?)?['name']
                                      ?.toString() ??
                                      '—',
                                ),
                                DataCardRow.text(
                                  'Productos',
                                  '${item['detalles_count'] ?? (item['detalles'] as List?)?.length ?? 0}',
                                ),
                                if (item['observaciones'] != null)
                                  DataCardRow.text(
                                    'Observación',
                                    item['observaciones'].toString(),
                                  ),
                                DataCardRow(
                                  label: 'Estado',
                                  value: AppBadge(
                                    estado.label,
                                    type: estado.type,
                                  ),
                                ),
                                DataCardRow.text('Total', _money(item['total'])),
                              ],
                              actions: [
                                DataCardAction(
                                  icon: Icons.picture_as_pdf_outlined,
                                  color: AppColors.textMuted,
                                  tooltip: 'Imprimir / PDF',
                                  onTap: () => mostrarPdf(context,
                                      tipo: 'ajuste',
                                      id: item['id'] as int,
                                      nombre: item['documento']?.toString() ?? '#${item['id']}',
                                      titulo: 'Ajuste de inventario',
                                      formatos: const ['a4', 'ticket']),
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
                                  onTap: () => _eliminar(item),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            );
  }
}

// ─────────────────────────── Formulario ───────────────────────────

/// Una línea del ajuste: producto + unidad derivada + cantidad.
class _Linea {
  int? productoId;
  int? presentacionId;
  final TextEditingController cantidad = TextEditingController(text: '1');

  void dispose() => cantidad.dispose();
}

class _AjusteFormSheet extends StatefulWidget {
  final List<Map<String, dynamic>> almacenes;
  final List<Map<String, dynamic>> productos;
  final List<Map<String, dynamic>> existencias;
  final List<Map<String, dynamic>> motivos;
  final List<Map<String, dynamic>> proveedores;

  const _AjusteFormSheet({
    required this.almacenes,
    required this.productos,
    required this.existencias,
    required this.motivos,
    required this.proveedores,
  });

  @override
  State<_AjusteFormSheet> createState() => _AjusteFormSheetState();
}

class _AjusteFormSheetState extends State<_AjusteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _almacenId;
  int? _proveedorId;
  String _tipo = 'entrada';
  String? _motivo;
  final _observaciones = TextEditingController();
  final List<_Linea> _lineas = [_Linea()];
  String? _error;

  @override
  void dispose() {
    _observaciones.dispose();
    for (final l in _lineas) {
      l.dispose();
    }
    super.dispose();
  }

  /// Motivos de inventario activos que aplican al tipo elegido.
  List<AppSelectOption<String>> get _motivosOptions => [
    for (final m in widget.motivos)
      if (m['activo'] != false &&
          m['tipo'] == _tipo &&
          (m['categoria_gasto'] == null))
        AppSelectOption<String>(
          m['nombre'].toString(),
          m['nombre'].toString(),
        ),
  ];

  /// Stock en unidad base de cada producto del almacén elegido.
  Map<int, double> get _stockDelAlmacen {
    if (_almacenId == null) return {};
    return {
      for (final e in widget.existencias)
        if (e['almacen_id'] == _almacenId)
          e['producto_id'] as int:
              double.tryParse('${e['stock_actual']}') ?? 0,
    };
  }

  /// Solo productos del almacén; en salidas además se exige stock.
  List<AppSelectOption<int>> get _productosOptions {
    final stock = _stockDelAlmacen;
    return [
      for (final p in widget.productos)
        if (stock.containsKey(p['id']) &&
            (_tipo != 'salida' || (stock[p['id']] ?? 0) > 0))
          AppSelectOption<int>(p['id'] as int, p['nombre']?.toString() ?? ''),
    ];
  }

  Map<String, dynamic>? _productoDe(int? id) {
    if (id == null) return null;
    for (final p in widget.productos) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  /// Unidades derivadas del producto, con el disponible ya convertido.
  List<({int id, String label, double factor, double disponible})> _unidadesDe(
    int? productoId,
  ) {
    final p = _productoDe(productoId);
    if (p == null) return [];

    final stockBase = _stockDelAlmacen[productoId] ?? 0;
    final abrev = (p['unidad_medida'] as Map?)?['abreviatura'] ?? '';

    return [
      for (final pres in (p['presentaciones'] as List? ?? []))
        if (pres['activo'] != false)
          () {
            final factor =
                double.tryParse('${pres['factor_conversion']}') ?? 1;
            return (
              id: pres['id'] as int,
              label: '${pres['nombre']} (x${_num(factor)} $abrev)',
              factor: factor,
              // El stock vive en unidad base: hay que convertirlo.
              disponible: (stockBase / factor * 100).floor() / 100,
            );
          }(),
    ];
  }

  double _disponibleDe(_Linea l) {
    for (final u in _unidadesDe(l.productoId)) {
      if (u.id == l.presentacionId) return u.disponible;
    }
    return 0;
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final detalles = <Map<String, dynamic>>[];
    for (final l in _lineas) {
      final cantidad = double.tryParse(l.cantidad.text.trim()) ?? 0;
      if (l.presentacionId == null || cantidad <= 0) continue;

      // El backend rechaza la salida si no alcanza; se avisa antes.
      if (_tipo == 'salida' && cantidad > _disponibleDe(l)) {
        final nombre = _productoDe(l.productoId)?['nombre'] ?? 'El producto';
        setState(() {
          _error = '"$nombre" solo tiene ${_num(_disponibleDe(l))} disponibles.';
        });
        return;
      }
      detalles.add({
        'producto_presentacion_id': l.presentacionId,
        'cantidad': cantidad,
      });
    }

    if (detalles.isEmpty) {
      setState(() => _error = 'Agrega al menos un producto con cantidad.');
      return;
    }

    Navigator.pop(context, {
      'almacen_id': _almacenId,
      'proveedor_id': _proveedorId,
      'tipo': _tipo,
      'motivo': _motivo,
      'observaciones': _observaciones.text.trim().isEmpty
          ? null
          : _observaciones.text.trim(),
      'detalles': detalles,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppMessage(text: _error!),
            ),

          AppFormSection(
            title: 'Datos del ajuste',
            children: [
              AppSelect<int>(
                label: 'Almacén',
                icon: Icons.warehouse_outlined,
                value: _almacenId,
                options: opcionesAlmacen(widget.almacenes, _almacenId),
                // Cambiar de almacén invalida los productos ya elegidos.
                onChanged: (v) => setState(() {
                  _almacenId = v;
                  for (final l in _lineas) {
                    l.dispose();
                  }
                  _lineas
                    ..clear()
                    ..add(_Linea());
                }),
                validator: (v) => v == null ? 'Elija el almacén' : null,
              ),
              AppSelect<String>(
                label: 'Tipo',
                icon: Icons.swap_vert,
                value: _tipo,
                options: const [
                  AppSelectOption('entrada', 'Entrada'),
                  AppSelectOption('salida', 'Salida'),
                ],
                onChanged: (v) => setState(() {
                  _tipo = v ?? 'entrada';
                  _motivo = null;
                  for (final l in _lineas) {
                    l.dispose();
                  }
                  _lineas
                    ..clear()
                    ..add(_Linea());
                }),
              ),
              AppSelect<String>(
                label: 'Motivo',
                icon: Icons.label_outline,
                value: _motivo,
                options: _motivosOptions,
                onChanged: (v) => setState(() => _motivo = v),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Elija el motivo' : null,
              ),
              AppSelect<int>(
                label: 'Proveedor (opcional)',
                icon: Icons.local_shipping_outlined,
                value: _proveedorId,
                options: [
                  for (final p in widget.proveedores)
                    AppSelectOption<int>(
                      p['id'] as int,
                      p['nombre']?.toString() ?? '',
                    ),
                ],
                onChanged: (v) => setState(() => _proveedorId = v),
              ),
              AppTextField(
                controller: _observaciones,
                label: 'Observaciones',
                icon: Icons.notes_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),

          AppFormSection(
            title: _tipo == 'salida' ? 'Productos a restar' : 'Productos a sumar',
            trailing: TextButton.icon(
              onPressed: _almacenId == null
                  ? null
                  : () => setState(() => _lineas.add(_Linea())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
            children: [
              if (_almacenId == null)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Elige un almacén para ver sus productos disponibles.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              else if (_productosOptions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _tipo == 'salida'
                        ? 'Este almacén no tiene productos con stock para restar.'
                        : 'Este almacén no tiene productos registrados.',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                )
              else
                for (var i = 0; i < _lineas.length; i++) _lineaCard(i),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Cancelar',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(label: 'Guardar', onPressed: _guardar),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lineaCard(int index) {
    final l = _lineas[index];
    final unidades = _unidadesDe(l.productoId);
    final disponible = _disponibleDe(l);
    final cantidad = double.tryParse(l.cantidad.text.trim()) ?? 0;
    final excede = _tipo == 'salida' && l.presentacionId != null && cantidad > disponible;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Producto ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (_lineas.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppColors.danger,
                      size: 20,
                    ),
                    onPressed: () => setState(() {
                      _lineas.removeAt(index).dispose();
                    }),
                  ),
              ],
            ),
            AppSelect<int>(
              label: 'Producto',
              value: l.productoId,
              options: _productosOptions,
              onChanged: (v) => setState(() {
                l.productoId = v;
                final us = _unidadesDe(v);
                // Con una sola unidad derivada, se elige sola.
                l.presentacionId = us.length == 1 ? us.first.id : null;
              }),
            ),
            AppSelect<int>(
              label: 'Unidad derivada',
              value: l.presentacionId,
              options: [
                for (final u in unidades) AppSelectOption<int>(u.id, u.label),
              ],
              onChanged: (v) => setState(() => l.presentacionId = v),
            ),
            if (l.presentacionId != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Disponible: ${_num(disponible)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            AppTextField(
              controller: l.cantidad,
              label: 'Cantidad',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              validator: (_) => excede ? 'Supera el stock' : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Solo estado y observaciones: el resto ya afectó el inventario.
class _EditarAjusteSheet extends StatefulWidget {
  final Map<String, dynamic> initial;

  const _EditarAjusteSheet({required this.initial});

  @override
  State<_EditarAjusteSheet> createState() => _EditarAjusteSheetState();
}

class _EditarAjusteSheetState extends State<_EditarAjusteSheet> {
  late String _estado;
  late final TextEditingController _observaciones;

  @override
  void initState() {
    super.initState();
    _estado = widget.initial['estado']?.toString() ?? 'pendiente';
    _observaciones = TextEditingController(
      text: widget.initial['observaciones']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _observaciones.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFormSection(
          title: 'Datos editables',
          children: [
            AppSelect<String>(
              label: 'Estado',
              icon: Icons.flag_outlined,
              value: _estado,
              options: const [
                AppSelectOption('pendiente', 'Pendiente'),
                AppSelectOption('aprobado', 'Aprobado'),
                AppSelectOption('rechazado', 'Rechazado'),
              ],
              onChanged: (v) => setState(() => _estado = v ?? 'pendiente'),
            ),
            AppTextField(
              controller: _observaciones,
              label: 'Observaciones',
              icon: Icons.notes_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Cancelar',
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Guardar',
                onPressed: () => Navigator.pop(context, {
                  'estado': _estado,
                  'observaciones': _observaciones.text.trim().isEmpty
                      ? null
                      : _observaciones.text.trim(),
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════ Formulario de motivo (inventario) ══════════════════

class _MotivoFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _MotivoFormSheet({this.initial});

  @override
  State<_MotivoFormSheet> createState() => _MotivoFormSheetState();
}

class _MotivoFormSheetState extends State<_MotivoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  String _tipo = 'entrada';
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre']?.toString() ?? '');
    _tipo = widget.initial?['tipo']?.toString() ?? 'entrada';
    _activo = widget.initial?['activo'] != false;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(
            title: 'Datos del motivo',
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.label_outline,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null,
              ),
              AppSelect<String>(
                label: 'Tipo de movimiento',
                icon: Icons.swap_vert,
                value: _tipo,
                options: const [
                  AppSelectOption('entrada', 'Entrada'),
                  AppSelectOption('salida', 'Salida'),
                ],
                onChanged: (v) => setState(() => _tipo = v ?? 'entrada'),
              ),
              AppToggle(
                label: 'Motivo activo',
                subtitle: 'Solo los activos aparecen al crear ajustes',
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Cancelar', onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Guardar',
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    Navigator.pop(context, {
                      'nombre': _nombre.text.trim(),
                      'tipo': _tipo,
                      'activo': _activo,
                      // Motivo de inventario (no de caja).
                      'ambito': 'inventario',
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
