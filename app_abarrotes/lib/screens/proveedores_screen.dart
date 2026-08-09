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
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle.dart';
import '../widgets/data_card.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.proveedores);
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
      _error = 'No se pudieron cargar los proveedores.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items
        .where(
          (p) =>
              '${p['nombre']} ${p['codigo']} ${p['ruc']} ${p['contacto_nombre']}'
                  .toLowerCase()
                  .contains(q),
        )
        .toList();
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo proveedor' : 'Editar proveedor',
      child: _ProveedorFormSheet(initial: item),
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
          item == null ? 'Proveedor creado' : 'Proveedor actualizado',
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
      title: 'Eliminar proveedor',
      message: '¿Eliminar "${item['nombre']}"?',
    );
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Proveedor eliminado',
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
      title: 'Proveedores',
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
                  hintText: 'Buscar proveedores...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(
                          child: Text(
                            _items.isEmpty
                                ? 'No hay proveedores'
                                : 'Ningun proveedor coincide con la busqueda',
                          ),
                        )
                      : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _visibles.length,
              itemBuilder: (context, index) {
                final item = _visibles[index];
                final activo = item['activo'] as bool? ?? true;
                return DataCard(
                  title: item['nombre'] as String,
                  rows: [
                    DataCardRow.text('Código', item['codigo'] as String? ?? ''),
                    DataCardRow.text('RUC', item['ruc'] as String? ?? ''),
                    DataCardRow.text(
                      'Contacto',
                      item['contacto_nombre'] as String? ?? '',
                    ),
                    DataCardRow.text(
                      'Teléfono',
                      item['telefono'] as String? ?? '',
                    ),
                    DataCardRow.text('Email', item['email'] as String? ?? ''),
                    DataCardRow(
                      label: 'Estado',
                      value: AppBadge(
                        activo ? 'Activo' : 'Inactivo',
                        type: activo
                            ? AppBadgeType.success
                            : AppBadgeType.danger,
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

class _ProveedorFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _ProveedorFormSheet({this.initial});

  @override
  State<_ProveedorFormSheet> createState() => _ProveedorFormSheetState();
}

class _ProveedorFormSheetState extends State<_ProveedorFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _nombre;
  late final TextEditingController _ruc;
  late final TextEditingController _direccion;
  late final TextEditingController _telefono;
  late final TextEditingController _email;
  late final TextEditingController _contacto;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _codigo = TextEditingController(text: widget.initial?['codigo'] ?? '');
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _ruc = TextEditingController(text: widget.initial?['ruc'] ?? '');
    _direccion = TextEditingController(
      text: widget.initial?['direccion'] ?? '',
    );
    _telefono = TextEditingController(text: widget.initial?['telefono'] ?? '');
    _email = TextEditingController(text: widget.initial?['email'] ?? '');
    _contacto = TextEditingController(
      text: widget.initial?['contacto_nombre'] ?? '',
    );
    _activo = widget.initial?['activo'] as bool? ?? true;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _ruc.dispose();
    _direccion.dispose();
    _telefono.dispose();
    _email.dispose();
    _contacto.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'codigo': _codigo.text.trim(),
      'nombre': _nombre.text.trim(),
      'ruc': _ruc.text.trim(),
      'direccion': _direccion.text.trim(),
      'telefono': _telefono.text.trim(),
      'email': _email.text.trim(),
      'contacto_nombre': _contacto.text.trim(),
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
            title: 'Datos del Proveedor',
            children: [
              AppTextField(
                controller: _codigo,
                label: 'Código',
                icon: Icons.qr_code,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el código'
                    : null,
              ),
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.business,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppTextField(
                controller: _ruc,
                label: 'RUC',
                icon: Icons.badge_outlined,
              ),
              AppTextField(
                controller: _direccion,
                label: 'Dirección',
                icon: Icons.location_on_outlined,
              ),
              AppTextField(
                controller: _telefono,
                label: 'Teléfono',
                icon: Icons.phone_outlined,
              ),
              AppTextField(
                controller: _email,
                label: 'Email',
                icon: Icons.email_outlined,
              ),
              AppTextField(
                controller: _contacto,
                label: 'Contacto',
                icon: Icons.person_outline,
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
