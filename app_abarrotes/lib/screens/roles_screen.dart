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
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle.dart';
import '../widgets/data_card.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.roles);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _items = await _crud.getAll(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context, title: item == null ? 'Nuevo rol' : 'Editar rol',
      child: _RolFormSheet(initial: item),
    );
    if (result == null) return;
    try {
      if (index != null) { await _crud.update(item!['id'], result); }
      else { await _crud.create(result); }
      await _load();
      if (mounted) showAppSnackbar(context, item == null ? 'Rol creado' : 'Rol actualizado', type: AppSnackbarType.success);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(context, title: 'Eliminar rol', message: '¿Eliminar "${item['nombre']}"?');
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Rol eliminado', type: AppSnackbarType.error);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Roles',
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty ? const Center(child: Text('No hay roles'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final activo = item['activo'] as bool? ?? true;
                return DataCard(
                  title: item['nombre'] as String,
                  rows: [
                    DataCardRow.text('Guard', item['guard_name'] as String? ?? ''),
                    DataCardRow(label: 'Estado', value: AppBadge(activo ? 'Activo' : 'Inactivo', type: activo ? AppBadgeType.success : AppBadgeType.danger)),
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

class _RolFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _RolFormSheet({this.initial});

  @override
  State<_RolFormSheet> createState() => _RolFormSheetState();
}

class _RolFormSheetState extends State<_RolFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _guardName;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['name'] ?? '');
    _guardName = TextEditingController(text: widget.initial?['guard_name'] ?? 'web');
    _activo = widget.initial?['activo'] as bool? ?? true;
  }

  @override
  void dispose() { _nombre.dispose(); _guardName.dispose(); super.dispose(); }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {'name': _nombre.text.trim(), 'guard_name': _guardName.text.trim(), 'activo': _activo});
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(title: 'Datos del Rol', children: [
            AppTextField(controller: _nombre, label: 'Nombre', icon: Icons.badge_outlined, validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null),
            AppTextField(controller: _guardName, label: 'Guard', icon: Icons.security_outlined),
            AppToggle(label: 'Activo', value: _activo, onChanged: (v) => setState(() => _activo = v)),
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
