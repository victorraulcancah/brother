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

class OrdenesCompraScreen extends StatefulWidget {
  const OrdenesCompraScreen({super.key});

  @override
  State<OrdenesCompraScreen> createState() => _OrdenesCompraScreenState();
}

class _OrdenesCompraScreenState extends State<OrdenesCompraScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _proveedores = [];
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
      _proveedores = await CrudService(_api, ApiEndpoints.proveedores).getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context, title: item == null ? 'Nueva orden' : 'Editar orden',
      child: _OrdenFormSheet(initial: item, proveedores: _proveedores),
    );
    if (result == null) return;
    try {
      if (index != null) { await _crud.update(item!['id'], result); }
      else { await _crud.create(result); }
      await _load();
      if (mounted) showAppSnackbar(context, item == null ? 'Orden creada' : 'Orden actualizada', type: AppSnackbarType.success);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(context, title: 'Eliminar orden', message: '¿Eliminar "${item['codigo']}"?');
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Orden eliminada', type: AppSnackbarType.error);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  String _estadoLabel(String estado) => switch (estado) {
    'borrador' => 'Borrador', 'enviada' => 'Enviada', 'recibida' => 'Recibida', 'anulada' => 'Anulada', _ => estado,
  };

  AppBadgeType _estadoType(String estado) => switch (estado) {
    'enviada' => AppBadgeType.info, 'recibida' => AppBadgeType.success, 'anulada' => AppBadgeType.danger, _ => AppBadgeType.neutral,
  };

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Órdenes de compra',
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty ? const Center(child: Text('No hay órdenes'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final estado = item['estado'] as String? ?? '';
                return DataCard(
                  title: item['codigo'] as String? ?? '',
                  rows: [
                    DataCardRow.text('Proveedor', item['proveedor'] is Map ? (item['proveedor'] as Map)['nombre'] as String? ?? '' : ''),
                    DataCardRow.text('Fecha', item['fecha_emision'] as String? ?? ''),
                    DataCardRow.text('Moneda', item['moneda'] as String? ?? ''),
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

class _OrdenFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> proveedores;
  const _OrdenFormSheet({this.initial, required this.proveedores});

  @override
  State<_OrdenFormSheet> createState() => _OrdenFormSheetState();
}

class _OrdenFormSheetState extends State<_OrdenFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _fecha;
  late final TextEditingController _observaciones;
  int? _proveedorId;
  String _moneda = 'PEN';
  String _estado = 'borrador';

  @override
  void initState() {
    super.initState();
    _codigo = TextEditingController(text: widget.initial?['codigo'] ?? '');
    _fecha = TextEditingController(text: widget.initial?['fecha_emision'] ?? '');
    _observaciones = TextEditingController(text: widget.initial?['observaciones'] ?? '');
    _proveedorId = widget.initial?['proveedor_id'] as int?;
    if (_proveedorId == null && widget.initial?['proveedor'] is Map) {
      _proveedorId = (widget.initial!['proveedor'] as Map)['id'] as int?;
    }
    _moneda = widget.initial?['moneda'] as String? ?? 'PEN';
    _estado = widget.initial?['estado'] as String? ?? 'borrador';
  }

  @override
  void dispose() { _codigo.dispose(); _fecha.dispose(); _observaciones.dispose(); super.dispose(); }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'codigo': _codigo.text.trim(),
      'proveedor_id': _proveedorId,
      'fecha_emision': _fecha.text.trim(),
      'moneda': _moneda,
      'estado': _estado,
      'observaciones': _observaciones.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final proveedores = widget.proveedores.map((p) => AppSelectOption<int>(p['id'] as int, p['nombre'] as String)).toList();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(title: 'Datos de la orden', children: [
            AppTextField(controller: _codigo, label: 'Código', icon: Icons.tag, validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el código' : null),
            AppSelect<int>(label: 'Proveedor', icon: Icons.local_shipping_outlined, value: _proveedorId, options: proveedores, onChanged: (v) => setState(() => _proveedorId = v), validator: (v) => v == null ? 'Seleccione un proveedor' : null),
            AppTextField(controller: _fecha, label: 'Fecha emisión (AAAA-MM-DD)', icon: Icons.event_outlined, validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese la fecha' : null),
            AppSelect<String>(label: 'Moneda', icon: Icons.payments_outlined, value: _moneda, options: const [AppSelectOption('PEN', 'Soles (PEN)'), AppSelectOption('USD', 'Dólares (USD)')], onChanged: (v) => setState(() => _moneda = v ?? 'PEN')),
            AppSelect<String>(label: 'Estado', icon: Icons.flag_outlined, value: _estado, options: const [AppSelectOption('borrador', 'Borrador'), AppSelectOption('enviada', 'Enviada'), AppSelectOption('recibida', 'Recibida'), AppSelectOption('anulada', 'Anulada')], onChanged: (v) => setState(() => _estado = v ?? 'borrador')),
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
