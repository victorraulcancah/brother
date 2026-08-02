import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';

class EmpresaScreen extends StatefulWidget {
  const EmpresaScreen({super.key});

  @override
  State<EmpresaScreen> createState() => _EmpresaScreenState();
}

class _EmpresaScreenState extends State<EmpresaScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.empresas);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva empresa' : 'Editar empresa',
      child: _EmpresaFormSheet(initial: item),
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
          item == null ? 'Empresa creada' : 'Empresa actualizada',
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
      title: 'Eliminar empresa',
      message:
          '¿Eliminar "${item['nombre_comercial'] ?? item['razon_social']}"?',
    );
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Empresa eliminada',
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
      title: 'Empresa',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay empresas'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return DataCard(
                  title:
                      item['nombre_comercial'] as String? ??
                      item['razon_social'] as String? ??
                      '',
                  rows: [
                    DataCardRow.text('RUC', item['ruc'] as String? ?? ''),
                    DataCardRow.text(
                      'Razón Social',
                      item['razon_social'] as String? ?? '',
                    ),
                    DataCardRow.text(
                      'Dirección',
                      item['direccion'] as String? ?? '',
                    ),
                    DataCardRow.text(
                      'Ubicación',
                      [item['distrito'], item['provincia'], item['departamento']]
                          .where((e) => e != null && '$e'.trim().isNotEmpty)
                          .join(', '),
                    ),
                    DataCardRow.text(
                      'Teléfono',
                      item['telefono'] as String? ?? '',
                    ),
                    DataCardRow.text('Email', item['email'] as String? ?? ''),
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

class _EmpresaFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _EmpresaFormSheet({this.initial});

  @override
  State<_EmpresaFormSheet> createState() => _EmpresaFormSheetState();
}

class _EmpresaFormSheetState extends State<_EmpresaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _razonSocial;
  late final TextEditingController _nombreComercial;
  late final TextEditingController _ruc;
  late final TextEditingController _direccion;
  late final TextEditingController _departamento;
  late final TextEditingController _provincia;
  late final TextEditingController _distrito;
  late final TextEditingController _ciudad;
  late final TextEditingController _telefono;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    _razonSocial = TextEditingController(
      text: widget.initial?['razon_social'] ?? '',
    );
    _nombreComercial = TextEditingController(
      text: widget.initial?['nombre_comercial'] ?? '',
    );
    _ruc = TextEditingController(text: widget.initial?['ruc'] ?? '');
    _direccion = TextEditingController(
      text: widget.initial?['direccion'] ?? '',
    );
    _departamento = TextEditingController(text: widget.initial?['departamento'] ?? '');
    _provincia = TextEditingController(text: widget.initial?['provincia'] ?? '');
    _distrito = TextEditingController(text: widget.initial?['distrito'] ?? '');
    _ciudad = TextEditingController(text: widget.initial?['ciudad'] ?? '');
    _telefono = TextEditingController(text: widget.initial?['telefono'] ?? '');
    _email = TextEditingController(text: widget.initial?['email'] ?? '');
  }

  @override
  void dispose() {
    _razonSocial.dispose();
    _nombreComercial.dispose();
    _ruc.dispose();
    _direccion.dispose();
    _departamento.dispose();
    _provincia.dispose();
    _distrito.dispose();
    _ciudad.dispose();
    _telefono.dispose();
    _email.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'razon_social': _razonSocial.text.trim(),
      'nombre_comercial': _nombreComercial.text.trim(),
      'ruc': _ruc.text.trim(),
      'direccion': _direccion.text.trim(),
      'departamento': _departamento.text.trim(),
      'provincia': _provincia.text.trim(),
      'distrito': _distrito.text.trim(),
      'ciudad': _ciudad.text.trim(),
      'telefono': _telefono.text.trim(),
      'email': _email.text.trim(),
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
            title: 'Datos de la Empresa',
            children: [
              AppTextField(
                controller: _razonSocial,
                label: 'Razón Social',
                icon: Icons.business,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese la razón social'
                    : null,
              ),
              AppTextField(
                controller: _nombreComercial,
                label: 'Nombre Comercial',
                icon: Icons.business,
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
                controller: _departamento,
                label: 'Departamento',
                icon: Icons.map_outlined,
              ),
              AppTextField(
                controller: _provincia,
                label: 'Provincia',
                icon: Icons.map_outlined,
              ),
              AppTextField(
                controller: _distrito,
                label: 'Distrito',
                icon: Icons.map_outlined,
              ),
              AppTextField(
                controller: _ciudad,
                label: 'Ciudad',
                icon: Icons.location_city_outlined,
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
