import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
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
  List<Map<String, dynamic>> _empresas = [];
  bool _loading = true;
  String? _error;
  String _busqueda = '';
  String? _filtroRol;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.usuarios);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // En paralelo: la app las pedia en serie y no cargaba empresas.
      final resultados = await Future.wait([
        _crud.getAll(),
        CrudService(_api, ApiEndpoints.roles).getAll(),
        CrudService(_api, ApiEndpoints.empresas).getAll(),
      ]);
      _items = resultados[0];
      _roles = resultados[1];
      _empresas = resultados[2];
    } catch (_) {
      _error = 'No se pudieron cargar los datos.';
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Nombre del primer rol del usuario, que es como se asigna hoy.
  String? _rolDe(Map<String, dynamic> u) {
    final roles = u['roles'];
    if (roles is! List || roles.isEmpty) return null;
    final primero = roles.first;
    return primero is Map ? primero['name']?.toString() : primero.toString();
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((u) {
      if (_filtroRol != null && _rolDe(u) != _filtroRol) return false;
      if (q.isEmpty) return true;
      final empresa =
          (u['empresa'] as Map<String, dynamic>?)?['nombre_comercial'] ?? '';
      return '${u['name']} ${u['email']} ${_rolDe(u) ?? ''} $empresa'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  List<AppListFilterOption> get _opcionesRol => [
    const AppListFilterOption(null, 'Todos los roles'),
    for (final r in _roles)
      AppListFilterOption(r['name']?.toString(), r['name']?.toString() ?? ''),
  ];

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo usuario' : 'Editar usuario',
      child: _UsuarioFormSheet(
        initial: item,
        roles: _roles,
        empresas: _empresas,
      ),
    );
    if (result == null) return;
    try {
      if (item != null) {
        await _crud.update(item['id'], result);
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

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar usuario',
      message: '¿Eliminar "${item['name']}"? Esta acción no se puede deshacer.',
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
          : Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AppMessage(text: _error!),
                  ),
                AppListHeader(
                  hintText: 'Buscar usuarios...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Rol',
                      value: _filtroRol,
                      options: _opcionesRol,
                      onChanged: (v) => setState(() => _filtroRol = v),
                    ),
                  ],
                  activeFilters: _filtroRol != null ? 1 : 0,
                  onClearFilters: () => setState(() => _filtroRol = null),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(
                          child: Text(
                            _items.isEmpty
                                ? 'No hay usuarios'
                                : 'Ningun usuario coincide con la busqueda',
                          ),
                        )
                      : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _visibles.length,
              itemBuilder: (context, index) {
                final item = _visibles[index];
                return DataCard(
                  title: '${item['name'] ?? ''} (${item['email'] ?? ''})',
                  rows: [
                    DataCardRow(
                      label: 'Rol',
                      value: AppBadge(
                        _rolDe(item) ?? 'Sin rol',
                        type: _rolDe(item) == null
                            ? AppBadgeType.neutral
                            : AppBadgeType.info,
                      ),
                    ),
                    DataCardRow.text(
                      'Empresa',
                      (item['empresa']
                              as Map<String, dynamic>?)?['nombre_comercial']
                          as String? ??
                          '-',
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
                      onTap: () => _openForm(item: item),
                    ),
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
                ),
              ],
            ),
    );
  }
}

class _UsuarioFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> roles;
  final List<Map<String, dynamic>> empresas;
  const _UsuarioFormSheet({
    this.initial,
    required this.roles,
    required this.empresas,
  });

  @override
  State<_UsuarioFormSheet> createState() => _UsuarioFormSheetState();
}

class _UsuarioFormSheetState extends State<_UsuarioFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;
  String? _selectedRole;
  String? _empresaId;
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
    final empresa = widget.initial?['empresa'];
    _empresaId = empresa is Map
        ? empresa['id']?.toString()
        : widget.initial?['empresa_id']?.toString();
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
      // Cadena vacía = "sin rol"/"sin empresa": se manda null, no ''.
      'role': (_selectedRole?.isEmpty ?? true) ? null : _selectedRole,
      'empresa_id': (_empresaId?.isEmpty ?? true) ? null : _empresaId,
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
    // Se incluye la opcion vacia para poder dejar el usuario sin rol/empresa.
    final roles = <AppSelectOption<String>>[
      const AppSelectOption<String>('', 'Sin rol'),
      for (final r in widget.roles)
        AppSelectOption<String>(r['name'] as String, r['name'] as String),
    ];

    final empresas = <AppSelectOption<String>>[
      const AppSelectOption<String>('', 'Sin empresa'),
      for (final e in widget.empresas)
        AppSelectOption<String>(
          e['id'].toString(),
          e['nombre_comercial']?.toString() ??
              e['razon_social']?.toString() ??
              'Empresa ${e['id']}',
        ),
    ];

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
              AppSelect<String>(
                label: 'Empresa',
                value: _empresaId,
                options: empresas,
                onChanged: (v) => setState(() => _empresaId = v),
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
