import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_area.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';

/// Gestión de Roles: listado en cards, crear/editar en modal.
class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final List<Map<String, dynamic>> _roles = [
    {'nombre': 'super-admin', 'descripcion': 'Acceso total al sistema'},
    {'nombre': 'admin', 'descripcion': 'Gestión de la empresa'},
    {'nombre': 'user', 'descripcion': 'Acceso básico'},
  ];

  Future<void> _openForm({Map<String, dynamic>? rol, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: rol == null ? 'Nuevo rol' : 'Editar rol',
      child: _RolFormSheet(initial: rol),
    );
    if (result == null) return;

    setState(() {
      if (index != null) {
        _roles[index] = result;
      } else {
        _roles.add(result);
      }
    });
    if (!mounted) return;
    showAppSnackbar(
      context,
      rol == null ? 'Rol creado' : 'Rol actualizado',
      type: AppSnackbarType.success,
    );
  }

  Future<void> _delete(int index) async {
    final rol = _roles[index];
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar rol',
      message: '¿Eliminar el rol "${rol['nombre']}"?',
    );
    if (!confirmado) return;

    setState(() => _roles.removeAt(index));
    if (!mounted) return;
    showAppSnackbar(context, 'Rol eliminado', type: AppSnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Roles',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _roles.length,
        itemBuilder: (context, index) {
          final rol = _roles[index];
          return DataCard(
            title: rol['nombre'] as String,
            rows: [
              DataCardRow.text('Nombre', rol['nombre'] as String),
              DataCardRow.text('Descripción', rol['descripcion'] as String),
            ],
            actions: [
              DataCardAction(
                icon: Icons.edit_outlined,
                color: AppColors.primary,
                tooltip: 'Editar',
                onTap: () => _openForm(rol: rol, index: index),
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

class _RolFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const _RolFormSheet({this.initial});

  @override
  State<_RolFormSheet> createState() => _RolFormSheetState();
}

class _RolFormSheetState extends State<_RolFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _descripcion = TextEditingController(
      text: widget.initial?['descripcion'] ?? '',
    );
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
            title: 'Datos del rol',
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.shield_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppTextArea(controller: _descripcion, label: 'Descripción'),
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
