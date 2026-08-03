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

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _roles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.usuarios);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
      _roles = await CrudService(_api, ApiEndpoints.roles).getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo usuario' : 'Editar usuario',
      child: _UsuarioFormSheet(initial: item, roles: _roles),
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
          item == null ? 'Usuario creado' : 'Usuario actualizado',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar usuario',
      message: '¿Eliminar "${item['name']}"?',
    );
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Usuario eliminado',
          type: AppSnackbarType.error,
        );
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
      title: 'Usuarios',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay usuarios'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return DataCard(
                  title: '${item['name'] ?? ''} (${item['email'] ?? ''})',
                  rows: [
                    DataCardRow.text(
                      'Rol',
                      item['roles'] is List
                          ? (item['roles'] as List)
                                .map(
                                  (r) => r is Map
                                      ? r['name']?.toString() ?? ''
                                      : r.toString(),
                                )
                                .join(', ')
                          : '',
                    ),
                    DataCardRow.text(
                      'Caja',
                      (item['caja'] as Map<String, dynamic>?)?['nombre'] as String? ?? '—',
                    ),
                    DataCardRow(
                      label: 'Verificado',
                      value: AppBadge(
                        item['email_verified_at'] != null ? 'Sí' : 'No',
                        type: item['email_verified_at'] != null
                            ? AppBadgeType.success
                            : AppBadgeType.warning,
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

class _UsuarioFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> roles;
  const _UsuarioFormSheet({this.initial, required this.roles});

  @override
  State<_UsuarioFormSheet> createState() => _UsuarioFormSheetState();
}

class _UsuarioFormSheetState extends State<_UsuarioFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;
  String? _selectedRole;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?['name'] ?? '');
    _email = TextEditingController(text: widget.initial?['email'] ?? '');
    _password = TextEditingController();
    final rolesData = widget.initial?['roles'];
    if (rolesData is List && rolesData.isNotEmpty) {
      final first = rolesData.first;
      _selectedRole = first is Map
          ? first['name']?.toString()
          : first.toString();
    }
    _activo = widget.initial?['activo'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'role': _selectedRole,
      'activo': _activo,
    };
    if (_password.text.trim().isNotEmpty) {
      data['password'] = _password.text.trim();
      data['password_confirmation'] = _password.text.trim();
    }
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    final roles = widget.roles
        .map(
          (r) =>
              AppSelectOption<String>(r['name'] as String, r['name'] as String),
        )
        .toList();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(
            title: 'Datos del Usuario',
            children: [
              AppTextField(
                controller: _name,
                label: 'Nombre',
                icon: Icons.person,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppTextField(
                controller: _email,
                label: 'Email',
                icon: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingrese el email';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              AppTextField(
                controller: _password,
                label: widget.initial == null
                    ? 'Contraseña'
                    : 'Nueva contraseña (opcional)',
                icon: Icons.lock_outlined,
                obscureText: true,
              ),
              AppSelect<String>(
                label: 'Rol',
                value: _selectedRole,
                options: roles,
                onChanged: (v) => setState(() => _selectedRole = v),
              ),
              AppToggle(
                label: 'Activo',
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Cancelar',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(label: 'Guardar', onPressed: _guardar),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
