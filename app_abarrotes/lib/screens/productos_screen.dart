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
import '../widgets/app_text_area.dart';
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
  List<Map<String, dynamic>> _subMarcas = [];
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
      _subMarcas = await CrudService(_api, ApiEndpoints.subMarcas).getAll();
      _unidades = await CrudService(_api, ApiEndpoints.unidades).getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo producto' : 'Editar producto',
      child: _ProductoFormSheet(
        initial: item,
        categorias: _categorias,
        marcas: _marcas,
        subMarcas: _subMarcas,
        unidades: _unidades,
      ),
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
          item == null ? 'Producto creado' : 'Producto actualizado',
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
      title: 'Eliminar producto',
      message: '¿Eliminar "${item['nombre']}"?',
    );
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Producto eliminado',
          type: AppSnackbarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  String _nested(Map<String, dynamic> item, String rel) {
    final r = item[rel];
    if (r is Map) return r['nombre']?.toString() ?? '';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Productos',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay productos'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final activo = item['activo'] == true;
                return DataCard(
                  title: item['nombre']?.toString() ?? '',
                  rows: [
                    DataCardRow.text(
                      'Código',
                      item['codigo']?.toString() ?? '',
                    ),
                    DataCardRow.text('Categoría', _nested(item, 'categoria')),
                    DataCardRow.text(
                      'Precio',
                      'S/ ${item['precio_base'] ?? ''}',
                    ),
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

class _ProductoFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> categorias;
  final List<Map<String, dynamic>> marcas;
  final List<Map<String, dynamic>> subMarcas;
  final List<Map<String, dynamic>> unidades;

  const _ProductoFormSheet({
    this.initial,
    required this.categorias,
    required this.marcas,
    required this.subMarcas,
    required this.unidades,
  });

  @override
  State<_ProductoFormSheet> createState() => _ProductoFormSheetState();
}

class _ProductoFormSheetState extends State<_ProductoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _precio;
  int? _categoriaId;
  int? _marcaId;
  int? _subMarcaId;
  int? _unidadId;
  bool _afectoIgv = true;
  bool _activo = true;

  int? _relId(String directField, String relField) {
    final i = widget.initial;
    if (i == null) return null;
    if (i[directField] != null) return i[directField] as int;
    if (i[relField] is Map) return (i[relField] as Map)['id'] as int?;
    return null;
  }

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _codigo = TextEditingController(text: i?['codigo'] ?? '');
    _nombre = TextEditingController(text: i?['nombre'] ?? '');
    _descripcion = TextEditingController(text: i?['descripcion'] ?? '');
    _precio = TextEditingController(text: i?['precio_base']?.toString() ?? '');
    _categoriaId = _relId('categoria_id', 'categoria');
    _marcaId = _relId('marca_id', 'marca');
    _subMarcaId = _relId('sub_marca_id', 'sub_marca');
    _unidadId = _relId('unidad_medida_id', 'unidad_medida');
    _afectoIgv = i?['afecto_igv'] == true || i == null;
    _activo = i?['activo'] == true || i == null;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _descripcion.dispose();
    _precio.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'codigo': _codigo.text.trim(),
      'nombre': _nombre.text.trim(),
      'categoria_id': _categoriaId,
      'marca_id': _marcaId,
      'sub_marca_id': _subMarcaId,
      'unidad_medida_id': _unidadId,
      'descripcion': _descripcion.text.trim(),
      'precio_base': double.tryParse(_precio.text.trim()) ?? 0,
      'afecto_igv': _afectoIgv,
      'activo': _activo,
    });
  }

  List<AppSelectOption<int>> _opts(List<Map<String, dynamic>> list) => list
      .map(
        (e) =>
            AppSelectOption<int>(e['id'] as int, e['nombre']?.toString() ?? ''),
      )
      .toList();

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
                controller: _codigo,
                label: 'Código / SKU',
                icon: Icons.qr_code_2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el código'
                    : null,
              ),
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.inventory_2_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppSelect<int>(
                label: 'Categoría',
                icon: Icons.category_outlined,
                value: _categoriaId,
                options: _opts(widget.categorias),
                onChanged: (v) => setState(() => _categoriaId = v),
                validator: (v) => v == null ? 'Seleccione una categoría' : null,
              ),
              AppSelect<int>(
                label: 'Marca',
                icon: Icons.sell_outlined,
                value: _marcaId,
                options: _opts(widget.marcas),
                onChanged: (v) => setState(() => _marcaId = v),
                validator: (v) => v == null ? 'Seleccione una marca' : null,
              ),
              AppSelect<int>(
                label: 'Sub-marca (opcional)',
                icon: Icons.style_outlined,
                value: _subMarcaId,
                options: _opts(widget.subMarcas),
                onChanged: (v) => setState(() => _subMarcaId = v),
              ),
              AppSelect<int>(
                label: 'Unidad de medida',
                icon: Icons.straighten,
                value: _unidadId,
                options: widget.unidades
                    .map(
                      (u) => AppSelectOption<int>(
                        u['id'] as int,
                        u['nombre']?.toString() ?? '',
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _unidadId = v),
                validator: (v) => v == null ? 'Seleccione una unidad' : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppFormSection(
            title: 'Precio y detalle',
            children: [
              AppTextField(
                controller: _precio,
                label: 'Precio base (S/)',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el precio'
                    : null,
              ),
              AppTextArea(controller: _descripcion, label: 'Descripción'),
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
