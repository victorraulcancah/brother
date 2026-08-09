import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_segmented.dart';
import '../widgets/data_card.dart';

String _money(dynamic v) =>
    'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';

String _num(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
}

/// Stock por almacén, con el desglose en cada unidad derivada del producto.
class ExistenciasScreen extends StatefulWidget {
  const ExistenciasScreen({super.key});

  @override
  State<ExistenciasScreen> createState() => _ExistenciasScreenState();
}

class _ExistenciasScreenState extends State<ExistenciasScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _existencias = [];
  List<Map<String, dynamic>> _almacenes = [];
  bool _loading = true;
  String? _error;

  /// 0 = todos los almacenes; el resto, índice dentro de [_almacenes].
  int _tab = 0;
  String _busqueda = '';
  String? _filtroStock;

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
        CrudService(_api, ApiEndpoints.almacenes).getAll(),
        CrudService(_api, ApiEndpoints.existencias).getAll(),
      ]);
      _almacenes = r[0];
      _existencias = r[1];
    } catch (_) {
      _error = 'No se pudieron cargar las existencias.';
    }
    if (mounted) setState(() => _loading = false);
  }

  /// El mínimo del almacén manda; si no está definido, el del producto.
  ({double stock, double minimo, double maximo}) _info(Map<String, dynamic> e) {
    final producto = e['producto'] as Map?;
    double n(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
    return (
      stock: n(e['stock_actual']),
      minimo: n(e['stock_minimo']) != 0
          ? n(e['stock_minimo'])
          : n(producto?['stock_minimo']),
      maximo: n(e['stock_maximo']) != 0
          ? n(e['stock_maximo'])
          : n(producto?['stock_maximo']),
    );
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    final almacenId = _tab == 0 ? null : _almacenes[_tab - 1]['id'];

    return _existencias.where((e) {
      if (almacenId != null && e['almacen_id'] != almacenId) return false;

      final i = _info(e);
      if (_filtroStock == 'sin' && i.stock > 0) return false;
      if (_filtroStock == 'bajo' &&
          !(i.stock > 0 && i.minimo > 0 && i.stock <= i.minimo)) {
        return false;
      }
      if (_filtroStock == 'sobre' && !(i.maximo > 0 && i.stock > i.maximo)) {
        return false;
      }
      if (_filtroStock == 'normal' &&
          !(i.stock > 0 && (i.minimo <= 0 || i.stock > i.minimo))) {
        return false;
      }

      if (q.isEmpty) return true;
      final p = e['producto'] as Map?;
      final marca = (p?['marca'] as Map?)?['nombre'] ?? '';
      final categoria = (p?['categoria'] as Map?)?['nombre'] ?? '';
      return '${p?['codigo'] ?? ''} ${p?['nombre'] ?? ''} $marca $categoria'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  ({int items, int sinStock, int bajoMinimo, double valorizado}) get _resumen {
    var items = 0, sinStock = 0, bajoMinimo = 0;
    var valorizado = 0.0;

    for (final e in _visibles) {
      final i = _info(e);
      items++;
      if (i.stock <= 0) {
        sinStock++;
      } else if (i.minimo > 0 && i.stock <= i.minimo) {
        bajoMinimo++;
      }
      valorizado += i.stock * (double.tryParse('${e['costo_promedio']}') ?? 0);
    }
    return (
      items: items,
      sinStock: sinStock,
      bajoMinimo: bajoMinimo,
      valorizado: valorizado,
    );
  }

  AppBadge _badgeStock(Map<String, dynamic> e) {
    final i = _info(e);
    final texto = _num(i.stock);
    if (i.stock <= 0) return AppBadge(texto, type: AppBadgeType.danger);
    if (i.minimo > 0 && i.stock <= i.minimo) {
      return AppBadge(texto, type: AppBadgeType.warning);
    }
    if (i.maximo > 0 && i.stock > i.maximo) {
      return AppBadge(texto, type: AppBadgeType.info);
    }
    return AppBadge(texto, type: AppBadgeType.success);
  }

  /// El stock vive en unidad base: "1000" no dice cuántos paquetes hay.
  Future<void> _verDerivadas(Map<String, dynamic> e) async {
    final producto = e['producto'] as Map?;
    final stockBase = double.tryParse('${e['stock_actual'] ?? 0}') ?? 0;
    final abrev = (producto?['unidad_base'] as Map?)?['abreviatura'] ?? '';

    final presentaciones =
        ((producto?['presentaciones'] as List?) ?? [])
            .whereType<Map>()
            .where((p) => p['activo'] != false)
            .toList()
          ..sort(
            (a, b) => (double.tryParse('${a['factor_conversion']}') ?? 1)
                .compareTo(double.tryParse('${b['factor_conversion']}') ?? 1),
          );

    await showAppModal<void>(
      context,
      title: 'Unidades derivadas · ${producto?['nombre'] ?? ''}',
      child: presentaciones.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Este producto no tiene unidades derivadas.'),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Stock base: ${_num(stockBase)} $abrev',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
                for (final p in presentaciones)
                  _derivadaCard(p, stockBase, '$abrev'),
              ],
            ),
    );
  }

  Widget _derivadaCard(Map p, double stockBase, String abrev) {
    final factor = double.tryParse('${p['factor_conversion']}') ?? 1;
    // Unidades completas: media caja no sirve para operar.
    final completas = (stockBase / factor).floor();
    final sobrante = stockBase - completas * factor;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p['nombre']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '$completas',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Factor: x${_num(factor)} $abrev'
              '${sobrante > 0 ? '  ·  Sobrante: ${_num(sobrante)} $abrev' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'Compra: ${_money(p['precio_compra'])}   '
              'Venta: ${_money(p['precio_venta'])}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resumen = _resumen;

    return AppScaffold(
      title: 'Existencias',
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
                  items: [
                    'Todos',
                    for (final a in _almacenes) a['nombre']?.toString() ?? '',
                  ],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      _stat('Productos', '${resumen.items}'),
                      _stat(
                        'Sin stock',
                        '${resumen.sinStock}',
                        color: AppColors.danger,
                      ),
                      _stat(
                        'Bajo mín.',
                        '${resumen.bajoMinimo}',
                        color: AppColors.warning,
                      ),
                      _stat(
                        'Valorizado',
                        _money(resumen.valorizado),
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                AppListHeader(
                  hintText: 'Buscar existencias...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Stock',
                      value: _filtroStock,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('sin', 'Sin stock'),
                        AppListFilterOption('bajo', 'Bajo el mínimo'),
                        AppListFilterOption('sobre', 'Sobre el máximo'),
                        AppListFilterOption('normal', 'Stock normal'),
                      ],
                      onChanged: (v) => setState(() => _filtroStock = v),
                    ),
                  ],
                  activeFilters: _filtroStock != null ? 1 : 0,
                  onClearFilters: () => setState(() => _filtroStock = null),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? const Center(child: Text('Sin existencias'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _visibles.length,
                          itemBuilder: (context, index) {
                            final e = _visibles[index];
                            final p = e['producto'] as Map?;
                            final unidad =
                                (p?['unidad_base'] as Map?)?['abreviatura'] ??
                                '';
                            final i = _info(e);
                            final costo =
                                double.tryParse('${e['costo_promedio']}') ?? 0;

                            return DataCard(
                              title: p?['nombre']?.toString() ?? '—',
                              subtitle:
                                  '${p?['codigo'] ?? '—'}'
                                  '${(p?['marca'] as Map?)?['nombre'] != null ? ' · ${(p!['marca'] as Map)['nombre']}' : ''}',
                              onTap: () => _verDerivadas(e),
                              rows: [
                                if (_tab == 0)
                                  DataCardRow.text(
                                    'Almacén',
                                    (e['almacen'] as Map?)?['nombre']
                                            ?.toString() ??
                                        '—',
                                  ),
                                DataCardRow.text(
                                  'Categoría',
                                  (p?['categoria'] as Map?)?['nombre']
                                          ?.toString() ??
                                      '—',
                                ),
                                DataCardRow(
                                  label: 'Stock ($unidad)',
                                  value: _badgeStock(e),
                                ),
                                DataCardRow.text(
                                  'Reservado',
                                  _num(e['stock_reservado']),
                                ),
                                DataCardRow.text(
                                  'Disponible',
                                  _num(e['stock_disponible']),
                                ),
                                DataCardRow.text(
                                  'Mín. / Máx.',
                                  '${_num(i.minimo)} / ${_num(i.maximo)}',
                                ),
                                DataCardRow.text(
                                  'Costo prom.',
                                  _money(e['costo_promedio']),
                                ),
                                DataCardRow.text(
                                  'Valorizado',
                                  _money(i.stock * costo),
                                ),
                                DataCardRow.text(
                                  'P. Venta',
                                  _money(p?['precio_base']),
                                ),
                                if (e['ubicacion'] != null)
                                  DataCardRow.text(
                                    'Ubicación',
                                    e['ubicacion'].toString(),
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

  Widget _stat(String label, String valor, {Color? color}) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            valor,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}
