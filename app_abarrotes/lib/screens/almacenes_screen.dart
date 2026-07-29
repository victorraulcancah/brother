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
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle.dart';
import '../widgets/data_card.dart';

/// Inventario → Almacenes. Listado en cards, crear/editar en modal.
class AlmacenesScreen extends StatefulWidget {
  const AlmacenesScreen({super.key});

  @override
  State<AlmacenesScreen> createState() => _AlmacenesScreenState();
}

class _AlmacenesScreenState extends State<AlmacenesScreen> {
  final List<Map<String, dynamic>> _items = [
    {
      'codigo': 'ALM01',
      'nombre': 'Almacén Central',
      'tipo': 'principal',
      'direccion': 'Av. Principal 123',
      'activo': true,
    },
    {
      'codigo': 'ALM02',
      'nombre': 'Tienda',
      'tipo': 'tienda',
      'direccion': 'Jr. Comercio 456',
      'activo': true,
    },
  ];

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo almacén' : 'Editar almacén',
      child: _AlmacenFormSheet(initial: item),
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
      item == null ? 'Almacén creado' : 'Almacén actualizado',
      type: AppSnackbarType.success,
    );
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar almacén',
      message: '¿Eliminar "${item['nombre']}"?',
    );
    if (!confirmado) return;

    setState(() => _items.removeAt(index));
    if (!mounted) return;
    showAppSnackbar(context, 'Almacén eliminado', type: AppSnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Almacenes',
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
              DataCardRow.text('Código', item['codigo'] as String),
              DataCardRow.text('Tipo', item['tipo'] as String),
              DataCardRow.text('Dirección', item['direccion'] as String),
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

class _AlmacenFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const _AlmacenFormSheet({this.initial});

  @override
  State<_AlmacenFormSheet> createState() => _AlmacenFormSheetState();
}

class _AlmacenFormSheetState extends State<_AlmacenFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _nombre;
  late final TextEditingController _direccion;
  String? _tipo;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _codigo = TextEditingController(text: i?['codigo'] ?? '');
    _nombre = TextEditingController(text: i?['nombre'] ?? '');
    _direccion = TextEditingController(text: i?['direccion'] ?? '');
    _tipo = i?['tipo'] as String? ?? 'principal';
    _activo = i?['activo'] as bool? ?? true;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _direccion.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'codigo': _codigo.text.trim(),
      'nombre': _nombre.text.trim(),
      'tipo': _tipo,
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
            title: 'Datos del almacén',
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
                label: 'Nombre',
                icon: Icons.warehouse_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppSelect<String>(
                label: 'Tipo',
                icon: Icons.category_outlined,
                value: _tipo,
                options: const [
                  AppSelectOption('principal', 'Principal'),
                  AppSelectOption('secundario', 'Secundario'),
                  AppSelectOption('tienda', 'Tienda'),
                ],
                onChanged: (v) => setState(() => _tipo = v),
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
