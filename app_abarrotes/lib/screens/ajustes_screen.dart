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

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.ajustes);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _nuevo() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const _CrearAjusteScreen()));
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ajustes',
      floatingActionButton: FloatingActionButton(onPressed: _nuevo, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay ajustes'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final almacen = item['almacen'] as Map<String, dynamic>?;
                final entrada = item['tipo'] == 'entrada';
                return DataCard(
                  title: 'Ajuste #${item['id']}',
                  rows: [
                    DataCardRow.text('Almacén', almacen?['nombre'] as String? ?? '—'),
                    DataCardRow(
                      label: 'Tipo',
                      value: AppBadge(entrada ? 'Entrada' : 'Salida',
                          type: entrada ? AppBadgeType.success : AppBadgeType.danger),
                    ),
                    DataCardRow.text('Motivo', item['motivo'] as String? ?? '—'),
                    DataCardRow.text('Productos', '${item['detalles_count'] ?? 0}'),
                    DataCardRow.text('Fecha', '${item['fecha'] ?? '—'}'),
                  ],
                );
              },
            ),
    );
  }
}

class _CrearAjusteScreen extends StatefulWidget {
  const _CrearAjusteScreen();

  @override
  State<_CrearAjusteScreen> createState() => _CrearAjusteScreenState();
}

class _CrearAjusteScreenState extends State<_CrearAjusteScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _almacenes = [];
  final List<AppSelectOption<int>> _presOptions = [];

  int? _almacenId;
  String _tipo = 'entrada';
  final _motivo = TextEditingController();
  final List<ProductLine> _lineas = [ProductLine(precio: '0')];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _motivo.dispose();
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
    if (lineas.isEmpty) {
      showAppSnackbar(context, 'Agrega al menos un producto', type: AppSnackbarType.error);
      return;
    }
    if (_motivo.text.trim().isEmpty) {
      showAppSnackbar(context, 'Ingresa el motivo', type: AppSnackbarType.error);
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.post(ApiEndpoints.ajustes, body: {
        'almacen_id': _almacenId,
        'tipo': _tipo,
        'motivo': _motivo.text.trim(),
        'detalles': lineas.map((l) => {'producto_presentacion_id': l.presentacionId, 'cantidad': l.cant}).toList(),
      });
      if (mounted) {
        showAppSnackbar(context, 'Ajuste aplicado. Stock actualizado.', type: AppSnackbarType.success);
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
      title: 'Nuevo Ajuste',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppFormSection(
                    title: 'Datos del ajuste',
                    children: [
                      AppSelect<int>(
                        label: 'Almacén',
                        icon: Icons.warehouse_outlined,
                        value: _almacenId,
                        options: [for (final a in _almacenes) AppSelectOption(a['id'] as int, a['nombre'] as String? ?? '')],
                        onChanged: (v) => setState(() => _almacenId = v),
                      ),
                      AppSelect<String>(
                        label: 'Tipo',
                        icon: Icons.swap_vert,
                        value: _tipo,
                        options: const [AppSelectOption('entrada', 'Entrada (suma)'), AppSelectOption('salida', 'Salida (resta)')],
                        onChanged: (v) => setState(() => _tipo = v ?? 'entrada'),
                      ),
                      AppTextField(controller: _motivo, label: 'Motivo', icon: Icons.edit_note),
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
                  PrimaryButton(label: 'Aplicar ajuste', loading: _saving, onPressed: _guardar),
                ],
              ),
            ),
    );
  }
}
