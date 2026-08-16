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

String _num(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
}

String _fecha(dynamic v) => v == null ? '—' : '$v'.split('T').first;

const _estadoLabel = {
  'pendiente': 'Pendiente',
  'en_transito': 'En tránsito',
  'recibida': 'Recibida',
  'cancelada': 'Cancelada',
};

AppBadgeType _estadoBadge(String? e) => switch (e) {
  'en_transito' => AppBadgeType.info,
  'recibida' => AppBadgeType.success,
  'cancelada' => AppBadgeType.danger,
  _ => AppBadgeType.warning,
};

/// Guías de traslado entre almacenes: documento interno numerado (T001-…)
/// con motivo, datos del transporte y detalle de productos.
class TrasladosScreen extends StatefulWidget {
  const TrasladosScreen({super.key});

  @override
  State<TrasladosScreen> createState() => _TrasladosScreenState();
}

class _TrasladosScreenState extends State<TrasladosScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _almacenes = [];
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _existencias = [];
  List<Map<String, dynamic>> _motivos = [];

  bool _loading = true;
  String? _error;
  String _busqueda = '';
  String? _filtroEstado;

  /// 0 = guías, 1 = motivos de traslado.
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.transferencias);
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
        CrudService(_api, ApiEndpoints.motivosTraslado).getAll(),
      ]);
      _items = r[0];
      _almacenes = r[1];
      _productos = r[2];
      _existencias = r[3];
      _motivos = r[4];
    } catch (e) {
      _error = 'No se pudieron cargar las guías: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _recargarMotivos() async {
    try {
      _motivos = await CrudService(_api, ApiEndpoints.motivosTraslado).getAll();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  String _motivoNombre(dynamic codigo) {
    for (final m in _motivos) {
      if (m['codigo'] == codigo) return m['nombre']?.toString() ?? '$codigo';
    }
    return codigo?.toString() ?? '—';
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((t) {
      if (_filtroEstado != null && t['estado'] != _filtroEstado) return false;
      if (q.isEmpty) return true;
      final o = (t['almacen_origen'] as Map?)?['nombre'] ?? '';
      final d = (t['almacen_destino'] as Map?)?['nombre'] ?? '';
      return '${t['documento'] ?? ''} $o $d ${t['vehiculo_placa'] ?? ''}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  // ─────────────────────────── Guías ───────────────────────────

  Future<void> _nueva() async {
    final ok = await showAppModal<bool>(
      context,
      title: 'Nueva guía de traslado',
      child: _GuiaFormSheet(
        api: _api,
        almacenes: _almacenes,
        productos: _productos,
        existencias: _existencias,
        motivos: _motivos,
        onMotivosCambiaron: _recargarMotivos,
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _editar(Map<String, dynamic> item) async {
    final ok = await showAppModal<bool>(
      context,
      title: 'Editar guía ${item['documento'] ?? ''}',
      child: _GuiaFormSheet(
        api: _api,
        almacenes: _almacenes,
        productos: _productos,
        existencias: _existencias,
        motivos: _motivos,
        onMotivosCambiaron: _recargarMotivos,
        initial: item,
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _accion(Map<String, dynamic> item, String accion, String exito) async {
    try {
      await _api.post('${ApiEndpoints.transferencias}/${item['id']}/$accion', body: {});
      await _load();
      if (mounted) showAppSnackbar(context, exito, type: AppSnackbarType.success);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  Future<void> _anular(Map<String, dynamic> item) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Anular guía',
      message: '¿Anular la guía ${item['documento'] ?? ''}?',
      confirmText: 'Anular',
    );
    if (ok) await _accion(item, 'anular', 'Guía anulada.');
  }

  Future<void> _eliminar(Map<String, dynamic> item) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Eliminar guía',
      message:
          '¿Eliminar la guía ${item['documento'] ?? item['id']}? '
          'Solo se pueden eliminar guías pendientes; no afecta al stock.',
    );
    if (!ok) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(context, 'Guía eliminada', type: AppSnackbarType.error);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  Future<void> _verDetalle(Map<String, dynamic> t) async {
    final detalles = ((t['detalles'] as List?) ?? []).whereType<Map>().toList();
    await showAppModal<void>(
      context,
      title: 'Detalle ${t['documento'] ?? ''}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Motivo: ${_motivoNombre(t['motivo_traslado'])}'),
          Text(
            'Transporte: ${t['modalidad_transporte'] == 'publico' ? 'Público' : 'Privado'}'
            '${t['vehiculo_placa'] != null ? ' · Placa ${t['vehiculo_placa']}' : ''}',
          ),
          if (t['conductor_nombre'] != null)
            Text('Conductor: ${t['conductor_nombre']}'),
          if (t['transportista_razon_social'] != null)
            Text('Transportista: ${t['transportista_razon_social']} (${t['transportista_ruc'] ?? '-'})'),
          if (t['numero_bultos'] != null || t['peso_bruto_kg'] != null)
            Text(
              'Bultos: ${t['numero_bultos'] ?? '—'} · Peso: ${t['peso_bruto_kg'] != null ? '${_num(t['peso_bruto_kg'])} kg' : '—'}',
            ),
          const SizedBox(height: 12),
          if (detalles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Esta guía no tiene productos.')),
            ),
          for (final d in detalles) _detalleCard(d),
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
        child: Row(
          children: [
            Expanded(
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
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Env. ${_num(d['cantidad_enviada'])}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
                Text(
                  'Rec. ${d['cantidad_recibida'] != null ? _num(d['cantidad_recibida']) : '—'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────── Motivos ──────────────────────────

  Future<void> _formMotivo({Map<String, dynamic>? item}) async {
    final data = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo motivo de traslado' : 'Editar motivo',
      child: _MotivoFormSheet(initial: item),
    );
    if (data == null) return;
    try {
      final crud = CrudService(_api, ApiEndpoints.motivosTraslado);
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
      message:
          '¿Eliminar "${m['nombre']}"? Si alguna guía lo usa, se desactivará '
          'en lugar de eliminarse.',
    );
    if (!ok) return;
    try {
      final res = await _api.delete('${ApiEndpoints.motivosTraslado}/${m['id']}');
      await _recargarMotivos();
      if (mounted) {
        showAppSnackbar(
          context,
          res['desactivado'] == true
              ? 'El motivo estaba en uso: se desactivó'
              : 'Motivo eliminado',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  // ─────────────────────────── Build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Guías de Traslado',
      floatingActionButton: FloatingActionButton(
        onPressed: _tab == 0 ? _nueva : () => _formMotivo(),
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
                  items: const ['Guías', 'Motivos de traslado'],
                  icons: const [Icons.local_shipping_outlined, Icons.label_outline],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                Expanded(child: _tab == 0 ? _listaGuias() : _listaMotivos()),
              ],
            ),
    );
  }

  Widget _listaGuias() {
    return Column(
      children: [
        AppListHeader(
          hintText: 'Buscar guías...',
          searchValue: _busqueda,
          onSearch: (v) => setState(() => _busqueda = v),
          filters: [
            AppListFilter(
              label: 'Estado',
              value: _filtroEstado,
              options: const [
                AppListFilterOption(null, 'Todos'),
                AppListFilterOption('pendiente', 'Pendiente'),
                AppListFilterOption('en_transito', 'En tránsito'),
                AppListFilterOption('recibida', 'Recibida'),
                AppListFilterOption('cancelada', 'Cancelada'),
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
                  child: Text(
                    _items.isEmpty ? 'No hay guías' : 'Ninguna guía coincide con la búsqueda',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _visibles.length,
                  itemBuilder: (context, index) {
                    final item = _visibles[index];
                    final origen = item['almacen_origen'] as Map?;
                    final destino = item['almacen_destino'] as Map?;
                    final estado = item['estado'] as String?;

                    return DataCard(
                      title: item['documento']?.toString() ?? '#${item['id']}',
                      subtitle: '${origen?['nombre'] ?? '—'} → ${destino?['nombre'] ?? '—'}',
                      onTap: () => _verDetalle(item),
                      rows: [
                        DataCardRow.text('Fecha', _fecha(item['fecha_inicio_traslado'] ?? item['created_at'])),
                        DataCardRow.text('Motivo', _motivoNombre(item['motivo_traslado'])),
                        DataCardRow.text(
                          'Transporte',
                          item['modalidad_transporte'] == 'publico'
                              ? (item['transportista_razon_social']?.toString() ?? 'Público')
                              : (item['vehiculo_placa'] != null ? 'Propio · ${item['vehiculo_placa']}' : 'Propio'),
                        ),
                        DataCardRow.text('Productos', '${item['detalles_count'] ?? (item['detalles'] as List?)?.length ?? 0}'),
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
                              tipo: 'guia-traslado',
                              id: item['id'] as int,
                              nombre: item['documento']?.toString() ?? '#${item['id']}',
                              titulo: 'Guía de traslado',
                              formatos: const ['a4', 'ticket']),
                      ),
                                              if (estado == 'pendiente')
                          DataCardAction(
                            icon: Icons.send_outlined,
                            color: AppColors.info,
                            tooltip: 'Enviar (descuenta stock del origen)',
                            onTap: () => _accion(item, 'enviar', 'Guía enviada. Stock descontado del origen.'),
                          ),
                        if (estado == 'en_transito')
                          DataCardAction(
                            icon: Icons.inventory_outlined,
                            color: AppColors.success,
                            tooltip: 'Recibir (ingresa stock al destino)',
                            onTap: () => _accion(item, 'recibir', 'Guía recibida. Stock ingresado al destino.'),
                          ),
                        if (estado == 'pendiente')
                          DataCardAction(
                            icon: Icons.block,
                            color: AppColors.textMuted,
                            tooltip: 'Anular',
                            onTap: () => _anular(item),
                          ),
                        DataCardAction(
                          icon: Icons.edit_outlined,
                          color: AppColors.primary,
                          tooltip: estado == 'pendiente' ? 'Editar transporte' : 'Editar observaciones',
                          onTap: () => _editar(item),
                        ),
                        if (estado == 'pendiente')
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

  Widget _listaMotivos() {
    return _motivos.isEmpty
        ? const Center(child: Text('No hay motivos de traslado'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _motivos.length,
            itemBuilder: (context, index) {
              final m = _motivos[index];
              final sistema = m['es_sistema'] == true;
              final activo = m['activo'] == true;
              return DataCard(
                title: m['nombre']?.toString() ?? '',
                subtitle: m['codigo']?.toString(),
                rows: [
                  DataCardRow(
                    label: 'Origen',
                    value: AppBadge(sistema ? 'Sistema' : 'Manual', type: sistema ? AppBadgeType.info : AppBadgeType.neutral),
                  ),
                  DataCardRow(
                    label: 'Estado',
                    value: AppBadge(activo ? 'Activo' : 'Inactivo', type: activo ? AppBadgeType.success : AppBadgeType.danger),
                  ),
                ],
                actions: [
                  DataCardAction(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    tooltip: sistema ? 'Activar / desactivar' : 'Editar',
                    onTap: () => _formMotivo(item: m),
                  ),
                  if (!sistema)
                    DataCardAction(
                      icon: Icons.delete_outline,
                      color: AppColors.danger,
                      tooltip: 'Eliminar',
                      onTap: () => _eliminarMotivo(m),
                    ),
                ],
              );
            },
          );
  }
}

// ═══════════════════════ Formulario de guía ═══════════════════════

class _Linea {
  int? productoId;
  int? presentacionId;
  final TextEditingController cantidad = TextEditingController(text: '1');
  double get cant => double.tryParse(cantidad.text.trim()) ?? 0;
  void dispose() => cantidad.dispose();
}

class _GuiaFormSheet extends StatefulWidget {
  final ApiService api;
  final List<Map<String, dynamic>> almacenes;
  final List<Map<String, dynamic>> productos;
  final List<Map<String, dynamic>> existencias;
  final List<Map<String, dynamic>> motivos;
  final Future<void> Function() onMotivosCambiaron;
  final Map<String, dynamic>? initial;

  const _GuiaFormSheet({
    required this.api,
    required this.almacenes,
    required this.productos,
    required this.existencias,
    required this.motivos,
    required this.onMotivosCambiaron,
    this.initial,
  });

  @override
  State<_GuiaFormSheet> createState() => _GuiaFormSheetState();
}

class _GuiaFormSheetState extends State<_GuiaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  int? _origenId;
  int? _destinoId;
  String? _motivo;
  DateTime _fechaInicio = DateTime.now();
  String _modalidad = 'privado';
  final _transportista = TextEditingController();
  final _transportistaRuc = TextEditingController();
  final _placa = TextEditingController();
  final _conductor = TextEditingController();
  final _conductorDoc = TextEditingController();
  final _licencia = TextEditingController();
  final _bultos = TextEditingController();
  final _peso = TextEditingController();
  final _observaciones = TextEditingController();
  final List<_Linea> _lineas = [_Linea()];

  /// Copia local: al crear un motivo desde el "+" se agrega aquí sin cerrar.
  late List<Map<String, dynamic>> _motivos = List.of(widget.motivos);

  bool get _editando => widget.initial != null;
  bool get _pendiente => widget.initial?['estado'] == 'pendiente';
  bool get _publico => _modalidad == 'publico';

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _origenId = int.tryParse('${i['almacen_origen_id']}');
      _destinoId = int.tryParse('${i['almacen_destino_id']}');
      _motivo = i['motivo_traslado']?.toString();
      _fechaInicio = DateTime.tryParse('${i['fecha_inicio_traslado']}') ?? DateTime.now();
      _modalidad = i['modalidad_transporte']?.toString() ?? 'privado';
      _transportista.text = i['transportista_razon_social']?.toString() ?? '';
      _transportistaRuc.text = i['transportista_ruc']?.toString() ?? '';
      _placa.text = i['vehiculo_placa']?.toString() ?? '';
      _conductor.text = i['conductor_nombre']?.toString() ?? '';
      _conductorDoc.text = i['conductor_documento']?.toString() ?? '';
      _licencia.text = i['conductor_licencia']?.toString() ?? '';
      _bultos.text = i['numero_bultos']?.toString() ?? '';
      _peso.text = i['peso_bruto_kg']?.toString() ?? '';
      _observaciones.text = i['observaciones']?.toString() ?? '';
    } else {
      // Motivo por defecto de la guía de remisión.
      _motivo = 'traslado_entre_establecimientos';
    }
  }

  @override
  void dispose() {
    for (final c in [_transportista, _transportistaRuc, _placa, _conductor, _conductorDoc, _licencia, _bultos, _peso, _observaciones]) {
      c.dispose();
    }
    for (final l in _lineas) {
      l.dispose();
    }
    super.dispose();
  }

  // ── Stock del origen (unidad base) y unidades convertidas ──
  Map<int, double> get _stockOrigen {
    if (_origenId == null) return {};
    return {
      for (final e in widget.existencias)
        if (e['almacen_id'] == _origenId)
          e['producto_id'] as int: double.tryParse('${e['stock_actual']}') ?? 0,
    };
  }

  List<AppSelectOption<int>> get _productosOptions {
    final st = _stockOrigen;
    return [
      for (final p in widget.productos)
        if ((st[p['id']] ?? 0) > 0)
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

  List<({int id, String label, double disponible})> _unidadesDe(int? productoId) {
    final p = _productoDe(productoId);
    if (p == null) return [];
    final base = _stockOrigen[productoId] ?? 0;
    return [
      for (final pres in (p['presentaciones'] as List? ?? []))
        if (pres['activo'] != false)
          () {
            final factor = double.tryParse('${pres['factor_conversion']}') ?? 1;
            return (
              id: pres['id'] as int,
              label: pres['nombre']?.toString() ?? '',
              disponible: (base / factor * 100).floor() / 100,
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

  // ── Motivos: crear desde el "+" sin salir del formulario ──
  Future<void> _crearMotivo() async {
    final data = await showAppModal<Map<String, dynamic>>(
      context,
      title: 'Nuevo motivo de traslado',
      child: const _MotivoFormSheet(),
    );
    if (data == null) return;
    try {
      final creado = await widget.api.post(ApiEndpoints.motivosTraslado, body: data);
      await widget.onMotivosCambiaron();
      if (!mounted) return;
      setState(() {
        _motivos = [..._motivos, creado];
        // Queda seleccionado en la guía.
        _motivo = creado['codigo']?.toString();
      });
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  List<AppSelectOption<String>> get _motivosOptions => [
    for (final m in _motivos)
      if (m['activo'] == true || m['codigo'] == _motivo)
        AppSelectOption<String>(m['codigo'].toString(), m['nombre']?.toString() ?? ''),
  ];

  // ── Guardar ──
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final transporte = {
      'motivo_traslado': _motivo,
      'fecha_inicio_traslado': _fechaInicio.toIso8601String().substring(0, 10),
      'modalidad_transporte': _modalidad,
      'transportista_razon_social': _publico && _transportista.text.trim().isNotEmpty ? _transportista.text.trim() : null,
      'transportista_ruc': _publico && _transportistaRuc.text.trim().isNotEmpty ? _transportistaRuc.text.trim() : null,
      'vehiculo_placa': _placa.text.trim().isEmpty ? null : _placa.text.trim().toUpperCase(),
      'conductor_nombre': _conductor.text.trim().isEmpty ? null : _conductor.text.trim(),
      'conductor_documento': _conductorDoc.text.trim().isEmpty ? null : _conductorDoc.text.trim(),
      'conductor_licencia': _licencia.text.trim().isEmpty ? null : _licencia.text.trim().toUpperCase(),
      'numero_bultos': int.tryParse(_bultos.text.trim()),
      'peso_bruto_kg': double.tryParse(_peso.text.trim()),
      'observaciones': _observaciones.text.trim().isEmpty ? null : _observaciones.text.trim(),
    };

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_editando) {
        await widget.api.put(ApiEndpoints.transferencia(widget.initial!['id']), body: transporte);
      } else {
        if (_origenId == null || _destinoId == null) {
          throw Exception('Elige almacén de origen y destino.');
        }
        final detalles = <Map<String, dynamic>>[];
        for (final l in _lineas) {
          if (l.presentacionId == null || l.cant <= 0) continue;
          if (l.cant > _disponibleDe(l)) {
            throw Exception('"${_productoDe(l.productoId)?['nombre']}" supera el stock del origen (${_num(_disponibleDe(l))}).');
          }
          detalles.add({'producto_presentacion_id': l.presentacionId, 'cantidad_enviada': l.cant});
        }
        if (detalles.isEmpty) throw Exception('Agrega al menos un producto.');

        await widget.api.post(ApiEndpoints.transferencias, body: {
          'almacen_origen_id': _origenId,
          'almacen_destino_id': _destinoId,
          ...transporte,
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

  Future<void> _elegirFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _fechaInicio = d);
  }

  @override
  Widget build(BuildContext context) {
    final bloqueado = _editando && !_pendiente;

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
          if (bloqueado) ...[
            const AppMessage(
              text: 'Una guía enviada solo admite cambios en observaciones.',
              type: AppMessageType.success,
            ),
            const SizedBox(height: 12),
          ],

          // ── Traslado ──
          AppFormSection(
            title: 'Traslado',
            children: [
              AppSelect<int>(
                label: 'Almacén origen',
                icon: Icons.warehouse_outlined,
                value: _origenId,
                options: [for (final a in widget.almacenes) AppSelectOption<int>(a['id'] as int, a['nombre']?.toString() ?? '')],
                onChanged: _editando
                    ? null
                    : (v) => setState(() {
                        _origenId = v;
                        for (final l in _lineas) {
                          l.dispose();
                        }
                        _lineas
                          ..clear()
                          ..add(_Linea());
                      }),
                validator: (v) => v == null ? 'Elija el origen' : null,
              ),
              AppSelect<int>(
                label: 'Almacén destino',
                icon: Icons.flag_outlined,
                value: _destinoId,
                options: [
                  for (final a in widget.almacenes)
                    if (a['id'] != _origenId) AppSelectOption<int>(a['id'] as int, a['nombre']?.toString() ?? ''),
                ],
                onChanged: _editando ? null : (v) => setState(() => _destinoId = v),
                validator: (v) => v == null ? 'Elija el destino' : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: !bloqueado,
                leading: const Icon(Icons.today_outlined),
                title: const Text('Fecha de inicio'),
                subtitle: Text(_fechaInicio.toIso8601String().substring(0, 10)),
                onTap: bloqueado ? null : _elegirFecha,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AppSelect<String>(
                      label: 'Motivo de traslado',
                      icon: Icons.label_outline,
                      value: _motivo,
                      options: _motivosOptions,
                      onChanged: bloqueado ? null : (v) => setState(() => _motivo = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Elija el motivo' : null,
                    ),
                  ),
                  if (!bloqueado)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: IconButton(
                        tooltip: 'Crear motivo',
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.success),
                        onPressed: _crearMotivo,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Transporte (opcional) ──
          AppFormSection(
            title: 'Transporte (opcional)',
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Puedes dejarlo vacío y completarlo después, mientras la guía esté pendiente.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
              AppSelect<String>(
                label: 'Modalidad',
                icon: Icons.local_shipping_outlined,
                value: _modalidad,
                options: const [
                  AppSelectOption('privado', 'Privado (vehículo propio)'),
                  AppSelectOption('publico', 'Público (empresa de transporte)'),
                ],
                onChanged: bloqueado ? null : (v) => setState(() => _modalidad = v ?? 'privado'),
              ),
              if (_publico) ...[
                AppTextField(
                  controller: _transportista,
                  label: 'Transportista (razón social) *',
                  icon: Icons.business_outlined,
                  validator: (v) => _publico && (v == null || v.trim().isEmpty) ? 'Requerido con transporte público' : null,
                ),
                AppTextField(
                  controller: _transportistaRuc,
                  label: 'RUC transportista *',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => _publico && (v == null || v.trim().length != 11) ? 'RUC de 11 dígitos' : null,
                ),
              ],
              AppTextField(controller: _placa, label: 'Placa del vehículo', icon: Icons.directions_car_outlined),
              AppTextField(controller: _conductor, label: 'Conductor', icon: Icons.person_outline),
              Row(
                children: [
                  Expanded(child: AppTextField(controller: _conductorDoc, label: 'DNI conductor', keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: AppTextField(controller: _licencia, label: 'Licencia')),
                ],
              ),
              Row(
                children: [
                  Expanded(child: AppTextField(controller: _bultos, label: 'N° bultos', keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextField(
                      controller: _peso,
                      label: 'Peso bruto (kg)',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Productos (solo al crear: emitida, el detalle es fijo) ──
          if (!_editando)
            AppFormSection(
              title: 'Productos a trasladar',
              trailing: TextButton.icon(
                onPressed: _origenId == null ? null : () => setState(() => _lineas.add(_Linea())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
              ),
              children: [
                if (_origenId == null)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Elige el almacén de origen para ver sus productos con stock.', style: TextStyle(color: AppColors.textMuted)),
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
            children: [
              AppTextField(controller: _observaciones, label: 'Observaciones (opcional)', icon: Icons.notes_outlined),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Cancelar', onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: _editando ? 'Guardar' : 'Crear guía',
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
    final excede = l.presentacionId != null && l.cant > disp;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('Producto ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
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
              options: [for (final u in unidades) AppSelectOption<int>(u.id, '${u.label} (disp. ${_num(u.disponible)})')],
              onChanged: (v) => setState(() => l.presentacionId = v),
            ),
            AppTextField(
              controller: l.cantidad,
              label: 'Cantidad',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (_) => excede ? 'Supera el stock del origen' : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════ Formulario de motivo ══════════════════════

class _MotivoFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _MotivoFormSheet({this.initial});

  @override
  State<_MotivoFormSheet> createState() => _MotivoFormSheetState();
}

class _MotivoFormSheetState extends State<_MotivoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  bool _activo = true;

  bool get _sistema => widget.initial?['es_sistema'] == true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre']?.toString() ?? '');
    _activo = widget.initial?['activo'] as bool? ?? true;
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
          if (_sistema) ...[
            const AppMessage(
              text: 'Los motivos del sistema solo se pueden activar o desactivar.',
              type: AppMessageType.success,
            ),
            const SizedBox(height: 12),
          ],
          AppFormSection(
            title: 'Datos del motivo',
            children: [
              // El nombre del sistema es fijo; el select solo lo muestra.
              if (_sistema)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_nombre.text, style: const TextStyle(fontWeight: FontWeight.w600)),
                )
              else
                AppTextField(
                  controller: _nombre,
                  label: 'Nombre',
                  icon: Icons.label_outline,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null,
                ),
              AppToggle(label: 'Motivo activo', value: _activo, onChanged: (v) => setState(() => _activo = v)),
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
                      if (!_sistema) 'nombre': _nombre.text.trim(),
                      'activo': _activo,
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
