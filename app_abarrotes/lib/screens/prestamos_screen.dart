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
import '../widgets/data_card.dart';
import '../widgets/pdf_viewer_sheet.dart';
import '../utils/almacenes.dart';

String _num(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
}

String _fecha(dynamic v) => v == null ? '—' : '$v'.split('T').first;
String _hoy() => DateTime.now().toIso8601String().substring(0, 10);

const _estadoLabel = {
  'prestado': 'Prestado',
  'parcial': 'Parcial',
  'devuelto': 'Devuelto',
};

AppBadgeType _estadoBadge(String? e) => switch (e) {
  'parcial' => AppBadgeType.warning,
  'devuelto' => AppBadgeType.success,
  _ => AppBadgeType.info,
};

/// Devolución esperada ya pasada y aún con saldo.
bool _vencido(Map p) =>
    p['estado'] != 'devuelto' &&
    p['fecha_devolucion_esperada'] != null &&
    _fecha(p['fecha_devolucion_esperada']).compareTo(_hoy()) < 0;

/// Préstamos de mercadería (la tienda presta / le prestan): documento
/// numerado PR01-… con detalle, devoluciones parciales e historial.
class PrestamosScreen extends StatefulWidget {
  const PrestamosScreen({super.key});

  @override
  State<PrestamosScreen> createState() => _PrestamosScreenState();
}

