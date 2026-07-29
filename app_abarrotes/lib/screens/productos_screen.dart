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

/// Catálogo → Productos. Listado en cards, crear/editar en modal.
class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final List<Map<String, dynamic>> _productos = [
    {
      'nombre': 'Leche evaporada 400g',
      'codigo': 'P001',
      'categoria': 'Abarrotes',
      'marca': 'Gloria',
      'unidad': 'UND',
      'precio': '4.20',
      'stock': '120',
      'afecto_igv': true,
      'activo': true,
    },
    {
      'nombre': 'Gaseosa 1.5L',
      'codigo': 'P002',
      'categoria': 'Bebidas',
      'marca': 'Sin marca',
      'unidad': 'UND',
      'precio': '6.50',
      'stock': '48',
      'afecto_igv': true,
      'activo': true,
    },
  ];

  Future<void> _openForm({Map<String, dynamic>? producto, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: producto == null ? 'Nuevo producto' : 'Editar producto',
      child: _ProductoFormSheet(initial: producto),
    );
    if (result == null) return;

    setState(() {
      if (index != null) {
        _productos[index] = result;
      } else {
        _productos.add(result);
      }
    });
    if (!mounted) return;
    showAppSnackbar(
      context,
      producto == null ? 'Producto creado' : 'Producto actualizado',
      type: AppSnackbarType.success,
    );
  }

  Future<void> _delete(int index) async {
    final producto = _productos[index];
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar producto',
      message: '¿Eliminar "${producto['nombre']}"?',
    );
    if (!confirmado) return;

    setState(() => _productos.removeAt(index));
    if (!mounted) return;
    showAppSnackbar(context, 'Producto eliminado', type: AppSnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Productos',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _productos.length,
        itemBuilder: (context, index) {
          final producto = _productos[index];
          final activo = producto['activo'] as bool;
          return DataCard(
            title: producto['nombre'] as String,
            rows: [
              DataCardRow.text('Código', producto['codigo'] as String),
              DataCardRow.text('Categoría', producto['categoria'] as String),
              DataCardRow.text('Precio', 'S/ ${producto['precio']}'),
              DataCardRow.text('Stock', producto['stock'] as String),
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
                onTap: () => _openForm(producto: producto, index: index),
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

class _ProductoFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const _ProductoFormSheet({this.initial});

  @override
  State<_ProductoFormSheet> createState() => _ProductoFormSheetState();
}

class _ProductoFormSheetState extends State<_ProductoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _codigo;
  late final TextEditingController _precio;
  late final TextEditingController _stock;
  String? _categoria;
  String? _marca;
  String? _unidad;
  bool _afectoIgv = true;
  bool _activo = true;

  static const _categorias = ['Abarrotes', 'Bebidas', 'Limpieza'];
  static const _marcas = ['Gloria', 'Nestlé', 'Sin marca'];
  static const _unidades = ['UND', 'KG', 'CJA', 'L'];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _nombre = TextEditingController(text: i?['nombre'] ?? '');
    _codigo = TextEditingController(text: i?['codigo'] ?? '');
    _precio = TextEditingController(text: i?['precio'] ?? '');
    _stock = TextEditingController(text: i?['stock'] ?? '');
    _categoria = i?['categoria'] as String?;
    _marca = i?['marca'] as String?;
    _unidad = i?['unidad'] as String?;
    _afectoIgv = i?['afecto_igv'] as bool? ?? true;
    _activo = i?['activo'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _codigo.dispose();
    _precio.dispose();
    _stock.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nombre': _nombre.text.trim(),
      'codigo': _codigo.text.trim(),
      'categoria': _categoria,
      'marca': _marca,
      'unidad': _unidad,
      'precio': _precio.text.trim(),
      'stock': _stock.text.trim(),
      'afecto_igv': _afectoIgv,
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
            title: 'Datos del producto',
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.inventory_2_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppTextField(
                controller: _codigo,
                label: 'Código / SKU',
                icon: Icons.qr_code_2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el código'
                    : null,
              ),
              AppSelect<String>(
                label: 'Categoría',
                icon: Icons.category_outlined,
                value: _categoria,
                options: [for (final c in _categorias) AppSelectOption(c, c)],
                onChanged: (v) => setState(() => _categoria = v),
                validator: (v) => v == null ? 'Seleccione una categoría' : null,
              ),
              AppSelect<String>(
                label: 'Marca',
                icon: Icons.sell_outlined,
                value: _marca,
                options: [for (final m in _marcas) AppSelectOption(m, m)],
                onChanged: (v) => setState(() => _marca = v),
                validator: (v) => v == null ? 'Seleccione una marca' : null,
              ),
              AppSelect<String>(
                label: 'Unidad de medida',
                icon: Icons.straighten,
                value: _unidad,
                options: [for (final u in _unidades) AppSelectOption(u, u)],
                onChanged: (v) => setState(() => _unidad = v),
                validator: (v) => v == null ? 'Seleccione una unidad' : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppFormSection(
            title: 'Precio y stock',
            children: [
              AppTextField(
                controller: _precio,
                label: 'Precio (S/)',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el precio'
                    : null,
              ),
              AppTextField(
                controller: _stock,
                label: 'Stock',
                icon: Icons.inventory_outlined,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingrese el stock' : null,
              ),
              AppToggle(
                label: 'Afecto a IGV',
                value: _afectoIgv,
                onChanged: (v) => setState(() => _afectoIgv = v),
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
