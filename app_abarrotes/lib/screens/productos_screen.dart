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

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _marcas = [];
  List<Map<String, dynamic>> _unidades = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.productos);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
      _categorias = await CrudService(_api, ApiEndpoints.categorias).getAll();
      _marcas = await CrudService(_api, ApiEndpoints.marcas).getAll();
      _unidades = await CrudService(_api, ApiEndpoints.unidades).getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context, title: item == null ? 'Nuevo producto' : 'Editar producto',
      child: _ProductoFormSheet(initial: item, categorias: _categorias, marcas: _marcas, unidades: _unidades),
    );
    if (result == null) return;
    try {
      if (index != null) { await _crud.update(item!['id'], result); }
      else { await _crud.create(result); }
      await _load();
      if (mounted) showAppSnackbar(context, item == null ? 'Producto creado' : 'Producto actualizado', type: AppSnackbarType.success);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(context, title: 'Eliminar producto', message: '¿Eliminar "${item['nombre']}"?');
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Producto eliminado', type: AppSnackbarType.error);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Productos',
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty ? const Center(child: Text('No hay productos'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final activo = item['activo'] as bool? ?? true;
                return DataCard(
                  title: '${item['nombre'] ?? ''} (${item['codigo'] ?? ''})',
                  rows: [
                    DataCardRow.text('Categoría', item['categoria_nombre'] as String? ?? ''),
                    DataCardRow.text('Marca', item['marca_nombre'] as String? ?? ''),
                    DataCardRow.text('Unidad', item['unidad_nombre'] as String? ?? ''),
                    DataCardRow.text('Precio Compra', item['precio_compra']?.toString() ?? ''),
                    DataCardRow.text('Precio Venta', item['precio_venta']?.toString() ?? ''),
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

class _ProductoFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> categorias;
  final List<Map<String, dynamic>> marcas;
  final List<Map<String, dynamic>> unidades;
  const _ProductoFormSheet({this.initial, required this.categorias, required this.marcas, required this.unidades});

  @override
  State<_ProductoFormSheet> createState() => _ProductoFormSheetState();
}

class _ProductoFormSheetState extends State<_ProductoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _codigo;
  late final TextEditingController _precioCompra;
  late final TextEditingController _precioVenta;
  int? _categoriaId;
  int? _marcaId;
  int? _unidadId;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _codigo = TextEditingController(text: widget.initial?['codigo'] ?? '');
    _precioCompra = TextEditingController(text: widget.initial?['precio_compra']?.toString() ?? '');
    _precioVenta = TextEditingController(text: widget.initial?['precio_venta']?.toString() ?? '');
    _categoriaId = widget.initial?['categoria_id'] as int?;
    _marcaId = widget.initial?['marca_id'] as int?;
    _unidadId = widget.initial?['unidad_id'] as int?;
    _activo = widget.initial?['activo'] as bool? ?? true;
  }

  @override
  void dispose() { _nombre.dispose(); _codigo.dispose(); _precioCompra.dispose(); _precioVenta.dispose(); super.dispose(); }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nombre': _nombre.text.trim(),
      'codigo': _codigo.text.trim(),
      'categoria_id': _categoriaId,
      'marca_id': _marcaId,
      'unidad_id': _unidadId,
      'precio_compra': double.tryParse(_precioCompra.text.trim()) ?? 0,
      'precio_venta': double.tryParse(_precioVenta.text.trim()) ?? 0,
      'activo': _activo,
    });
  }

  @override
  Widget build(BuildContext context) {
    final categorias = widget.categorias.map((c) => AppSelectOption<int>(c['id'] as int, c['nombre'] as String)).toList();
    final marcas = widget.marcas.map((m) => AppSelectOption<int>(m['id'] as int, m['nombre'] as String)).toList();
    final unidades = widget.unidades.map((u) => AppSelectOption<int>(u['id'] as int, u['nombre'] as String)).toList();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(title: 'Datos del Producto', children: [
            AppTextField(controller: _nombre, label: 'Nombre', icon: Icons.inventory_2_outlined, validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null),
            AppTextField(controller: _codigo, label: 'Código', icon: Icons.qr_code, validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el código' : null),
            AppSelect<int>(label: 'Categoría', value: _categoriaId, options: categorias, onChanged: (v) => setState(() => _categoriaId = v)),
            AppSelect<int>(label: 'Marca', value: _marcaId, options: marcas, onChanged: (v) => setState(() => _marcaId = v)),
            AppSelect<int>(label: 'Unidad', value: _unidadId, options: unidades, onChanged: (v) => setState(() => _unidadId = v)),
            AppTextField(controller: _precioCompra, label: 'Precio compra', icon: Icons.attach_money, keyboardType: TextInputType.number),
            AppTextField(controller: _precioVenta, label: 'Precio venta', icon: Icons.attach_money, keyboardType: TextInputType.number),
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
