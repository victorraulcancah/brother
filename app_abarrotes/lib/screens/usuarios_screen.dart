import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_tabs.dart';
import '../widgets/app_text_area.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle.dart';
import '../widgets/data_card.dart';

/// Listado de usuarios tipo "tabla en cards". Demo de todo el kit:
/// tabs, modal (bottom sheet), confirmación y avisos.
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final List<Map<String, dynamic>> _usuarios = [
    {
      'nombre': 'Admin Acme',
      'correo': 'admin@acme.com',
      'rol': 'admin',
      'activo': true,
      'notas': '',
    },
    {
      'nombre': 'Usuario Prueba Angular',
      'correo': 'prueba.angular@acme.com',
      'rol': 'user',
      'activo': true,
      'notas': '',
    },
    {
      'nombre': 'Admin-victor',
      'correo': 'vcanchari38@gmail.com',
      'rol': 'super-admin',
      'activo': true,
      'notas': '',
    },
  ];

  Future<void> _openForm({Map<String, dynamic>? user, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: user == null ? 'Nuevo usuario' : 'Editar usuario',
      child: _UserFormSheet(initial: user),
    );
    if (result == null) return;

    setState(() {
      if (index != null) {
        _usuarios[index] = result;
      } else {
        _usuarios.add(result);
      }
    });
    if (!mounted) return;
    showAppSnackbar(
      context,
      user == null ? 'Usuario creado' : 'Usuario actualizado',
      type: AppSnackbarType.success,
    );
  }

  Future<void> _delete(int index) async {
    final usuario = _usuarios[index];
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar usuario',
      message:
          '¿Eliminar a ${usuario['nombre']}? Esta acción no se puede deshacer.',
    );
    if (!confirmado) return;

    setState(() => _usuarios.removeAt(index));
    if (!mounted) return;
    showAppSnackbar(context, 'Usuario eliminado', type: AppSnackbarType.error);
  }

  Widget _list(bool? activoFilter) {
    final indices = [
      for (var i = 0; i < _usuarios.length; i++)
        if (activoFilter == null || _usuarios[i]['activo'] == activoFilter) i,
    ];

    if (indices.isEmpty) {
      return const Center(
        child: Text(
          'No hay usuarios en esta vista',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: indices.length,
      itemBuilder: (context, position) {
        final index = indices[position];
        final usuario = _usuarios[index];
        final activo = usuario['activo'] as bool;

        return DataCard(
          title: usuario['nombre'] as String,
          rows: [
            DataCardRow.text('Nombre completo', usuario['nombre'] as String),
            DataCardRow.text('Correo', usuario['correo'] as String),
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
              onTap: () => _openForm(user: usuario, index: index),
            ),
            DataCardAction(
              icon: Icons.key_outlined,
              color: AppColors.info,
              tooltip: 'Contraseña',
              onTap: () => showAppSnackbar(
                context,
                'Restablecer contraseña (pendiente)',
                type: AppSnackbarType.info,
              ),
            ),
            DataCardAction(
              icon: Icons.person_remove_outlined,
              color: AppColors.danger,
              tooltip: 'Eliminar',
              onTap: () => _delete(index),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Usuarios',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: AppTabs(
        tabs: [
          AppTab(
            icon: Icons.groups_outlined,
            label: 'Todos',
            content: _list(null),
          ),
          AppTab(
            icon: Icons.check_circle_outline,
            label: 'Activos',
            content: _list(true),
          ),
          AppTab(icon: Icons.block, label: 'Inactivos', content: _list(false)),
        ],
      ),
    );
  }
}

/// Formulario de usuario que se muestra dentro del modal.
/// Al guardar, devuelve el mapa con los datos vía `Navigator.pop`.
class _UserFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const _UserFormSheet({this.initial});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _correo;
  late final TextEditingController _notas;
  String? _rol;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nombre = TextEditingController(text: initial?['nombre'] ?? '');
    _correo = TextEditingController(text: initial?['correo'] ?? '');
    _notas = TextEditingController(text: initial?['notas'] ?? '');
    _rol = initial?['rol'] as String?;
    _activo = initial?['activo'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _notas.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nombre': _nombre.text.trim(),
      'correo': _correo.text.trim(),
      'rol': _rol,
      'activo': _activo,
      'notas': _notas.text.trim(),
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
            title: 'Datos del usuario',
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre completo',
                icon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppTextField(
                controller: _correo,
                label: 'Correo',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingrese el correo';
                  if (!v.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              AppSelect<String>(
                label: 'Rol',
                icon: Icons.badge_outlined,
                value: _rol,
                options: const [
                  AppSelectOption('super-admin', 'Super Admin'),
                  AppSelectOption('admin', 'Administrador'),
                  AppSelectOption('user', 'Usuario'),
                ],
                onChanged: (v) => setState(() => _rol = v),
                validator: (v) => v == null ? 'Seleccione un rol' : null,
              ),
              AppToggle(
                label: 'Activo',
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
              AppTextArea(controller: _notas, label: 'Notas (opcional)'),
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
