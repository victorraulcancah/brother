import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_area.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle.dart';
import '../widgets/data_card.dart';

/// Catálogo → Categorías. Listado en cards, crear/editar en modal.
class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final List<Map<String, dynamic>> _items = [
    {
      'nombre': 'Abarrotes',
      'descripcion': 'Productos de despensa',
      'activo': true,
    },
    {
      'nombre': 'Bebidas',
      'descripcion': 'Gaseosas, aguas y jugos',
      'activo': true,
    },
    {'nombre': 'Limpieza', 'descripcion': 'Artículos de aseo', 'activo': true},
  ];

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva categoría' : 'Editar categoría',
      child: _CategoriaFormSheet(initial: item),
    );
    if (result == null) return;

    setState(() {
      if (index != null) {
        _items[index] = result;
      } else {
        _items.add(result);
      }
    });
    if (!mounted) return;
    showAppSnackbar(
      context,
      item == null ? 'Categoría creada' : 'Categoría actualizada',
      type: AppSnackbarType.success,
    );
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar categoría',
      message: '¿Eliminar "${item['nombre']}"?',
    );
    if (!confirmado) return;

    setState(() => _items.removeAt(index));
    if (!mounted) return;
    showAppSnackbar(
      context,
      'Categoría eliminada',
      type: AppSnackbarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Categorías',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final activo = item['activo'] as bool;
          return DataCard(
            title: item['nombre'] as String,
            rows: [
              DataCardRow.text('Descripción', item['descripcion'] as String),
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
    );
  }
}

class _CategoriaFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const _CategoriaFormSheet({this.initial});

  @override
  State<_CategoriaFormSheet> createState() => _CategoriaFormSheetState();
}

class _CategoriaFormSheetState extends State<_CategoriaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _descripcion = TextEditingController(
      text: widget.initial?['descripcion'] ?? '',
    );
    _activo = widget.initial?['activo'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nombre': _nombre.text.trim(),
      'descripcion': _descripcion.text.trim(),
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
            title: 'Datos de la categoría',
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.category_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppTextArea(controller: _descripcion, label: 'Descripción'),
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
