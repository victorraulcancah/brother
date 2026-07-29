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

class AlmacenesScreen extends StatefulWidget {
  const AlmacenesScreen({super.key});

  @override
  State<AlmacenesScreen> createState() => _AlmacenesScreenState();
}

class _AlmacenesScreenState extends State<AlmacenesScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.almacenes);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _items = await _crud.getAll(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context, title: item == null ? 'Nuevo almacén' : 'Editar almacén',
      child: _AlmacenFormSheet(initial: item),
    );
    if (result == null) return;
    try {
      if (index != null) { await _crud.update(item!['id'], result); }
      else { await _crud.create(result); }
      await _load();
      if (mounted) showAppSnackbar(context, item == null ? 'Almacén creado' : 'Almacén actualizado', type: AppSnackbarType.success);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(context, title: 'Eliminar almacén', message: '¿Eliminar "${item['nombre']}"?');
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Almacén eliminado', type: AppSnackbarType.error);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Almacenes',
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty ? const Center(child: Text('No hay almacenes'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final activo = item['activo'] as bool? ?? true;
                return DataCard(
                  title: item['nombre'] as String,
                  rows: [
                    DataCardRow.text('Código', item['codigo'] as String? ?? ''),
                    DataCardRow.text('Tipo', item['tipo'] as String? ?? ''),
                    DataCardRow.text('Dirección', item['direccion'] as String? ?? ''),
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

class _AlmacenFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _AlmacenFormSheet({this.initial});

  @override
  State<_AlmacenFormSheet> createState() => _AlmacenFormSheetState();
}

class _AlmacenFormSheetState extends State<_AlmacenFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _codigo;
  late final TextEditingController _direccion;
  String _tipo = 'principal';
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _codigo = TextEditingController(text: widget.initial?['codigo'] ?? '');
    _direccion = TextEditingController(text: widget.initial?['direccion'] ?? '');
    _tipo = widget.initial?['tipo'] as String? ?? 'principal';
    _activo = widget.initial?['activo'] as bool? ?? true;
  }

  @override
  void dispose() { _nombre.dispose(); _codigo.dispose(); _direccion.dispose(); super.dispose(); }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {'nombre': _nombre.text.trim(), 'codigo': _codigo.text.trim(), 'tipo': _tipo, 'direccion': _direccion.text.trim(), 'activo': _activo});
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(title: 'Datos del Almacén', children: [
            AppTextField(controller: _nombre, label: 'Nombre', icon: Icons.warehouse, validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null),
            AppTextField(controller: _codigo, label: 'Código', icon: Icons.qr_code, validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el código' : null),
            AppSelect<String>(label: 'Tipo', value: _tipo, options: const [AppSelectOption('principal', 'Principal'), AppSelectOption('secundario', 'Secundario'), AppSelectOption('tienda', 'Tienda')], onChanged: (v) => setState(() => _tipo = v ?? 'principal')),
            AppTextField(controller: _direccion, label: 'Dirección', icon: Icons.location_on_outlined),
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
