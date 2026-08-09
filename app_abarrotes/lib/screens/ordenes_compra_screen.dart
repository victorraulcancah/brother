import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/data_card.dart';
import 'crear_compra_screen.dart';
import '../widgets/product_lines_editor.dart';

String _money(dynamic v) => 'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';

/// Etiqueta y color de cada estado de la orden, igual que en la web.
({String label, AppBadgeType type}) _estadoInfo(String? estado) =>
    switch (estado) {
      'aprobada' => (label: 'Aprobada', type: AppBadgeType.success),
      'enviada' => (label: 'Enviada', type: AppBadgeType.info),
      'parcial' => (label: 'Parcial', type: AppBadgeType.warning),
      'completada' => (label: 'Completada', type: AppBadgeType.success),
      'anulada' => (label: 'Anulada', type: AppBadgeType.danger),
      _ => (label: 'Pendiente', type: AppBadgeType.warning),
    };

/// Campo de solo lectura que explica que el código lo asigna el sistema.
class _CodigoAutomatico extends StatelessWidget {
  const _CodigoAutomatico();

  @override
  Widget build(BuildContext context) {
    return const TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Código',
        prefixIcon: Icon(Icons.tag),
        hintText: 'Se genera automáticamente',
      ),
    );
  }
}

class OrdenesCompraScreen extends StatefulWidget {
  const OrdenesCompraScreen({super.key});

  @override
  State<OrdenesCompraScreen> createState() => _OrdenesCompraScreenState();
}

class _OrdenesCompraScreenState extends State<OrdenesCompraScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.ordenes);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _nueva() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const _CrearOrdenScreen()));
    if (ok == true) _load();
  }

  /// La compra nace de la orden: se copian proveedor y lineas.
  Future<void> _transformar(Map<String, dynamic> item) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CrearCompraScreen(ordenId: item['id'] as int),
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await showAppConfirmDialog(context, title: 'Eliminar orden', message: '¿Eliminar la orden ${item['codigo']}?');
    if (!ok) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Orden eliminada', type: AppSnackbarType.error);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Órdenes de Compra',
      floatingActionButton: FloatingActionButton(onPressed: _nueva, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay órdenes'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final prov = item['proveedor'] as Map<String, dynamic>?;
                return DataCard(
                  title: item['codigo'] as String? ?? 'Orden',
                  rows: [
                    DataCardRow.text('Proveedor', prov?['nombre'] as String? ?? '—'),
                    DataCardRow.text('Emisión', '${item['fecha_emision'] ?? '—'}'),
                    DataCardRow.text('Productos', '${item['detalles_count'] ?? 0}'),
                    DataCardRow(
                      label: 'Estado',
                      value: AppBadge(
                        _estadoInfo(item['estado']?.toString()).label,
                        type: _estadoInfo(item['estado']?.toString()).type,
                      ),
                    ),
                    DataCardRow(
                      label: 'Compra',
                      value: AppBadge(
                        (item['compras_count'] ?? 0) > 0
                            ? 'Transformada'
                            : 'Sin compra',
                        type: (item['compras_count'] ?? 0) > 0
                            ? AppBadgeType.success
                            : AppBadgeType.neutral,
                      ),
                    ),
                  ],
                  actions: [
                    if ((item['compras_count'] ?? 0) == 0)
                      DataCardAction(
                        icon: Icons.shopping_bag_outlined,
                        color: AppColors.success,
                        tooltip: 'Transformar a compra',
                        onTap: () => _transformar(item),
                      ),
                    if ((item['compras_count'] ?? 0) == 0)
                      DataCardAction(
                        icon: Icons.delete_outline,
                        color: AppColors.danger,
                        tooltip: 'Eliminar',
                        onTap: () => _delete(item),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _CrearOrdenScreen extends StatefulWidget {
  const _CrearOrdenScreen();

  @override
  State<_CrearOrdenScreen> createState() => _CrearOrdenScreenState();
}

class _CrearOrdenScreenState extends State<_CrearOrdenScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _proveedores = [];
  final List<AppSelectOption<int>> _presOptions = [];

  int? _proveedorId;
  final List<ProductLine> _lineas = [ProductLine(precio: '0')];

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
        CrudService(_api, ApiEndpoints.proveedores).getAll(),
        CrudService(_api, ApiEndpoints.productos).getAll(),
      ]);
      _proveedores = results[0];
      for (final p in results[1]) {
        for (final pres in (p['presentaciones'] as List? ?? [])) {
          _presOptions.add(AppSelectOption(pres['id'] as int, '${p['nombre']} — ${pres['nombre']}'));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double get _total => _lineas.fold(0, (a, l) => a + l.subtotal);

  Future<void> _guardar() async {
    final lineas = _lineas.where((l) => l.presentacionId != null && l.cant > 0).toList();
    if (_proveedorId == null) {
      showAppSnackbar(context, 'Selecciona el proveedor', type: AppSnackbarType.error);
      return;
    }
    if (lineas.isEmpty) {
      showAppSnackbar(context, 'Agrega al menos un producto', type: AppSnackbarType.error);
      return;
    }
    final fecha = DateTime.now().toIso8601String().substring(0, 10);
    setState(() => _saving = true);
    try {
      await _api.post(ApiEndpoints.ordenes, body: {
        'proveedor_id': _proveedorId,
        'fecha_emision': fecha,
        'moneda': 'PEN',
        'detalles': lineas
            .map((l) => {'producto_presentacion_id': l.presentacionId, 'cantidad': l.cant, 'precio_unitario': l.precioVal})
            .toList(),
      });
      if (mounted) {
        showAppSnackbar(context, 'Orden creada', type: AppSnackbarType.success);
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
      title: 'Nueva Orden de Compra',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppFormSection(
                    title: 'Datos de la orden',
                    children: [
                      // El código es un correlativo interno que asigna el backend.
                      const _CodigoAutomatico(),
                      AppSelect<int>(
                        label: 'Proveedor',
                        icon: Icons.local_shipping_outlined,
                        value: _proveedorId,
                        options: [for (final p in _proveedores) AppSelectOption(p['id'] as int, p['nombre'] as String? ?? '')],
                        onChanged: (v) => setState(() => _proveedorId = v),
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
                        priceLabel: 'Precio',
                        onAdd: () => setState(() => _lineas.add(ProductLine(precio: '0'))),
                        onRemove: (i) => setState(() => _lineas.removeAt(i).dispose()),
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Total: ${_money(_total)}',
                      textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Crear orden', loading: _saving, onPressed: _guardar),
                ],
              ),
            ),
    );
  }
}
