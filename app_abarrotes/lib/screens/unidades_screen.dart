import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';

/// Catálogo → Unidades de medida. Listado en cards, crear/editar en modal.
class UnidadesScreen extends StatefulWidget {
  const UnidadesScreen({super.key});

  @override
  State<UnidadesScreen> createState() => _UnidadesScreenState();
}

class _UnidadesScreenState extends State<UnidadesScreen> {
  final List<Map<String, dynamic>> _items = [
    {'nombre': 'Unidad', 'abreviatura': 'UND'},
    {'nombre': 'Kilogramo', 'abreviatura': 'KG'},
    {'nombre': 'Caja', 'abreviatura': 'CJA'},
    {'nombre': 'Litro', 'abreviatura': 'L'},
  ];

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva unidad' : 'Editar unidad',
      child: _UnidadFormSheet(initial: item),
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
      item == null ? 'Unidad creada' : 'Unidad actualizada',
      type: AppSnackbarType.success,
    );
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar unidad',
      message: '¿Eliminar "${item['nombre']}"?',
    );
    if (!confirmado) return;

    setState(() => _items.removeAt(index));
    if (!mounted) return;
    showAppSnackbar(context, 'Unidad eliminada', type: AppSnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Unidades de medida',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return DataCard(
            title: item['nombre'] as String,
            rows: [
              DataCardRow.text('Nombre', item['nombre'] as String),
              DataCardRow.text('Abreviatura', item['abreviatura'] as String),
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

class _UnidadFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const _UnidadFormSheet({this.initial});

  @override
  State<_UnidadFormSheet> createState() => _UnidadFormSheetState();
}

class _UnidadFormSheetState extends State<_UnidadFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _abreviatura;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _abreviatura = TextEditingController(
      text: widget.initial?['abreviatura'] ?? '',
    );
  }

  @override
  void dispose() {
    _nombre.dispose();
    _abreviatura.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nombre': _nombre.text.trim(),
      'abreviatura': _abreviatura.text.trim().toUpperCase(),
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
            title: 'Datos de la unidad',
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.straighten,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppTextField(
                controller: _abreviatura,
                label: 'Abreviatura',
                icon: Icons.short_text,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese la abreviatura'
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
