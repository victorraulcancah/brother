import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/data_card.dart';
import '../widgets/product_lines_editor.dart';

class TomasInventarioScreen extends StatefulWidget {
  const TomasInventarioScreen({super.key});

  @override
  State<TomasInventarioScreen> createState() => _TomasInventarioScreenState();
}

class _TomasInventarioScreenState extends State<TomasInventarioScreen> {
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
    _crud = CrudService(_api, ApiEndpoints.tomas);
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
      _error = 'No se pudieron cargar las tomas.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _nueva() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const _CrearTomaScreen()));
    if (ok == true) _load();
  }

  Future<void> _cerrar(Map<String, dynamic> item) async {
    try {
      await _api.post('${ApiEndpoints.tomas}/${item['id']}/cerrar', body: {});
      await _load();
      if (mounted) showAppSnackbar(context, 'Toma cerrada. Stock ajustado.', type: AppSnackbarType.success);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((t) {
      if (_filtroEstado != null && t['estado'] != _filtroEstado) return false;
      if (q.isEmpty) return true;
      final almacen = (t['almacen'] as Map?)?['nombre'] ?? '';
      return '${t['id']} $almacen ${t['observaciones'] ?? ''}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tomas de Inventario',
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
                  hintText: 'Buscar tomas...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Estado',
                      value: _filtroEstado,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('en_proceso', 'En proceso'),
                        AppListFilterOption('cerrado', 'Cerrada'),
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
                            _items.isEmpty ? 'No hay tomas de inventario' : 'Ninguna toma coincide con la busqueda',
                          ),
                        )
                      : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _visibles.length,
              itemBuilder: (context, index) {
                final item = _visibles[index];
                final almacen = item['almacen'] as Map<String, dynamic>?;
                final cerrado = item['estado'] == 'cerrado';
                return DataCard(
                  title: 'Toma #${item['id']}',
                  rows: [
                    DataCardRow.text('Almacén', almacen?['nombre'] as String? ?? '—'),
                    DataCardRow.text('Productos', '${item['detalles_count'] ?? 0}'),
                    DataCardRow.text('Fecha', '${item['fecha'] ?? '—'}'),
                    DataCardRow(
                      label: 'Estado',
                      value: AppBadge(cerrado ? 'Cerrado' : 'En proceso',
                          type: cerrado ? AppBadgeType.success : AppBadgeType.warning),
                    ),
                  ],
                  actions: cerrado
                      ? []
                      : [
                          DataCardAction(
                            icon: Icons.lock_outline,
                            color: AppColors.primary,
                            tooltip: 'Cerrar y ajustar stock',
                            onTap: () => _cerrar(item),
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

class _CrearTomaScreen extends StatefulWidget {
  const _CrearTomaScreen();

  @override
  State<_CrearTomaScreen> createState() => _CrearTomaScreenState();
}

class _CrearTomaScreenState extends State<_CrearTomaScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _almacenes = [];
  final List<AppSelectOption<int>> _presOptions = [];

  int? _almacenId;
  final List<ProductLine> _lineas = [ProductLine(cantidad: '0', precio: '0')];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final l in _lineas) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        CrudService(_api, ApiEndpoints.almacenes).getAll(),
        CrudService(_api, ApiEndpoints.productos).getAll(),
      ]);
      _almacenes = results[0];
      for (final p in results[1]) {
        for (final pres in (p['presentaciones'] as List? ?? [])) {
          _presOptions.add(AppSelectOption(pres['id'] as int, '${p['nombre']} — ${pres['nombre']}'));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _guardar() async {
    final lineas = _lineas.where((l) => l.presentacionId != null).toList();
    if (_almacenId == null) {
      showAppSnackbar(context, 'Selecciona el almacén', type: AppSnackbarType.error);
      return;
    }
    if (lineas.isEmpty) {
      showAppSnackbar(context, 'Agrega al menos un producto', type: AppSnackbarType.error);
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.post(ApiEndpoints.tomas, body: {
        'almacen_id': _almacenId,
        'detalles': lineas.map((l) => {'producto_presentacion_id': l.presentacionId, 'stock_contado': l.cant}).toList(),
      });
      if (mounted) {
        showAppSnackbar(context, 'Toma creada. Ciérrala para ajustar el stock.', type: AppSnackbarType.success);
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
      title: 'Nueva Toma de Inventario',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppFormSection(
                    title: 'Datos de la toma',
                    children: [
                      AppSelect<int>(
                        label: 'Almacén',
                        icon: Icons.warehouse_outlined,
                        value: _almacenId,
                        options: [for (final a in _almacenes) AppSelectOption(a['id'] as int, a['nombre'] as String? ?? '')],
                        onChanged: (v) => setState(() => _almacenId = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppFormSection(
                    title: 'Conteo físico',
                    children: [
                      ProductLinesEditor(
                        lines: _lineas,
                        options: _presOptions,
                        showPrice: false,
                        qtyLabel: 'Contado',
                        onAdd: () => setState(() => _lineas.add(ProductLine(cantidad: '0'))),
                        onRemove: (i) => setState(() => _lineas.removeAt(i).dispose()),
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(label: 'Guardar toma', loading: _saving, onPressed: _guardar),
                ],
              ),
            ),
    );
  }
}
