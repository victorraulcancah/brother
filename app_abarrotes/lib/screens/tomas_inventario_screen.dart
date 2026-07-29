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

import '../widgets/data_card.dart';

class TomasInventarioScreen extends StatefulWidget {
  const TomasInventarioScreen({super.key});

  @override
  State<TomasInventarioScreen> createState() => _TomasInventarioScreenState();
}

class _TomasInventarioScreenState extends State<TomasInventarioScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _almacenes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.tomas);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
      _almacenes = await CrudService(_api, ApiEndpoints.almacenes).getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context, title: item == null ? 'Nueva toma' : 'Editar toma',
      child: _TomaFormSheet(initial: item, almacenes: _almacenes),
    );
    if (result == null) return;
    try {
      if (index != null) { await _crud.update(item!['id'], result); }
      else { await _crud.create(result); }
      await _load();
      if (mounted) showAppSnackbar(context, item == null ? 'Toma registrada' : 'Toma actualizada', type: AppSnackbarType.success);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  Future<void> _delete(int index) async {
    final confirmado = await showAppConfirmDialog(context, title: 'Eliminar toma', message: '¿Eliminar esta toma de inventario?');
    if (!confirmado) return;
    try {
      await _crud.delete(_items[index]['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Toma eliminada', type: AppSnackbarType.error);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tomas de inventario',
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty ? const Center(child: Text('No hay tomas'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final estado = item['estado'] as String? ?? '';
                final cerrada = estado == 'cerrada';
                final almacen = item['almacen'] is Map ? (item['almacen'] as Map)['nombre'] as String? ?? '' : '';
                return DataCard(
                  title: '$almacen — ${item['fecha'] ?? ''}',
                  rows: [
                    DataCardRow(label: 'Estado', value: AppBadge(cerrada ? 'Cerrada' : 'En proceso', type: cerrada ? AppBadgeType.success : AppBadgeType.info)),
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

class _TomaFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> almacenes;
  const _TomaFormSheet({this.initial, required this.almacenes});

  @override
  State<_TomaFormSheet> createState() => _TomaFormSheetState();
}

class _TomaFormSheetState extends State<_TomaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _observaciones;
  int? _almacenId;
  String _estado = 'en_proceso';

  @override
  void initState() {
    super.initState();
    _observaciones = TextEditingController(text: widget.initial?['observaciones'] ?? '');
    _almacenId = widget.initial?['almacen_id'] as int?;
    if (_almacenId == null && widget.initial?['almacen'] is Map) {
      _almacenId = (widget.initial!['almacen'] as Map)['id'] as int?;
    }
    _estado = widget.initial?['estado'] as String? ?? 'en_proceso';
  }

  @override
  void dispose() { _observaciones.dispose(); super.dispose(); }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'almacen_id': _almacenId,
      'estado': _estado,
      'observaciones': _observaciones.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final almacenes = widget.almacenes.map((a) => AppSelectOption<int>(a['id'] as int, a['nombre'] as String)).toList();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(title: 'Datos de la toma', children: [
            AppSelect<int>(label: 'Almacén', icon: Icons.warehouse_outlined, value: _almacenId, options: almacenes, onChanged: (v) => setState(() => _almacenId = v), validator: (v) => v == null ? 'Seleccione un almacén' : null),
            AppSelect<String>(label: 'Estado', icon: Icons.flag_outlined, value: _estado, options: const [AppSelectOption('en_proceso', 'En proceso'), AppSelectOption('cerrada', 'Cerrada')], onChanged: (v) => setState(() => _estado = v ?? 'en_proceso')),
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
