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
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle.dart';
import '../widgets/data_card.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _busqueda = '';
  String? _filtroEstado;
  String? _filtroTipoDoc;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.clientes);
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
      _error = 'No se pudieron cargar los clientes.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo cliente' : 'Editar cliente',
      child: _ClienteFormSheet(initial: item),
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
          item == null ? 'Cliente creado' : 'Cliente actualizado',
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
      title: 'Eliminar cliente',
      message: '¿Eliminar "${item['nombre']}"?',
    );
    if (!ok) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Cliente eliminado', type: AppSnackbarType.error);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((c) {
      if (_filtroTipoDoc != null && c['tipo_documento'] != _filtroTipoDoc) {
        return false;
      }
      if (_filtroEstado == 'activos' && c['activo'] != true) return false;
      if (_filtroEstado == 'inactivos' && c['activo'] == true) return false;
      if (q.isEmpty) return true;
      return '${c['nombre']} ${c['numero_documento'] ?? ''} ${c['telefono'] ?? ''}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Clientes',
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
                  hintText: 'Buscar clientes...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Tipo doc.',
                      value: _filtroTipoDoc,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('DNI', 'DNI'),
                        AppListFilterOption('RUC', 'RUC'),
                        AppListFilterOption('CE', 'CE'),
                        AppListFilterOption('SIN', 'Sin documento'),
                      ],
                      onChanged: (v) => setState(() => _filtroTipoDoc = v),
                    ),
                    AppListFilter(
                      label: 'Estado',
                      value: _filtroEstado,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('activos', 'Activos'),
                        AppListFilterOption('inactivos', 'Inactivos'),
                      ],
                      onChanged: (v) => setState(() => _filtroEstado = v),
                    ),
                  ],
                  activeFilters:
                      (_filtroTipoDoc != null ? 1 : 0) +
                      (_filtroEstado != null ? 1 : 0),
                  onClearFilters: () => setState(() {
                    _filtroTipoDoc = null;
                    _filtroEstado = null;
                  }),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(child: Text(_items.isEmpty ? 'No hay clientes' : 'Ningun cliente coincide con la busqueda'))
                      : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _visibles.length,
              itemBuilder: (context, index) {
                final item = _visibles[index];
                final activo = item['activo'] as bool? ?? true;
                final doc = [item['tipo_documento'], item['numero_documento']]
                    .where((e) => e != null && '$e'.isNotEmpty)
                    .join(' ');
                return DataCard(
                  title: item['nombre'] as String? ?? '',
                  rows: [
                    DataCardRow.text('Documento', doc),
                    DataCardRow.text('Teléfono', item['telefono'] as String? ?? ''),
                    DataCardRow.text('Email', item['email'] as String? ?? ''),
                    DataCardRow.text('Dirección', item['direccion'] as String? ?? ''),
                    DataCardRow(
                      label: 'Estado',
                      value: AppBadge(
                        activo ? 'Activo' : 'Inactivo',
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
                ),
              ],
            ),
    );
  }
}

class _ClienteFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _ClienteFormSheet({this.initial});

  @override
  State<_ClienteFormSheet> createState() => _ClienteFormSheetState();
}

class _ClienteFormSheetState extends State<_ClienteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _numeroDoc;
  late final TextEditingController _direccion;
  late final TextEditingController _telefono;
  late final TextEditingController _email;
  String _tipoDoc = 'DNI';
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _numeroDoc = TextEditingController(text: widget.initial?['numero_documento'] ?? '');
    _direccion = TextEditingController(text: widget.initial?['direccion'] ?? '');
    _telefono = TextEditingController(text: widget.initial?['telefono'] ?? '');
    _email = TextEditingController(text: widget.initial?['email'] ?? '');
    _tipoDoc = widget.initial?['tipo_documento'] as String? ?? 'DNI';
    _activo = widget.initial?['activo'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _numeroDoc.dispose();
    _direccion.dispose();
    _telefono.dispose();
    _email.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nombre': _nombre.text.trim(),
      'tipo_documento': _tipoDoc,
      'numero_documento': _numeroDoc.text.trim(),
      'direccion': _direccion.text.trim(),
      'telefono': _telefono.text.trim(),
      'email': _email.text.trim(),
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
            title: 'Datos del Cliente',
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null,
              ),
              AppSelect<String>(
                label: 'Tipo de documento',
                icon: Icons.badge_outlined,
                value: _tipoDoc,
                options: const [
                  AppSelectOption('DNI', 'DNI'),
                  AppSelectOption('RUC', 'RUC'),
                  AppSelectOption('CE', 'Carné de extranjería'),
                  AppSelectOption('SIN', 'Sin documento'),
                ],
                onChanged: (v) => setState(() => _tipoDoc = v ?? 'DNI'),
              ),
              AppTextField(controller: _numeroDoc, label: 'N° Documento', icon: Icons.badge),
              AppTextField(controller: _telefono, label: 'Teléfono', icon: Icons.phone_outlined),
              AppTextField(controller: _email, label: 'Email', icon: Icons.email_outlined),
              AppTextField(controller: _direccion, label: 'Dirección', icon: Icons.location_on_outlined),
              AppToggle(label: 'Activo', value: _activo, onChanged: (v) => setState(() => _activo = v)),
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
