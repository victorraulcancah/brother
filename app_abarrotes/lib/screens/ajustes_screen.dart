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
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';

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
        CrudService(_api, ApiEndpoints.motivosMovimiento).getAll(),
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
        onPressed: _nuevo,
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
            ),
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
                options: [
                  for (final a in widget.almacenes)
                    AppSelectOption<int>(
                      a['id'] as int,
                      a['nombre']?.toString() ?? '',
                    ),
                ],
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
