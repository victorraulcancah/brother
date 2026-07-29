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

/// Compras → Proveedores. Listado en cards, crear/editar en modal.
class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final List<Map<String, dynamic>> _items = [
    {
      'codigo': 'PRV001',
      'nombre': 'Distribuidora Lima S.A.C.',
      'ruc': '20501234567',
      'contacto_nombre': 'Juan Pérez',
      'telefono': '987654321',
      'email': 'ventas@dislima.com',
      'direccion': 'Av. Argentina 456',
      'activo': true,
    },
    {
      'codigo': 'PRV002',
      'nombre': 'Alicorp S.A.A.',
      'ruc': '20100055237',
      'contacto_nombre': 'María Gómez',
      'telefono': '956123789',
      'email': 'contacto@alicorp.com',
      'direccion': 'Av. Argentina 4793',
      'activo': true,
    },
  ];

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo proveedor' : 'Editar proveedor',
      child: _ProveedorFormSheet(initial: item),
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
      item == null ? 'Proveedor creado' : 'Proveedor actualizado',
      type: AppSnackbarType.success,
    );
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar proveedor',
      message: '¿Eliminar "${item['nombre']}"?',
    );
    if (!confirmado) return;

    setState(() => _items.removeAt(index));
    if (!mounted) return;
    showAppSnackbar(
      context,
      'Proveedor eliminado',
      type: AppSnackbarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Proveedores',
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
              DataCardRow.text('RUC', item['ruc'] as String),
              DataCardRow.text('Contacto', item['contacto_nombre'] as String),
              DataCardRow.text('Teléfono', item['telefono'] as String),
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
  late final TextEditingController _contacto;
  late final TextEditingController _telefono;
  late final TextEditingController _email;
  late final TextEditingController _direccion;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _codigo = TextEditingController(text: i?['codigo'] ?? '');
    _nombre = TextEditingController(text: i?['nombre'] ?? '');
    _ruc = TextEditingController(text: i?['ruc'] ?? '');
    _contacto = TextEditingController(text: i?['contacto_nombre'] ?? '');
    _telefono = TextEditingController(text: i?['telefono'] ?? '');
    _email = TextEditingController(text: i?['email'] ?? '');
    _direccion = TextEditingController(text: i?['direccion'] ?? '');
    _activo = i?['activo'] as bool? ?? true;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _ruc.dispose();
    _contacto.dispose();
    _telefono.dispose();
    _email.dispose();
    _direccion.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'codigo': _codigo.text.trim(),
      'nombre': _nombre.text.trim(),
      'ruc': _ruc.text.trim(),
      'contacto_nombre': _contacto.text.trim(),
      'telefono': _telefono.text.trim(),
      'email': _email.text.trim(),
      'direccion': _direccion.text.trim(),
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
            title: 'Datos del proveedor',
            children: [
              AppTextField(
                controller: _codigo,
                label: 'Código',
                icon: Icons.tag,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el código'
                    : null,
              ),
              AppTextField(
                controller: _nombre,
                label: 'Nombre / Razón social',
                icon: Icons.local_shipping_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppTextField(
                controller: _ruc,
                label: 'RUC',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppFormSection(
            title: 'Contacto',
            children: [
              AppTextField(
                controller: _contacto,
                label: 'Persona de contacto',
                icon: Icons.person_outline,
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
              AppTextField(
                controller: _direccion,
                label: 'Dirección',
                icon: Icons.location_on_outlined,
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
