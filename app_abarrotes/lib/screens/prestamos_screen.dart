import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';
import '../widgets/product_lines_editor.dart';

/// Etiqueta legible de cada estado del prestamo.
const _estadoLabel = {
  'pendiente': 'Pendiente',
  'prestado': 'Prestado',
  'parcial': 'Devuelto parcial',
  'devuelto': 'Devuelto',
};

AppBadgeType _estadoBadge(String? e) => switch (e) {
      'prestado' => AppBadgeType.warning,
      'parcial' => AppBadgeType.info,
      'devuelto' => AppBadgeType.success,
      _ => AppBadgeType.neutral,
    };

class PrestamosScreen extends StatefulWidget {
  const PrestamosScreen({super.key});

  @override
  State<PrestamosScreen> createState() => _PrestamosScreenState();
}

class _PrestamosScreenState extends State<PrestamosScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _busqueda = '';
  String? _filtroEstado;
  String? _filtroTipo;

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
      _items = await _crud.getAll();
    } catch (_) {
      _error = 'No se pudieron cargar los prestamos.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _nuevo() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const _CrearPrestamoScreen()));
    if (ok == true) _load();
  }

  Future<void> _devolver(Map<String, dynamic> item) async {
    final detalles = (item['detalles'] as List? ?? []).cast<Map<String, dynamic>>();
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: 'Registrar devolución',
      child: _DevolucionSheet(detalles: detalles),
    );
    if (result == null) return;
    try {
      await _api.post('${ApiEndpoints.prestamos}/${item['id']}/devoluciones', body: result);
      await _load();
      if (mounted) showAppSnackbar(context, 'Devolución registrada.', type: AppSnackbarType.success);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((p) {
      if (_filtroEstado != null && p['estado'] != _filtroEstado) return false;
      if (_filtroTipo != null && p['tipo'] != _filtroTipo) return false;
      if (q.isEmpty) return true;
      return '${p['tercero'] ?? ''} ${p['observaciones'] ?? ''}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  Future<void> _eliminar(Map<String, dynamic> item) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Eliminar préstamo',
      message: '¿Eliminar el préstamo de ${item['tercero'] ?? ''}?',
    );
    if (!ok) return;
    try {
      await CrudService(_api, ApiEndpoints.prestamos).delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(context, 'Préstamo eliminado', type: AppSnackbarType.error);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

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
                AppListHeader(
                  hintText: 'Buscar prestamos...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Estado',
                      value: _filtroEstado,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('pendiente', 'Pendiente'),
                        AppListFilterOption('prestado', 'Prestado'),
                        AppListFilterOption('parcial', 'Devuelto parcial'),
                        AppListFilterOption('devuelto', 'Devuelto'),
                      ],
                      onChanged: (v) => setState(() => _filtroEstado = v),
                    ),
                    AppListFilter(
                      label: 'Tipo',
                      value: _filtroTipo,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('prestado', 'Presté'),
                        AppListFilterOption('recibido', 'Me prestaron'),
                      ],
                      onChanged: (v) => setState(() => _filtroTipo = v),
                    ),
                  ],
                  activeFilters:
                      (_filtroEstado != null ? 1 : 0) +
                      (_filtroTipo != null ? 1 : 0),
                  onClearFilters: () => setState(() {
                    _filtroEstado = null;
                    _filtroTipo = null;
                  }),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(
                          child: Text(
                            _items.isEmpty ? 'No hay préstamos' : 'Ningun prestamo coincide con la busqueda',
                          ),
                        )
                      : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _visibles.length,
              itemBuilder: (context, index) {
                final item = _visibles[index];
                final presto = item['tipo'] == 'prestado';
                final estado = item['estado'] as String?;
                return DataCard(
                  title: '#${item['id']}  ${item['tercero'] ?? ''}',
                  rows: [
                    DataCardRow(
                      label: 'Tipo',
                      value: AppBadge(presto ? 'Presté' : 'Me prestaron',
                          type: presto ? AppBadgeType.danger : AppBadgeType.success),
                    ),
                    DataCardRow.text('Productos', '${(item['detalles'] as List?)?.length ?? 0}'),
                    DataCardRow(label: 'Estado', value: AppBadge(_estadoLabel[estado] ?? estado ?? '—', type: _estadoBadge(estado))),
                  ],
                  actions: [
                    DataCardAction(
                      icon: Icons.delete_outline,
                      color: AppColors.danger,
                      tooltip: 'Eliminar',
                      onTap: () => _eliminar(item),
                    ),
                    if (estado != 'devuelto') ...[
                          DataCardAction(
                            icon: Icons.assignment_return_outlined,
                            color: AppColors.primary,
                            tooltip: 'Devolución',
                            onTap: () => _devolver(item),
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

class _DevolucionSheet extends StatefulWidget {
  final List<Map<String, dynamic>> detalles;
  const _DevolucionSheet({required this.detalles});

  @override
  State<_DevolucionSheet> createState() => _DevolucionSheetState();
}

class _DevolucionSheetState extends State<_DevolucionSheet> {
  int? _presId;
  final _cantidad = TextEditingController();

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = <AppSelectOption<int>>[
      for (final d in widget.detalles)
        AppSelectOption(
          d['producto_presentacion_id'] as int,
          '${(d['presentacion']?['producto']?['nombre']) ?? 'Producto'} (${d['cantidad_prestada']})',
        ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSelect<int>(
          label: 'Producto',
          value: _presId,
          options: options,
          onChanged: (v) => setState(() => _presId = v),
        ),
        const SizedBox(height: 12),
        AppTextField(controller: _cantidad, label: 'Cantidad a devolver', keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SecondaryButton(label: 'Cancelar', onPressed: () => Navigator.pop(context))),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Devolver',
                onPressed: () {
                  final cant = double.tryParse(_cantidad.text.trim()) ?? 0;
                  if (_presId == null || cant <= 0) return;
                  Navigator.pop(context, {'producto_presentacion_id': _presId, 'cantidad': cant});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CrearPrestamoScreen extends StatefulWidget {
  const _CrearPrestamoScreen();

  @override
  State<_CrearPrestamoScreen> createState() => _CrearPrestamoScreenState();
}

class _CrearPrestamoScreenState extends State<_CrearPrestamoScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _almacenes = [];
  final List<AppSelectOption<int>> _presOptions = [];

  int? _almacenId;
  String _tipo = 'prestado';
  final _tercero = TextEditingController();
  final List<ProductLine> _lineas = [ProductLine(precio: '0')];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tercero.dispose();
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
    final lineas = _lineas.where((l) => l.presentacionId != null && l.cant > 0).toList();
    if (_almacenId == null) {
      showAppSnackbar(context, 'Selecciona el almacén', type: AppSnackbarType.error);
      return;
    }
    if (_tercero.text.trim().isEmpty) {
      showAppSnackbar(context, 'Ingresa el tercero', type: AppSnackbarType.error);
      return;
    }
    if (lineas.isEmpty) {
      showAppSnackbar(context, 'Agrega al menos un producto', type: AppSnackbarType.error);
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.post(ApiEndpoints.prestamos, body: {
        'almacen_id': _almacenId,
        'tipo': _tipo,
        'tercero': _tercero.text.trim(),
        'detalles': lineas.map((l) => {'producto_presentacion_id': l.presentacionId, 'cantidad_prestada': l.cant}).toList(),
      });
      if (mounted) {
        showAppSnackbar(context, 'Préstamo registrado. Stock actualizado.', type: AppSnackbarType.success);
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
      title: 'Nuevo Préstamo',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppFormSection(
                    title: 'Datos del préstamo',
                    children: [
                      AppSelect<String>(
                        label: 'Tipo',
                        icon: Icons.swap_horiz,
                        value: _tipo,
                        options: const [
                          AppSelectOption('prestado', 'Presté (sale stock)'),
                          AppSelectOption('recibido', 'Me prestaron (entra stock)'),
                        ],
                        onChanged: (v) => setState(() => _tipo = v ?? 'prestado'),
                      ),
                      AppTextField(controller: _tercero, label: 'Tercero', icon: Icons.storefront_outlined),
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
                    title: 'Productos',
                    children: [
                      ProductLinesEditor(
                        lines: _lineas,
                        options: _presOptions,
                        showPrice: false,
                        onAdd: () => setState(() => _lineas.add(ProductLine())),
                        onRemove: (i) => setState(() => _lineas.removeAt(i).dispose()),
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(label: 'Registrar préstamo', loading: _saving, onPressed: _guardar),
                ],
              ),
            ),
    );
  }
}
