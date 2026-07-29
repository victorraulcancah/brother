import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';

import '../widgets/app_snackbar.dart';
import '../widgets/app_text_area.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';

class RecepcionesCompraScreen extends StatefulWidget {
  const RecepcionesCompraScreen({super.key});

  @override
  State<RecepcionesCompraScreen> createState() => _RecepcionesCompraScreenState();
}

class _RecepcionesCompraScreenState extends State<RecepcionesCompraScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _ordenes = [];
  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _almacenes = [];
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
      _ordenes = await CrudService(_api, ApiEndpoints.ordenes).getAll();
      _proveedores = await CrudService(_api, ApiEndpoints.proveedores).getAll();
      _almacenes = await CrudService(_api, ApiEndpoints.almacenes).getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context, title: item == null ? 'Nueva recepción' : 'Editar recepción',
      child: _RecepcionFormSheet(initial: item, ordenes: _ordenes, proveedores: _proveedores, almacenes: _almacenes),
    );
    if (result == null) return;
    try {
      if (index != null) { await _crud.update(item!['id'], result); }
      else { await _crud.create(result); }
      await _load();
      if (mounted) showAppSnackbar(context, item == null ? 'Recepción registrada' : 'Recepción actualizada', type: AppSnackbarType.success);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(context, title: 'Eliminar recepción', message: '¿Eliminar "${item['numero_documento']}"?');
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Recepción eliminada', type: AppSnackbarType.error);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  String _estadoLabel(String estado) => switch (estado) {
    'pendiente' => 'Pendiente', 'parcial' => 'Parcial', 'completa' => 'Completa', _ => estado,
  };

  AppBadgeType _estadoType(String estado) => switch (estado) {
    'completa' => AppBadgeType.success, 'parcial' => AppBadgeType.info, _ => AppBadgeType.warning,
  };

  String _relValue(Map? rel, String field) => rel?[field] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Recepciones de compra',
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty ? const Center(child: Text('No hay recepciones'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final estado = item['estado'] as String? ?? '';
                return DataCard(
                  title: item['numero_documento'] as String? ?? '',
                  rows: [
                    DataCardRow.text('Orden', _relValue(item['orden_compra'] as Map?, 'codigo')),
                    DataCardRow.text('Proveedor', _relValue(item['proveedor'] as Map?, 'nombre')),
                    DataCardRow.text('Almacén', _relValue(item['almacen'] as Map?, 'nombre')),
                    DataCardRow.text('Fecha', item['fecha_recepcion'] as String? ?? ''),
                    DataCardRow(label: 'Estado', value: AppBadge(_estadoLabel(estado), type: _estadoType(estado))),
                  ],
                  actions: [
                    DataCardAction(icon: Icons.edit_outlined, color: AppColors.primary, tooltip: 'Editar', onTap: () => _openForm(item: item, index: index)),
                    DataCardAction(icon: Icons.delete_outline, color: AppColors.danger, tooltip: 'Eliminar', onTap: () => _delete(index)),
                  ],
                );
              },
            ),
    );
  }
}

class _RecepcionFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> ordenes;
  final List<Map<String, dynamic>> proveedores;
  final List<Map<String, dynamic>> almacenes;
  const _RecepcionFormSheet({this.initial, required this.ordenes, required this.proveedores, required this.almacenes});

  @override
  State<_RecepcionFormSheet> createState() => _RecepcionFormSheetState();
}

class _RecepcionFormSheetState extends State<_RecepcionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numeroDoc;
  late final TextEditingController _fecha;
  late final TextEditingController _observaciones;
  int? _ordenId;
  int? _proveedorId;
  int? _almacenId;
  String _estado = 'pendiente';

  @override
  void initState() {
    super.initState();
    _numeroDoc = TextEditingController(text: widget.initial?['numero_documento'] ?? '');
    _fecha = TextEditingController(text: widget.initial?['fecha_recepcion'] ?? '');
    _observaciones = TextEditingController(text: widget.initial?['observaciones'] ?? '');
    _ordenId = _extractId(widget.initial, 'orden_compra_id', 'orden_compra');
    _proveedorId = _extractId(widget.initial, 'proveedor_id', 'proveedor');
    _almacenId = _extractId(widget.initial, 'almacen_id', 'almacen');
    _estado = widget.initial?['estado'] as String? ?? 'pendiente';
  }

  int? _extractId(Map<String, dynamic>? item, String directField, String relField) {
    if (item?[directField] != null) return item![directField] as int;
    final rel = item?[relField] as Map?;
    return rel?['id'] as int?;
  }

  @override
  void dispose() { _numeroDoc.dispose(); _fecha.dispose(); _observaciones.dispose(); super.dispose(); }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'numero_documento': _numeroDoc.text.trim(),
      'orden_compra_id': _ordenId,
      'proveedor_id': _proveedorId,
      'almacen_id': _almacenId,
      'fecha_recepcion': _fecha.text.trim(),
      'estado': _estado,
      'observaciones': _observaciones.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordenes = widget.ordenes.map((o) => AppSelectOption<int>(o['id'] as int, o['codigo'] as String? ?? '')).toList();
    final proveedores = widget.proveedores.map((p) => AppSelectOption<int>(p['id'] as int, p['nombre'] as String)).toList();
    final almacenes = widget.almacenes.map((a) => AppSelectOption<int>(a['id'] as int, a['nombre'] as String)).toList();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(title: 'Datos de la recepción', children: [
            AppTextField(controller: _numeroDoc, label: 'N° documento', icon: Icons.receipt_long_outlined, validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el documento' : null),
            AppSelect<int>(label: 'Orden de compra', icon: Icons.assignment_outlined, value: _ordenId, options: ordenes, onChanged: (v) => setState(() => _ordenId = v)),
            AppSelect<int>(label: 'Proveedor', icon: Icons.local_shipping_outlined, value: _proveedorId, options: proveedores, onChanged: (v) => setState(() => _proveedorId = v)),
            AppSelect<int>(label: 'Almacén', icon: Icons.warehouse_outlined, value: _almacenId, options: almacenes, onChanged: (v) => setState(() => _almacenId = v), validator: (v) => v == null ? 'Seleccione un almacén' : null),
            AppTextField(controller: _fecha, label: 'Fecha recepción (AAAA-MM-DD)', icon: Icons.event_outlined),
            AppSelect<String>(label: 'Estado', icon: Icons.flag_outlined, value: _estado, options: const [AppSelectOption('pendiente', 'Pendiente'), AppSelectOption('parcial', 'Parcial'), AppSelectOption('completa', 'Completa')], onChanged: (v) => setState(() => _estado = v ?? 'pendiente')),
            AppTextArea(controller: _observaciones, label: 'Observaciones'),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: SecondaryButton(label: 'Cancelar', onPressed: () => Navigator.pop(context))),
            const SizedBox(width: 12),
            Expanded(child: PrimaryButton(label: 'Guardar', onPressed: _guardar)),
          ]),
        ],
      ),
    );
  }
}
