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
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle.dart';
import '../widgets/data_card.dart';

class CajasScreen extends StatefulWidget {
  const CajasScreen({super.key});

  @override
  State<CajasScreen> createState() => _CajasScreenState();
}

class _CajasScreenState extends State<CajasScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  late final CrudService _almacenesCrud;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _almacenes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.cajas);
    _almacenesCrud = CrudService(_api, ApiEndpoints.almacenes);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_crud.getAll(), _almacenesCrud.getAll()]);
      _items = results[0];
      _almacenes = results[1];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva caja' : 'Editar caja',
      child: _CajaFormSheet(initial: item, almacenes: _almacenes),
    );
    if (result == null) return;
    try {
      if (index != null) {
        await _crud.update(item!['id'], result);
      } else {
        await _crud.create(result);
      }
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          item == null ? 'Caja creada' : 'Caja actualizada',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final ok = await showAppConfirmDialog(
      context,
      title: 'Eliminar caja',
      message: '¿Eliminar "${item['nombre']}"?',
    );
    if (!ok) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Caja eliminada', type: AppSnackbarType.error);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cajas',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay cajas'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final activo = item['activo'] as bool? ?? true;
                final almacen = item['almacen'] as Map<String, dynamic>?;
                return DataCard(
                  title: item['nombre'] as String? ?? '',
                  rows: [
                    DataCardRow.text('Almacén', almacen?['nombre'] as String? ?? '—'),
                    DataCardRow(
                      label: 'Estado',
                      value: AppBadge(
                        activo ? 'Activa' : 'Inactiva',
                        type: activo ? AppBadgeType.success : AppBadgeType.danger,
                      ),
                    ),
                  ],
                  actions: [
                    DataCardAction(
                      icon: Icons.edit_outlined,
                      color: AppColors.primary,
                      tooltip: 'Editar',
                      onTap: () => _openForm(item: item, index: index),
                    ),
                    DataCardAction(
                      icon: Icons.delete_outline,
                      color: AppColors.danger,
                      tooltip: 'Eliminar',
                      onTap: () => _delete(index),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _CajaFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> almacenes;
  const _CajaFormSheet({this.initial, required this.almacenes});

  @override
  State<_CajaFormSheet> createState() => _CajaFormSheetState();
}

class _CajaFormSheetState extends State<_CajaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  int? _almacenId;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _almacenId = widget.initial?['almacen_id'] as int?;
    _activo = widget.initial?['activo'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nombre': _nombre.text.trim(),
      'almacen_id': _almacenId,
      'activo': _activo,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(
            title: 'Datos de la Caja',
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.point_of_sale_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null,
              ),
              AppSelect<int>(
                label: 'Almacén',
                icon: Icons.warehouse_outlined,
                value: _almacenId,
                options: [
                  for (final a in widget.almacenes)
                    AppSelectOption(a['id'] as int, a['nombre'] as String? ?? ''),
                ],
                onChanged: (v) => setState(() => _almacenId = v),
              ),
              AppToggle(label: 'Activa', value: _activo, onChanged: (v) => setState(() => _activo = v)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Cancelar', onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 12),
              Expanded(child: PrimaryButton(label: 'Guardar', onPressed: _guardar)),
            ],
          ),
        ],
      ),
    );
  }
}