class _PrestamosScreenState extends State<PrestamosScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _almacenes = [];
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _existencias = [];

  bool _loading = true;
  String? _error;
  String _busqueda = '';
  String? _filtroEstado;
  String? _filtroAlmacen;

  /// 0 = presté, 1 = me prestaron.
  int _tab = 0;
  String get _tipoTab => _tab == 0 ? 'prestado' : 'recibido';

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.prestamos);
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
      ]);
      _items = r[0];
      _almacenes = r[1];
      _productos = r[2];
      _existencias = r[3];
    } catch (e) {
      _error = 'No se pudieron cargar los préstamos: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((p) {
      if (p['tipo'] != _tipoTab) return false;
      if (_filtroEstado == 'vencido') {
        if (!_vencido(p)) return false;
      } else if (_filtroEstado != null && p['estado'] != _filtroEstado) {
        return false;
      }
      if (_filtroAlmacen != null && '${p['almacen_id']}' != _filtroAlmacen) return false;
      if (q.isEmpty) return true;
      return '${p['documento'] ?? ''} ${p['tercero'] ?? ''} ${p['tercero_documento'] ?? ''} ${(p['almacen'] as Map?)?['nombre'] ?? ''}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  // ─────────────────────────── Acciones ───────────────────────────

  Future<void> _nuevo() async {
    final ok = await showAppModal<bool>(
      context,
      title: 'Nuevo préstamo',
      child: _PrestamoFormSheet(
        api: _api,
        almacenes: _almacenes,
        productos: _productos,
        existencias: _existencias,
        tipoInicial: _tipoTab,
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _editar(Map<String, dynamic> item) async {
    final ok = await showAppModal<bool>(
      context,
      title: 'Editar ${item['documento'] ?? 'préstamo'}',
      child: _PrestamoFormSheet(
        api: _api,
        almacenes: _almacenes,
        productos: _productos,
        existencias: _existencias,
        tipoInicial: item['tipo']?.toString() ?? 'prestado',
        initial: item,
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _devolucion(Map<String, dynamic> item) async {
    final ok = await showAppModal<bool>(
      context,
      title: 'Devolución ${item['documento'] ?? ''}',
      child: _DevolucionSheet(api: _api, prestamo: item),
    );
    if (ok == true) _load();
  }

  Future<void> _eliminar(Map<String, dynamic> item) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Eliminar préstamo',
      message:
          '¿Eliminar el préstamo ${item['documento'] ?? ''} con "${item['tercero']}"? '
          'El stock pendiente de devolver se revertirá en el almacén.',
    );
    if (!ok) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(context, 'Préstamo eliminado y stock revertido', type: AppSnackbarType.error);
      }
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  Future<void> _verDetalle(Map<String, dynamic> p) async {
    final detalles = ((p['detalles'] as List?) ?? []).whereType<Map>().toList();
    final devoluciones = ((p['devoluciones'] as List?) ?? []).whereType<Map>().toList();
    await showAppModal<void>(
      context,
      title: 'Detalle ${p['documento'] ?? ''}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${p['tipo'] == 'prestado' ? 'Presté a' : 'Me prestó'}: ${p['tercero'] ?? '—'}'),
          if (p['tercero_documento'] != null || p['tercero_telefono'] != null)
            Text([p['tercero_documento'], p['tercero_telefono']].where((x) => x != null).join(' · ')),
          Text('Almacén: ${(p['almacen'] as Map?)?['nombre'] ?? '—'} · Registró: ${(p['usuario'] as Map?)?['name'] ?? '—'}'),
          if (p['fecha_devolucion'] != null) Text('Devuelto el: ${_fecha(p['fecha_devolucion'])}'),
          if (p['observaciones'] != null) Text('Obs.: ${p['observaciones']}'),
          const SizedBox(height: 12),
          if (detalles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Este préstamo no tiene artículos.')),
            ),
          for (final d in detalles) _detalleCard(d),
          if (devoluciones.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Historial de devoluciones', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            for (final dv in devoluciones)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${_fecha(dv['fecha'])} · ${((dv['presentacion'] as Map?)?['producto'] as Map?)?['nombre'] ?? 'Producto'}'
                  ' — ${(dv['presentacion'] as Map?)?['nombre'] ?? ''}: ${_num(dv['cantidad'])}'
                  '${(dv['usuario'] as Map?)?['name'] != null ? ' (${(dv['usuario'] as Map)['name']})' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _detalleCard(Map d) {
    final pres = d['presentacion'] as Map?;
    final producto = pres?['producto'] as Map?;
    final pend = double.tryParse('${d['cantidad_pendiente'] ?? 0}') ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto?['nombre']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${producto?['codigo'] ?? '—'} · ${pres?['nombre'] ?? '—'}'
                    '${(producto?['marca'] as Map?)?['nombre'] != null ? ' · ${(producto!['marca'] as Map)['nombre']}' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Prest. ${_num(d['cantidad_prestada'])}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                Text('Dev. ${_num(d['cantidad_devuelta'])}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                AppBadge('Pend. ${_num(pend)}', type: pend > 0 ? AppBadgeType.warning : AppBadgeType.success),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Préstamos',
      floatingActionButton: FloatingActionButton(onPressed: _nuevo, child: const Icon(Icons.add)),
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
                  items: const ['Presté', 'Me prestaron'],
                  icons: const [Icons.volunteer_activism_outlined, Icons.handshake_outlined],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                AppListHeader(
                  hintText: 'Buscar por documento o tercero...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Estado',
                      value: _filtroEstado,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('prestado', 'Prestado'),
                        AppListFilterOption('parcial', 'Parcial'),
                        AppListFilterOption('devuelto', 'Devuelto'),
                        AppListFilterOption('vencido', 'Vencidos'),
                      ],
                      onChanged: (v) => setState(() => _filtroEstado = v),
                    ),
                    AppListFilter(
                      label: 'Almacén',
                      value: _filtroAlmacen,
                      options: [
                        const AppListFilterOption(null, 'Todos'),
                        for (final a in _almacenes) AppListFilterOption('${a['id']}', a['nombre']?.toString() ?? ''),
                      ],
                      onChanged: (v) => setState(() => _filtroAlmacen = v),
                    ),
                  ],
                  activeFilters: (_filtroEstado != null ? 1 : 0) + (_filtroAlmacen != null ? 1 : 0),
                  onClearFilters: () => setState(() {
                    _filtroEstado = null;
                    _filtroAlmacen = null;
                  }),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(child: Text(_items.isEmpty ? 'No hay préstamos' : 'Ningún préstamo coincide con la búsqueda'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _visibles.length,
                          itemBuilder: (context, index) {
                            final item = _visibles[index];
                            final estado = item['estado'] as String?;
                            final detalles = ((item['detalles'] as List?) ?? []).whereType<Map>();
                            final total = detalles.fold<double>(0, (s, d) => s + (double.tryParse('${d['cantidad_prestada']}') ?? 0));
                            final dev = detalles.fold<double>(0, (s, d) => s + (double.tryParse('${d['cantidad_devuelta'] ?? 0}') ?? 0));
                            final vencido = _vencido(item);

                            return DataCard(
                              title: item['documento']?.toString() ?? '#${item['id']}',
                              subtitle: '${_tab == 0 ? 'Presté a' : 'Me prestó'} ${item['tercero'] ?? '—'}'
                                  '${item['tercero_documento'] != null ? ' · ${item['tercero_documento']}' : ''}',
                              onTap: () => _verDetalle(item),
                              rows: [
                                DataCardRow.text('Fecha', _fecha(item['fecha_prestamo'])),
                                DataCardRow.text('Almacén', (item['almacen'] as Map?)?['nombre']?.toString() ?? '—'),
                                DataCardRow(
                                  label: 'Dev. esperada',
                                  value: Text(
                                    '${vencido ? '⚠ ' : ''}${_fecha(item['fecha_devolucion_esperada'])}',
                                    style: TextStyle(
                                      fontWeight: vencido ? FontWeight.w700 : FontWeight.w500,
                                      color: vencido ? AppColors.danger : AppColors.textStrong,
                                    ),
                                  ),
                                ),
                                DataCardRow(
                                  label: 'Devuelto',
                                  value: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 70,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: total > 0 ? (dev / total).clamp(0, 1) : 0,
                                            minHeight: 6,
                                            backgroundColor: AppColors.border,
                                            color: dev >= total && total > 0 ? AppColors.success : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${_num(dev)} / ${_num(total)}', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                DataCardRow(
                                  label: 'Estado',
                                  value: AppBadge(_estadoLabel[estado] ?? estado ?? '—', type: _estadoBadge(estado)),
                                ),
                              ],
                              actions: [
                              DataCardAction(
                                  icon: Icons.picture_as_pdf_outlined,
                                  color: AppColors.textMuted,
                                  tooltip: 'Imprimir / PDF',
                                  onTap: () => mostrarPdf(context,
                                      tipo: 'prestamo',
                                      id: item['id'] as int,
                                      nombre: item['documento']?.toString() ?? '#${item['id']}',
                                      titulo: 'Préstamo',
                                      formatos: const ['a4', 'ticket']),
                              ),
                                                              if (estado != 'devuelto')
                                  DataCardAction(
                                    icon: Icons.undo,
                                    color: AppColors.warning,
                                    tooltip: 'Registrar devolución',
                                    onTap: () => _devolucion(item),
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
                                  tooltip: 'Eliminar (revierte stock pendiente)',
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

// ═══════════════════════ Formulario de préstamo ═══════════════════════

class _Linea {
  int? productoId;
  int? presentacionId;
  final TextEditingController cantidad = TextEditingController(text: '1');
  double get cant => double.tryParse(cantidad.text.trim()) ?? 0;
  void dispose() => cantidad.dispose();
}

class _PrestamoFormSheet extends StatefulWidget {
  final ApiService api;
  final List<Map<String, dynamic>> almacenes;
  final List<Map<String, dynamic>> productos;
  final List<Map<String, dynamic>> existencias;
  final String tipoInicial;
  final Map<String, dynamic>? initial;

  const _PrestamoFormSheet({
    required this.api,
    required this.almacenes,
    required this.productos,
    required this.existencias,
    required this.tipoInicial,
    this.initial,
  });

  @override
  State<_PrestamoFormSheet> createState() => _PrestamoFormSheetState();
}

class _PrestamoFormSheetState extends State<_PrestamoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  late String _tipo = widget.tipoInicial;
  int? _almacenId;
  DateTime _fechaPrestamo = DateTime.now();
  DateTime? _fechaEsperada;
  final _tercero = TextEditingController();
  final _terceroDoc = TextEditingController();
  final _terceroTel = TextEditingController();
  final _observaciones = TextEditingController();
  final List<_Linea> _lineas = [_Linea()];

  bool get _editando => widget.initial != null;
  bool get _esPrestado => _tipo == 'prestado';

  /// Con devoluciones registradas ya no se corrigen los datos del tercero.
  bool get _terceroBloqueado => _editando && ((widget.initial!['devoluciones'] as List?)?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _almacenId = int.tryParse('${i['almacen_id']}');
      _fechaPrestamo = DateTime.tryParse('${i['fecha_prestamo']}') ?? DateTime.now();
      _fechaEsperada = i['fecha_devolucion_esperada'] == null ? null : DateTime.tryParse('${i['fecha_devolucion_esperada']}');
      _tercero.text = i['tercero']?.toString() ?? '';
      _terceroDoc.text = i['tercero_documento']?.toString() ?? '';
      _terceroTel.text = i['tercero_telefono']?.toString() ?? '';
      _observaciones.text = i['observaciones']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [_tercero, _terceroDoc, _terceroTel, _observaciones]) {
      c.dispose();
    }
    for (final l in _lineas) {
      l.dispose();
    }
    super.dispose();
  }

  // ── Stock del almacén (unidad base); solo limita cuando la tienda presta ──
  Map<int, double> get _stockAlmacen {
    if (_almacenId == null) return {};
    return {
      for (final e in widget.existencias)
        if (e['almacen_id'] == _almacenId) e['producto_id'] as int: double.tryParse('${e['stock_actual']}') ?? 0,
    };
  }

  List<AppSelectOption<int>> get _productosOptions {
    final st = _stockAlmacen;
    return [
      for (final p in widget.productos)
        if (!_esPrestado || (st[p['id']] ?? 0) > 0) AppSelectOption<int>(p['id'] as int, p['nombre']?.toString() ?? ''),
    ];
  }

  Map<String, dynamic>? _productoDe(int? id) {
    if (id == null) return null;
    for (final p in widget.productos) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  List<({int id, String label, double disponible})> _unidadesDe(int? productoId) {
    final p = _productoDe(productoId);
    if (p == null) return [];
    final base = _stockAlmacen[productoId] ?? 0;
    return [
      for (final pres in (p['presentaciones'] as List? ?? []))
        if (pres['activo'] != false)
          () {
            final factor = double.tryParse('${pres['factor_conversion']}') ?? 1;
            return (id: pres['id'] as int, label: pres['nombre']?.toString() ?? '', disponible: (base / factor * 100).floor() / 100);
          }(),
    ];
  }

  double _disponibleDe(_Linea l) {
    for (final u in _unidadesDe(l.productoId)) {
      if (u.id == l.presentacionId) return u.disponible;
    }
    return 0;
  }

  void _reiniciarLineas() {
    for (final l in _lineas) {
      l.dispose();
    }
    _lineas
      ..clear()
      ..add(_Linea());
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final tercero = {
      'tercero': _tercero.text.trim(),
      'tercero_documento': _terceroDoc.text.trim().isEmpty ? null : _terceroDoc.text.trim(),
      'tercero_telefono': _terceroTel.text.trim().isEmpty ? null : _terceroTel.text.trim(),
    };
    final comunes = {
      'fecha_devolucion_esperada': _fechaEsperada?.toIso8601String().substring(0, 10),
      'observaciones': _observaciones.text.trim().isEmpty ? null : _observaciones.text.trim(),
    };

    try {
      if (_editando) {
        await widget.api.put(ApiEndpoints.prestamo(widget.initial!['id']), body: {
          if (!_terceroBloqueado) ...tercero,
          ...comunes,
        });
      } else {
        if (_almacenId == null) throw Exception('Elige el almacén.');
        final detalles = <Map<String, dynamic>>[];
        for (final l in _lineas) {
          if (l.presentacionId == null || l.cant <= 0) continue;
          if (_esPrestado && l.cant > _disponibleDe(l)) {
            throw Exception('"${_productoDe(l.productoId)?['nombre']}" supera el stock del almacén (${_num(_disponibleDe(l))}).');
          }
          detalles.add({'producto_presentacion_id': l.presentacionId, 'cantidad_prestada': l.cant});
        }
        if (detalles.isEmpty) throw Exception('Agrega al menos un artículo.');

        await widget.api.post(ApiEndpoints.prestamos, body: {
          'tipo': _tipo,
          'almacen_id': _almacenId,
          'fecha_prestamo': _fechaPrestamo.toIso8601String().substring(0, 10),
          ...tercero,
          ...comunes,
          'detalles': detalles,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = '$e'.replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _elegirFecha({required bool esperada}) async {
    final d = await showDatePicker(
      context: context,
      initialDate: esperada ? (_fechaEsperada ?? _fechaPrestamo) : _fechaPrestamo,
      firstDate: esperada ? _fechaPrestamo : DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      if (esperada) {
        _fechaEsperada = d;
      } else {
        _fechaPrestamo = d;
        if (_fechaEsperada != null && _fechaEsperada!.isBefore(d)) _fechaEsperada = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            AppMessage(text: _error!),
            const SizedBox(height: 12),
          ],
          if (_editando) ...[
            AppMessage(
              text: _terceroBloqueado
                  ? 'Con devoluciones registradas solo se cambia la fecha esperada y las observaciones.'
                  : 'Los artículos no se modifican; para corregirlos elimina y vuelve a registrar.',
              type: AppMessageType.success,
            ),
            const SizedBox(height: 12),
          ],

          AppFormSection(
            title: 'Préstamo',
            children: [
              AppSelect<String>(
                label: 'Dirección',
                icon: Icons.swap_horiz,
                value: _tipo,
                options: const [
                  AppSelectOption('prestado', 'Presté (la tienda presta)'),
                  AppSelectOption('recibido', 'Me prestaron (la tienda recibe)'),
                ],
                onChanged: _editando
                    ? null
                    : (v) => setState(() {
                        _tipo = v ?? 'prestado';
                        _reiniciarLineas();
                      }),
              ),
              AppSelect<int>(
                label: 'Almacén',
                icon: Icons.warehouse_outlined,
                value: _almacenId,
                options: opcionesAlmacen(widget.almacenes, _almacenId),
                onChanged: _editando
                    ? null
                    : (v) => setState(() {
                        _almacenId = v;
                        _reiniciarLineas();
                      }),
                validator: (v) => v == null ? 'Elija el almacén' : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: !_editando,
                leading: const Icon(Icons.today_outlined),
                title: const Text('Fecha del préstamo'),
                subtitle: Text(_fechaPrestamo.toIso8601String().substring(0, 10)),
                onTap: _editando ? null : () => _elegirFecha(esperada: false),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('Devolución esperada'),
                subtitle: Text(_fechaEsperada?.toIso8601String().substring(0, 10) ?? 'Sin fecha'),
                trailing: _fechaEsperada == null
                    ? null
                    : IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _fechaEsperada = null)),
                onTap: () => _elegirFecha(esperada: true),
              ),
            ],
          ),
          const SizedBox(height: 12),

          AppFormSection(
            title: _esPrestado ? 'A quién se presta' : 'Quién presta',
            children: [
              AppTextField(
                controller: _tercero,
                label: 'Nombre / razón social *',
                icon: Icons.person_outline,
                enabled: !_terceroBloqueado,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Indica con quién se realiza el préstamo' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _terceroDoc,
                      label: 'DNI / RUC',
                      keyboardType: TextInputType.number,
                      enabled: !_terceroBloqueado,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextField(
                      controller: _terceroTel,
                      label: 'Teléfono',
                      keyboardType: TextInputType.phone,
                      enabled: !_terceroBloqueado,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!_editando)
            AppFormSection(
              title: 'Artículos',
              trailing: TextButton.icon(
                onPressed: _almacenId == null ? null : () => setState(() => _lineas.add(_Linea())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
              ),
              children: [
                if (_almacenId == null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _esPrestado ? 'Elige el almacén para ver sus productos con stock.' : 'Elige el almacén al que ingresará la mercadería.',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else if (_productosOptions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Este almacén no tiene productos con stock.', style: TextStyle(color: AppColors.textMuted)),
                  )
                else
                  for (var i = 0; i < _lineas.length; i++) _lineaCard(i),
              ],
            ),
          if (!_editando) const SizedBox(height: 12),

          AppFormSection(
            title: 'Observaciones',
            children: [AppTextField(controller: _observaciones, label: 'Observaciones (opcional)', icon: Icons.notes_outlined)],
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Cancelar', onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: _editando ? 'Guardar' : 'Registrar préstamo',
                  loading: _saving,
                  onPressed: _guardar,
                ),
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
    final disp = _disponibleDe(l);
    final excede = _esPrestado && l.presentacionId != null && l.cant > disp;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('Artículo ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (_lineas.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                    onPressed: () => setState(() => _lineas.removeAt(index).dispose()),
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
                l.presentacionId = us.length == 1 ? us.first.id : null;
              }),
            ),
            AppSelect<int>(
              label: 'Unidad',
              value: l.presentacionId,
              options: [
                for (final u in unidades)
                  AppSelectOption<int>(u.id, _esPrestado ? '${u.label} (disp. ${_num(u.disponible)})' : u.label),
              ],
              onChanged: (v) => setState(() => l.presentacionId = v),
            ),
            AppTextField(
              controller: l.cantidad,
              label: 'Cantidad',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (_) => excede ? 'Supera el stock del almacén' : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════ Devolución (por artículo) ═══════════════════════

class _DevolucionSheet extends StatefulWidget {
  final ApiService api;
  final Map<String, dynamic> prestamo;
  const _DevolucionSheet({required this.api, required this.prestamo});

  @override
  State<_DevolucionSheet> createState() => _DevolucionSheetState();
}

class _DevolucionSheetState extends State<_DevolucionSheet> {
  late final List<Map> _pendientes = ((widget.prestamo['detalles'] as List?) ?? [])
      .whereType<Map>()
      .where((d) => (double.tryParse('${d['cantidad_pendiente'] ?? 0}') ?? 0) > 0)
      .toList();
  late final Map<int, TextEditingController> _cant = {
    for (final d in _pendientes) d['producto_presentacion_id'] as int: TextEditingController(),
  };
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _cant.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _pend(Map d) => double.tryParse('${d['cantidad_pendiente'] ?? 0}') ?? 0;

  void _devolverTodo() {
    for (final d in _pendientes) {
      _cant[d['producto_presentacion_id']]!.text = _num(_pend(d));
    }
    setState(() {});
  }

  Future<void> _guardar() async {
    final items = <Map<String, dynamic>>[];
    for (final d in _pendientes) {
      final c = double.tryParse(_cant[d['producto_presentacion_id']]!.text.trim()) ?? 0;
      if (c <= 0) continue;
      if (c > _pend(d) + 0.0001) {
        setState(() => _error = 'La cantidad de "${((d['presentacion'] as Map?)?['producto'] as Map?)?['nombre'] ?? 'un artículo'}" supera lo pendiente.');
        return;
      }
      items.add({'producto_presentacion_id': d['producto_presentacion_id'], 'cantidad': c});
    }
    if (items.isEmpty) {
      setState(() => _error = 'Indica la cantidad a devolver de al menos un artículo.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.post('${ApiEndpoints.prestamos}/${widget.prestamo['id']}/devoluciones', body: {'items': items});
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = '$e'.replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prestamo;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${p['tercero'] ?? ''} — ${p['tipo'] == 'prestado' ? 'me devuelve mercadería (entra al almacén)' : 'devuelvo la mercadería (sale del almacén)'}',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        if (_error != null) ...[
          AppMessage(text: _error!),
          const SizedBox(height: 12),
        ],
        if (_pendientes.isEmpty)
          const AppMessage(text: 'Este préstamo ya está devuelto por completo.', type: AppMessageType.success)
        else ...[
          Row(
            children: [
              const Expanded(
                child: Text('Indica cuánto se devuelve de cada artículo; deja en blanco los que aún no vuelven.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
              TextButton(onPressed: _devolverTodo, child: const Text('Devolver todo')),
            ],
          ),
          for (final d in _pendientes)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(((d['presentacion'] as Map?)?['producto'] as Map?)?['nombre']?.toString() ?? 'Producto', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '${(d['presentacion'] as Map?)?['nombre'] ?? ''} · prestado ${_num(d['cantidad_prestada'])} · pendiente ${_num(_pend(d))}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: AppTextField(
                        controller: _cant[d['producto_presentacion_id']]!,
                        label: 'Devuelve',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() => _error = null),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SecondaryButton(label: 'Cerrar', onPressed: () => Navigator.pop(context))),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Registrar devolución',
                loading: _saving,
                onPressed: _pendientes.isEmpty ? null : _guardar,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
