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

class SubCategoriasScreen extends StatefulWidget {
  const SubCategoriasScreen({super.key});

  @override
  State<SubCategoriasScreen> createState() => _SubCategoriasScreenState();
}

class _SubCategoriasScreenState extends State<SubCategoriasScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _categorias = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.subCategorias);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
      _categorias = await CrudService(_api, ApiEndpoints.categorias).getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva sub-categoría' : 'Editar sub-categoría',
      child: _SubCategoriaFormSheet(initial: item, categorias: _categorias),
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
          item == null ? 'Sub-categoría creada' : 'Sub-categoría actualizada',
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
      title: 'Eliminar sub-categoría',
      message: '¿Eliminar "${item['nombre']}"?',
    );
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Sub-categoría eliminada',
          type: AppSnackbarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  String _categoriaNombre(Map<String, dynamic> item) {
    if (item['categoria'] is Map) {
      return (item['categoria'] as Map)['nombre']?.toString() ?? '';
    }
    final id = item['categoria_id'];
    final match = _categorias.firstWhere(
      (c) => c['id'] == id,
      orElse: () => const {},
    );
    return match['nombre']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Sub-categorías',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay sub-categorías'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final activo = item['activo'] == true;
                return DataCard(
                  title: item['nombre']?.toString() ?? '',
                  rows: [
                    DataCardRow.text('Categoría', _categoriaNombre(item)),
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

class _SubCategoriaFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> categorias;

  const _SubCategoriaFormSheet({this.initial, required this.categorias});

  @override
  State<_SubCategoriaFormSheet> createState() => _SubCategoriaFormSheetState();
}

class _SubCategoriaFormSheetState extends State<_SubCategoriaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  int? _categoriaId;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _categoriaId = widget.initial?['categoria_id'] as int?;
    if (_categoriaId == null && widget.initial?['categoria'] is Map) {
      _categoriaId = (widget.initial!['categoria'] as Map)['id'] as int?;
    }
    _activo = widget.initial?['activo'] == true || widget.initial == null;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'categoria_id': _categoriaId,
      'nombre': _nombre.text.trim(),
      'activo': _activo,
    });
  }

  @override
  Widget build(BuildContext context) {
    final opciones = widget.categorias
        .map(
          (c) => AppSelectOption<int>(
            c['id'] as int,
            c['nombre']?.toString() ?? '',
          ),
        )
        .toList();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(
            title: 'Datos de la sub-categoría',
            children: [
              AppSelect<int>(
                label: 'Categoría',
                icon: Icons.category_outlined,
                value: _categoriaId,
                options: opciones,
                onChanged: (v) => setState(() => _categoriaId = v),
                validator: (v) => v == null ? 'Seleccione una categoría' : null,
              ),
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.label_outline,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
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
