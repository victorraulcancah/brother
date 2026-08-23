import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/data_card.dart';

String _money(dynamic v) =>
    'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';

String _num(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
}

String _fechaHora(dynamic v) {
  if (v == null) return '—';
  final d = DateTime.tryParse('$v');
  if (d == null) return '$v';
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mi = d.minute.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year} $hh:$mi';
}

/// Motivo del movimiento. "compra" queda por los registros antiguos:
/// las recepciones ahora se guardan con origen "recepcion".
const _origenLabel = {
  'recepcion': 'Recepción',
  'recepcion_deshecha': 'Recepción deshecha',
  'compra': 'Recepción',
  'venta': 'Venta',
  'nota_venta': 'Venta',
  'devolucion': 'Devolución',
  'merma': 'Merma',
  'transferencia': 'Traslado',
  'ajuste_manual': 'Ajuste',
  'prestamo': 'Préstamo',
  'toma_inventario': 'Toma inventario',
};

const _docLabel = {
  'recepcion_compra': 'Recepción',
  'ajuste_inventario': 'Ajuste',
  'transferencia': 'Traslado',
  'prestamo': 'Préstamo',
  'toma_inventario': 'Toma',
  'nota_venta': 'Venta',
};

/// Kardex: historial de entradas y salidas de inventario por producto.
///
/// Es un registro derivado de las operaciones (recepciones, ventas, ajustes),
/// así que es de solo lectura: no se crean movimientos a mano.
class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _almacenes = [];
  bool _loading = true;
  String? _error;
  String _busqueda = '';
  String? _filtroTipo;
  String? _filtroAlmacen;

  /// Unidad elegida en cada fila para expresar la cantidad: { id: nombre }.
  final Map<int, String> _unidadPorFila = {};

  /// Formatos activos del producto de esa fila, del más chico al más grande.
  List<Map<String, dynamic>> _formatosDe(Map<String, dynamic> m) {
    final lista = (((m['producto'] as Map?)?['presentaciones'] as List?) ?? [])
        .whereType<Map>()
        .where((p) => p['activo'] != false && '${p['nombre'] ?? ''}'.trim().isNotEmpty)
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    lista.sort((a, b) => (double.tryParse('${a['factor_conversion']}') ?? 1)
        .compareTo(double.tryParse('${b['factor_conversion']}') ?? 1));
    return lista;
  }

  /// Cuántas unidades base vale la unidad elegida: una salida de 100 kg son
  /// 2 sacos de 50. Sin elección vale 1 y se muestra en unidad base.
  double _factorDeFila(Map<String, dynamic> m) {
    final elegida = _unidadPorFila[m['id']];
    if (elegida == null) return 1;
    for (final f in _formatosDe(m)) {
      if ('${f['nombre']}'.trim() == elegida) {
        return double.tryParse('${f['factor_conversion']}') ?? 1;
      }
    }
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Future.wait([
        CrudService(_api, ApiEndpoints.movimientos).getAll(),
        CrudService(_api, ApiEndpoints.almacenes).getAll(),
      ]);
      _items = r[0];
      _almacenes = r[1];
    } catch (_) {
      _error = 'No se pudieron cargar los movimientos.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((m) {
      if (_filtroTipo != null && m['tipo_movimiento'] != _filtroTipo) {
        return false;
      }
      if (_filtroAlmacen != null) {
        final id = (m['almacen_id'] ?? (m['almacen'] as Map?)?['id'])
            ?.toString();
        if (id != _filtroAlmacen) return false;
      }
      if (q.isEmpty) return true;

      final producto = m['producto'] as Map?;
      return '${producto?['codigo'] ?? ''} ${producto?['nombre'] ?? ''} '
              '${m['proveedor_nombre'] ?? ''}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Kardex',
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
                  hintText: 'Buscar en el kardex...',
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
                      label: 'Almacén',
                      value: _filtroAlmacen,
                      options: [
                        const AppListFilterOption(null, 'Todos'),
                        for (final a in _almacenes)
                          AppListFilterOption(
                            a['id'].toString(),
                            a['nombre']?.toString() ?? '',
                          ),
                      ],
                      onChanged: (v) => setState(() => _filtroAlmacen = v),
                    ),
                  ],
                  activeFilters:
                      (_filtroTipo != null ? 1 : 0) +
                      (_filtroAlmacen != null ? 1 : 0),
                  onClearFilters: () => setState(() {
                    _filtroTipo = null;
                    _filtroAlmacen = null;
                  }),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(
                          child: Text(
                            _items.isEmpty
                                ? 'No hay movimientos'
                                : 'Ningún movimiento coincide con la búsqueda',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _visibles.length,
                          itemBuilder: (context, index) {
                            final m = _visibles[index];
                            final producto = m['producto'] as Map?;
                            final esEntrada = m['tipo_movimiento'] == 'entrada';
                            final cantidad =
                                (double.tryParse('${m['cantidad'] ?? 0}') ?? 0)
                                    .abs();
                            final base =
                                (producto?['unidad_base'] as Map?)?['nombre']
                                        ?.toString() ??
                                    'Unidad base';
                            final formatos = _formatosDe(m);
                            final factor = _factorDeFila(m);
                            final unidad = _unidadPorFila[m['id']] ?? base;
                            final doc = m['documento_referencia_tipo'];

                            return DataCard(
                              title: producto?['nombre']?.toString() ?? '—',
                              subtitle:
                                  '${producto?['codigo'] ?? '—'} · '
                                  '${_fechaHora(m['fecha'])}',
                              rows: [
                                DataCardRow(
                                  label: 'Tipo',
                                  value: AppBadge(
                                    esEntrada ? 'Entrada' : 'Salida',
                                    type: esEntrada
                                        ? AppBadgeType.success
                                        : AppBadgeType.danger,
                                  ),
                                ),
                                DataCardRow.text(
                                  'Mov.',
                                  _origenLabel[m['origen']] ??
                                      m['origen']?.toString() ??
                                      '—',
                                ),
                                DataCardRow.text(
                                  'Documento',
                                  doc == null
                                      ? '—'
                                      : '${_docLabel[doc] ?? doc}'
                                            '${m['documento_referencia_id'] != null ? ' #${m['documento_referencia_id']}' : ''}',
                                ),
                                if (m['proveedor_nombre'] != null)
                                  DataCardRow.text(
                                    'Proveedor',
                                    m['proveedor_nombre'].toString(),
                                  ),
                                DataCardRow.text(
                                  'Almacén',
                                  (m['almacen'] as Map?)?['nombre']
                                          ?.toString() ??
                                      '—',
                                ),
                                if (formatos.isNotEmpty)
                                  DataCardRow(
                                    label: 'Ver en',
                                    value: DropdownButton<String>(
                                      value: _unidadPorFila[m['id']],
                                      hint: Text('$base (base)',
                                          style: const TextStyle(fontSize: 13)),
                                      isDense: true,
                                      underline: const SizedBox.shrink(),
                                      style: const TextStyle(
                                          fontSize: 13, color: AppColors.textStrong),
                                      items: [
                                        DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('$base (base)'),
                                        ),
                                        for (final f in formatos)
                                          DropdownMenuItem<String>(
                                            value: '${f['nombre']}'.trim(),
                                            child: Text('${f['nombre']}'.trim()),
                                          ),
                                      ],
                                      onChanged: (v) => setState(() {
                                        if (v == null) {
                                          _unidadPorFila.remove(m['id']);
                                        } else {
                                          _unidadPorFila[m['id']] = v;
                                        }
                                      }),
                                    ),
                                  ),
                                DataCardRow(
                                  label: esEntrada ? 'Ingreso' : 'Salida',
                                  value: Text(
                                    '${esEntrada ? '+' : '−'} ${_num(cantidad / factor)} $unidad',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: esEntrada
                                          ? AppColors.success
                                          : AppColors.danger,
                                    ),
                                  ),
                                ),
                                DataCardRow.text(
                                  'Stock ant. → act.',
                                  '${_num((double.tryParse('${m['stock_anterior'] ?? 0}') ?? 0) / factor)}'
                                  ' → '
                                  '${_num((double.tryParse('${m['saldo_stock'] ?? 0}') ?? 0) / factor)}',
                                ),
                                DataCardRow.text(
                                  'Costo ant. → act.',
                                  '${_money(m['costo_anterior'])} → ${_money(m['costo_actual'])}',
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
