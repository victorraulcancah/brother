import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle.dart';
import '../widgets/data_card.dart';

/// Gestión de Empresa: listado en cards, crear/editar en modal.
class EmpresaScreen extends StatefulWidget {
  const EmpresaScreen({super.key});

  @override
  State<EmpresaScreen> createState() => _EmpresaScreenState();
}

class _EmpresaScreenState extends State<EmpresaScreen> {
  final List<Map<String, dynamic>> _empresas = [
    {
      'ruc': '20123456789',
      'razon_social': 'Brava Corp S.A.C.',
      'nombre_comercial': 'BRAVA',
      'direccion': 'Av. Principal 123',
      'telefono': '999888777',
      'email': 'contacto@brava.com',
      'activa': true,
    },
  ];

  Future<void> _openForm({Map<String, dynamic>? empresa, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: empresa == null ? 'Nueva empresa' : 'Editar empresa',
      child: _EmpresaFormSheet(initial: empresa),
    );
    if (result == null) return;

    setState(() {
      if (index != null) {
        _empresas[index] = result;
      } else {
        _empresas.add(result);
      }
    });
    if (!mounted) return;
    showAppSnackbar(
      context,
      empresa == null ? 'Empresa creada' : 'Empresa actualizada',
      type: AppSnackbarType.success,
    );
  }

  Future<void> _delete(int index) async {
    final empresa = _empresas[index];
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar empresa',
      message: '¿Eliminar "${empresa['nombre_comercial']}"?',
    );
    if (!confirmado) return;

    setState(() => _empresas.removeAt(index));
    if (!mounted) return;
    showAppSnackbar(context, 'Empresa eliminada', type: AppSnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Empresa',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _empresas.length,
        itemBuilder: (context, index) {
          final empresa = _empresas[index];
          final activa = empresa['activa'] as bool;
          return DataCard(
            title: empresa['nombre_comercial'] as String,
            rows: [
              DataCardRow.text('RUC', empresa['ruc'] as String),
              DataCardRow.text(
                'Razón social',
                empresa['razon_social'] as String,
              ),
              DataCardRow.text('Teléfono', empresa['telefono'] as String),
              DataCardRow(
                label: 'Estado',
                value: AppBadge(
                  activa ? 'Activa' : 'Inactiva',
                  type: activa ? AppBadgeType.success : AppBadgeType.danger,
                ),
              ),
            ],
            actions: [
              DataCardAction(
                icon: Icons.edit_outlined,
                color: AppColors.primary,
                tooltip: 'Editar',
                onTap: () => _openForm(empresa: empresa, index: index),
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
  late final TextEditingController _ruc;
  late final TextEditingController _razonSocial;
  late final TextEditingController _nombreComercial;
  late final TextEditingController _direccion;
  late final TextEditingController _telefono;
  late final TextEditingController _email;
  bool _activa = true;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _ruc = TextEditingController(text: i?['ruc'] ?? '');
    _razonSocial = TextEditingController(text: i?['razon_social'] ?? '');
    _nombreComercial = TextEditingController(
      text: i?['nombre_comercial'] ?? '',
    );
    _direccion = TextEditingController(text: i?['direccion'] ?? '');
    _telefono = TextEditingController(text: i?['telefono'] ?? '');
    _email = TextEditingController(text: i?['email'] ?? '');
    _activa = i?['activa'] as bool? ?? true;
  }

  @override
  void dispose() {
    _ruc.dispose();
    _razonSocial.dispose();
    _nombreComercial.dispose();
    _direccion.dispose();
    _telefono.dispose();
    _email.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'ruc': _ruc.text.trim(),
      'razon_social': _razonSocial.text.trim(),
      'nombre_comercial': _nombreComercial.text.trim(),
      'direccion': _direccion.text.trim(),
      'telefono': _telefono.text.trim(),
      'email': _email.text.trim(),
      'activa': _activa,
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
            title: 'Datos de la empresa',
            children: [
              AppTextField(
                controller: _ruc,
                label: 'RUC',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingrese el RUC';
                  if (v.trim().length != 11) {
                    return 'El RUC debe tener 11 dígitos';
                  }
                  return null;
                },
              ),
              AppTextField(
                controller: _razonSocial,
                label: 'Razón social',
                icon: Icons.apartment_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese la razón social'
                    : null,
              ),
              AppTextField(
                controller: _nombreComercial,
                label: 'Nombre comercial',
                icon: Icons.store_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre comercial'
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppFormSection(
            title: 'Contacto',
            children: [
              AppTextField(
                controller: _direccion,
                label: 'Dirección',
                icon: Icons.location_on_outlined,
              ),
              AppTextField(
                controller: _telefono,
                label: 'Teléfono',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              AppTextField(
                controller: _email,
                label: 'Correo',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              AppToggle(
                label: 'Activa',
                value: _activa,
                onChanged: (v) => setState(() => _activa = v),
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
