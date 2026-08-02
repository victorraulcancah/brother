import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';
import '../widgets/product_lines_editor.dart';

String _money(dynamic v) => 'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';

class RecepcionesCompraScreen extends StatefulWidget {
  const RecepcionesCompraScreen({super.key});

  @override
  State<RecepcionesCompraScreen> createState() => _RecepcionesCompraScreenState();
}

class _RecepcionesCompraScreenState extends State<RecepcionesCompraScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.recepciones);
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
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const _CrearRecepcionScreen()));
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Recepciones de Compra',
      floatingActionButton: FloatingActionButton(onPressed: _nueva, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay recepciones'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final prov = item['proveedor'] as Map<String, dynamic>?;
                final almacen = item['almacen'] as Map<String, dynamic>?;
                final aplicado = item['stock_aplicado'] as bool? ?? false;
                final doc = item['documento'] as String? ?? '#${item['id']}';
                return DataCard(
                  title: '$doc  ·  ${prov?['nombre'] ?? 'Sin proveedor'}',
                  rows: [
                    DataCardRow.text('Almacén', almacen?['nombre'] as String? ?? '—'),
                    DataCardRow.text('Documento', '${item['numero_documento'] ?? '—'}'),
                    DataCardRow.text('Fecha', '${item['fecha_recepcion'] ?? '—'}'),
                    DataCardRow.text('Productos', '${item['detalles_count'] ?? 0}'),
                    DataCardRow(
                      label: 'Stock',
                      value: AppBadge(aplicado ? 'Ingresado' : 'Pendiente',
                          type: aplicado ? AppBadgeType.success : AppBadgeType.warning),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _CrearRecepcionScreen extends StatefulWidget {
  const _CrearRecepcionScreen();

  @override
  State<_CrearRecepcionScreen> createState() => _CrearRecepcionScreenState();
}

class _CrearRecepcionScreenState extends State<_CrearRecepcionScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _almacenes = [];
  final List<AppSelectOption<int>> _presOptions = [];

  int? _proveedorId;
  int? _almacenId;
  String _tipoDoc = 'factura';
  final _numeroDoc = TextEditingController();
  final List<ProductLine> _lineas = [ProductLine(precio: '0')];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _numeroDoc.dispose();
    for (final l in _lineas) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        CrudService(_api, ApiEndpoints.proveedores).getAll(),
        CrudService(_api, ApiEndpoints.almacenes).getAll(),
        CrudService(_api, ApiEndpoints.productos).getAll(),
      ]);
      _proveedores = results[0];
      _almacenes = results[1];
      for (final p in results[2]) {
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
    if (_almacenId == null) {
      showAppSnackbar(context, 'Selecciona el almacén', type: AppSnackbarType.error);
      return;
    }
    if (lineas.isEmpty) {
      showAppSnackbar(context, 'Agrega al menos un producto', type: AppSnackbarType.error);
      return;
    }
    final fecha = DateTime.now().toIso8601String().substring(0, 10);
    setState(() => _saving = true);
    try {
      await _api.post(ApiEndpoints.recepciones, body: {
        'proveedor_id': _proveedorId,
        'almacen_id': _almacenId,
        'tipo_documento': _tipoDoc,
        'numero_documento': _numeroDoc.text.trim(),
        'fecha_recepcion': fecha,
        'detalles': lineas
            .map((l) => {'producto_presentacion_id': l.presentacionId, 'cantidad_recibida': l.cant, 'costo_unitario': l.precioVal})
            .toList(),
      });
      if (mounted) {
        showAppSnackbar(context, 'Recepción registrada. Stock ingresado.', type: AppSnackbarType.success);
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
      title: 'Nueva Recepción',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppFormSection(
                    title: 'Datos de la recepción',
                    children: [
                      AppSelect<int>(
                        label: 'Proveedor',
                        icon: Icons.local_shipping_outlined,
                        value: _proveedorId,
                        options: [for (final p in _proveedores) AppSelectOption(p['id'] as int, p['nombre'] as String? ?? '')],
                        onChanged: (v) => setState(() => _proveedorId = v),
                      ),
                      AppSelect<int>(
                        label: 'Almacén',
                        icon: Icons.warehouse_outlined,
                        value: _almacenId,
                        options: [for (final a in _almacenes) AppSelectOption(a['id'] as int, a['nombre'] as String? ?? '')],
                        onChanged: (v) => setState(() => _almacenId = v),
                      ),
                      AppSelect<String>(
                        label: 'Tipo documento',
                        icon: Icons.description_outlined,
                        value: _tipoDoc,
                        options: const [
                          AppSelectOption('factura', 'Factura'),
                          AppSelectOption('boleta', 'Boleta'),
                          AppSelectOption('guia_remision', 'Guía de remisión'),
                        ],
                        onChanged: (v) => setState(() => _tipoDoc = v ?? 'factura'),
                      ),
                      AppTextField(controller: _numeroDoc, label: 'N° Documento', icon: Icons.numbers),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppFormSection(
                    title: 'Productos recibidos',
                    children: [
                      ProductLinesEditor(
                        lines: _lineas,
                        options: _presOptions,
                        priceLabel: 'Costo',
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
                  PrimaryButton(label: 'Registrar e ingresar stock', loading: _saving, onPressed: _guardar),
                ],
              ),
            ),
    );
  }
}
