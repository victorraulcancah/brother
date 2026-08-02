import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/data_card.dart';
import '../widgets/product_lines_editor.dart';

AppBadgeType _estadoBadge(String? e) => switch (e) {
      'pendiente' => AppBadgeType.warning,
      'en_transito' => AppBadgeType.info,
      'recibida' => AppBadgeType.success,
      'cancelada' => AppBadgeType.danger,
      _ => AppBadgeType.neutral,
    };

class TrasladosScreen extends StatefulWidget {
  const TrasladosScreen({super.key});

  @override
  State<TrasladosScreen> createState() => _TrasladosScreenState();
}

class _TrasladosScreenState extends State<TrasladosScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.transferencias);
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
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const _CrearTrasladoScreen()));
    if (ok == true) _load();
  }

  Future<void> _accion(Map<String, dynamic> item, String accion, String msg) async {
    try {
      await _api.post('${ApiEndpoints.transferencias}/${item['id']}/$accion', body: {});
      await _load();
      if (mounted) showAppSnackbar(context, msg, type: AppSnackbarType.success);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Traslados',
      floatingActionButton: FloatingActionButton(onPressed: _nuevo, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay traslados'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final origen = item['almacen_origen'] as Map<String, dynamic>?;
                final destino = item['almacen_destino'] as Map<String, dynamic>?;
                final estado = item['estado'] as String?;
                return DataCard(
                  title: '#${item['id']}  ${origen?['nombre'] ?? '—'} → ${destino?['nombre'] ?? '—'}',
                  rows: [
                    DataCardRow.text('Productos', '${item['detalles_count'] ?? 0}'),
                    DataCardRow(label: 'Estado', value: AppBadge(estado ?? '—', type: _estadoBadge(estado))),
                  ],
                  actions: [
                    if (estado == 'pendiente')
                      DataCardAction(
                        icon: Icons.send_outlined,
                        color: AppColors.info,
                        tooltip: 'Enviar',
                        onTap: () => _accion(item, 'enviar', 'Traslado enviado. Stock descontado del origen.'),
                      ),
                    if (estado == 'en_transito')
                      DataCardAction(
                        icon: Icons.inventory_outlined,
                        color: AppColors.success,
                        tooltip: 'Recibir',
                        onTap: () => _accion(item, 'recibir', 'Traslado recibido. Stock ingresado al destino.'),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _CrearTrasladoScreen extends StatefulWidget {
  const _CrearTrasladoScreen();

  @override
  State<_CrearTrasladoScreen> createState() => _CrearTrasladoScreenState();
}

class _CrearTrasladoScreenState extends State<_CrearTrasladoScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _almacenes = [];
  final List<AppSelectOption<int>> _presOptions = [];

  int? _origenId;
  int? _destinoId;
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
    if (_origenId == null || _destinoId == null) {
      showAppSnackbar(context, 'Selecciona origen y destino', type: AppSnackbarType.error);
      return;
    }
    if (_origenId == _destinoId) {
      showAppSnackbar(context, 'El origen y destino deben ser distintos', type: AppSnackbarType.error);
      return;
    }
    if (lineas.isEmpty) {
      showAppSnackbar(context, 'Agrega al menos un producto', type: AppSnackbarType.error);
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.post(ApiEndpoints.transferencias, body: {
        'almacen_origen_id': _origenId,
        'almacen_destino_id': _destinoId,
        'detalles': lineas.map((l) => {'producto_presentacion_id': l.presentacionId, 'cantidad_enviada': l.cant}).toList(),
      });
      if (mounted) {
        showAppSnackbar(context, 'Traslado creado. Envíalo para descontar stock.', type: AppSnackbarType.success);
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
      title: 'Nuevo Traslado',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppFormSection(
                    title: 'Almacenes',
                    children: [
                      AppSelect<int>(
                        label: 'Almacén origen',
                        icon: Icons.output,
                        value: _origenId,
                        options: [for (final a in _almacenes) AppSelectOption(a['id'] as int, a['nombre'] as String? ?? '')],
                        onChanged: (v) => setState(() => _origenId = v),
                      ),
                      AppSelect<int>(
                        label: 'Almacén destino',
                        icon: Icons.input,
                        value: _destinoId,
                        options: [for (final a in _almacenes) AppSelectOption(a['id'] as int, a['nombre'] as String? ?? '')],
                        onChanged: (v) => setState(() => _destinoId = v),
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
                  PrimaryButton(label: 'Crear traslado', loading: _saving, onPressed: _guardar),
                ],
              ),
            ),
    );
  }
}
