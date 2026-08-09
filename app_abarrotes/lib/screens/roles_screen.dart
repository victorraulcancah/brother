import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
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
  String? _error;
  String _busqueda = '';
  String? _filtroGuard;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.roles);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await _crud.getAll();
    } catch (_) {
      // Antes se silenciaba: la lista quedaba vacia sin explicar por que.
      _error = 'No se pudieron cargar los roles.';
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Roles que pasan el buscador y el filtro por guard.
  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((r) {
      if (_filtroGuard != null && r['guard_name']?.toString() != _filtroGuard) {
        return false;
      }
      if (q.isEmpty) return true;
      return '${r['name']} ${r['guard_name']}'.toLowerCase().contains(q);
    }).toList();
  }

  List<AppListFilterOption> get _guards {
    final valores =
        _items
            .map((r) => r['guard_name']?.toString())
            .where((g) => g != null && g.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return [
      const AppListFilterOption(null, 'Todos los guards'),
      for (final g in valores) AppListFilterOption(g, g!),
    ];
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo rol' : 'Editar rol',
      child: _RolFormSheet(initial: item),
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
          item == null ? 'Rol creado' : 'Rol actualizado',
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
      title: 'Eliminar rol',
      message: '¿Eliminar el rol "${item['name']}"?',
    );
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(context, 'Rol eliminado', type: AppSnackbarType.error);
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
      title: 'Roles',
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
                  hintText: 'Buscar roles...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Guard',
                      value: _filtroGuard,
                      options: _guards,
                      onChanged: (v) => setState(() => _filtroGuard = v),
                    ),
                  ],
                  activeFilters: _filtroGuard != null ? 1 : 0,
                  onClearFilters: () => setState(() => _filtroGuard = null),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(
                          child: Text(
                            _items.isEmpty
                                ? 'No hay roles'
                                : 'Ningun rol coincide con la busqueda',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _visibles.length,
                          itemBuilder: (context, index) {
                            final item = _visibles[index];
                            return DataCard(
                              title: item['name']?.toString() ?? '',
                              rows: [
                                DataCardRow.text(
                                  'ID',
                                  item['id']?.toString() ?? '-',
                                ),
                                DataCardRow.text(
                                  'Guard',
                                  item['guard_name']?.toString() ?? '-',
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

class _RolFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const _RolFormSheet({this.initial});

  @override
  State<_RolFormSheet> createState() => _RolFormSheetState();
}

class _RolFormSheetState extends State<_RolFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?['name'] ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {'name': _name.text.trim()});
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(
            title: 'Datos del rol',
            children: [
              AppTextField(
                controller: _name,
                label: 'Nombre del rol',
                icon: Icons.shield_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
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
