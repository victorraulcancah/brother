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
      child: _ProductoWizard(
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
        final updated = await _crud.update(item!['id'], result['producto']);
        final prodId = updated['id'] ?? item['id'];
        await _sincronizarPresentaciones(prodId, result['presentaciones'] ?? []);
      } else {
        final created = await _crud.create(result['producto']);
        final prodId = created['id'];
        await _sincronizarPresentaciones(prodId, result['presentaciones'] ?? []);
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

  Future<void> _sincronizarPresentaciones(int productoId, List<Map<String, dynamic>> presentaciones) async {
    final listEndpoint = ApiEndpoints.presentaciones(productoId);
    final itemBase = ApiEndpoints.presentacionesBase;
    final existentes = await _api.get(listEndpoint);
    final lista = (existentes is List) ? existentes.whereType<Map<String, dynamic>>().toList() : [];
    for (final p in lista) {
      await _api.delete('$itemBase/${p['id']}');
    }
    for (final p in presentaciones) {
      await _api.post(listEndpoint, body: p);
    }
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar producto',
      message: '¿Eliminar "${item['nombre']}"?\nSe eliminarán también sus presentaciones.',
    );
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(context, 'Producto eliminado', type: AppSnackbarType.error);
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

  int _presentacionesCount(Map<String, dynamic> item) {
    final p = item['presentaciones'];
    if (p is List) return p.length;
    return 0;
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
                final presCount = _presentacionesCount(item);
                return DataCard(
                  title: item['nombre']?.toString() ?? '',
                  subtitle: '${item['codigo']}  ·  ${presCount} presentac.  ·  ${_nested(item, 'categoria')}',
                  rows: [
                    DataCardRow.text('Precio base', 'S/ ${item['precio_base'] ?? ''}'),
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

class _ProductoWizard extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> categorias;
  final List<Map<String, dynamic>> marcas;
  final List<Map<String, dynamic>> subMarcas;
  final List<Map<String, dynamic>> unidades;

  const _ProductoWizard({
    this.initial,
    required this.categorias,
    required this.marcas,
    required this.subMarcas,
    required this.unidades,
  });

  @override
  State<_ProductoWizard> createState() => _ProductoWizardState();
}

class _ProductoWizardState extends State<_ProductoWizard> {
  int _step = 0;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // Step 1 fields
  late final TextEditingController _codigo;
  late final TextEditingController _nombre;
  int? _categoriaId;
  int? _marcaId;
  int? _subMarcaId;
  int? _unidadId;
  int? _unidadCompraId;
  int? _unidadBaseId;
  late final TextEditingController _factorCompra;

  // Step 2: presentaciones
  final List<_PresentacionEntry> _presentaciones = [];

  // Step 3 fields
  late final TextEditingController _precio;
  late final TextEditingController _descripcion;
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
    _precio = TextEditingController(text: i?['precio_base']?.toString() ?? '');
    _descripcion = TextEditingController(text: i?['descripcion'] ?? '');
    _factorCompra = TextEditingController(text: i?['factor_compra_base']?.toString() ?? '1');

    _categoriaId = _relId('categoria_id', 'categoria');
    _marcaId = _relId('marca_id', 'marca');
    _subMarcaId = _relId('sub_marca_id', 'sub_marca');
    _unidadId = _relId('unidad_medida_id', 'unidad_medida');
    _unidadCompraId = _relId('unidad_compra_id', 'unidad_compra');
    _unidadBaseId = _relId('unidad_base_id', 'unidad_base');
    _afectoIgv = i?['afecto_igv'] == true || i == null;
    _activo = i?['activo'] == true || i == null;

    if (i != null) {
      final pres = i['presentaciones'];
      if (pres is List) {
        for (final p in pres) {
          _presentaciones.add(_PresentacionEntry(
            nombreCtrl: TextEditingController(text: p['nombre'] ?? ''),
            codigoCtrl: TextEditingController(text: p['codigo_barras'] ?? ''),
            precioCtrl: TextEditingController(text: (p['precio_venta'] ?? '').toString()),
            factorCtrl: TextEditingController(text: (p['factor_conversion'] ?? '1').toString()),
            unidadBaseId: p['unidad_base']?['id'],
          ));
        }
      }
    }
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _precio.dispose();
    _descripcion.dispose();
    _factorCompra.dispose();
    for (final p in _presentaciones) {
      p.dispose();
    }
    super.dispose();
  }

  void _guardar() {
    if (!_formKey1.currentState!.validate()) return;
    if (_presentaciones.isEmpty) {
      showAppSnackbar(context, 'Debe agregar al menos una presentación', type: AppSnackbarType.warning);
      return;
    }
    if (!_formKey2.currentState!.validate()) return;

    final presData = _presentaciones.map((p) => {
      'nombre': p.nombreCtrl.text.trim(),
      'codigo_barras': p.codigoCtrl.text.trim().isEmpty ? null : p.codigoCtrl.text.trim(),
      'precio_venta': double.tryParse(p.precioCtrl.text.trim()) ?? 0,
      'factor_conversion': double.tryParse(p.factorCtrl.text.trim()) ?? 1,
      'unidad_base_id': p.unidadBaseId,
    }).toList();

    Navigator.pop(context, {
      'producto': {
        'codigo': _codigo.text.trim(),
        'nombre': _nombre.text.trim(),
        'categoria_id': _categoriaId,
        'marca_id': _marcaId,
        'sub_marca_id': _subMarcaId,
        'unidad_medida_id': _unidadId,
        'unidad_compra_id': _unidadCompraId,
        'unidad_base_id': _unidadBaseId,
        'factor_compra_base': double.tryParse(_factorCompra.text.trim()) ?? 1,
        'descripcion': _descripcion.text.trim(),
        'precio_base': double.tryParse(_precio.text.trim()) ?? 0,
        'afecto_igv': _afectoIgv,
        'activo': _activo,
      },
      'presentaciones': presData,
    });
  }

  void _agregarPresentacion() {
    setState(() {
      _presentaciones.add(_PresentacionEntry(
        nombreCtrl: TextEditingController(),
        codigoCtrl: TextEditingController(),
        precioCtrl: TextEditingController(),
        factorCtrl: TextEditingController(text: '1'),
      ));
    });
  }

  List<AppSelectOption<int>> _opts(List<Map<String, dynamic>> list) => list
      .map((e) => AppSelectOption<int>(e['id'] as int, e['nombre']?.toString() ?? ''))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepper(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _step == 0 ? _buildStep1() : _buildStep2(),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _stepIndicator(0, 'Datos'),
          const Expanded(child: Divider()),
          _stepIndicator(1, 'Presentaciones'),
        ],
      ),
    );
  }

  Widget _stepIndicator(int index, String label) {
    final active = _step == index;
    final color = active ? AppColors.primary : AppColors.textMuted;
    return GestureDetector(
      onTap: index <= _step ? () => setState(() => _step = index) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Center(
              child: Text('${index + 1}', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: Column(
        children: [
          AppFormSection(
            title: 'Identificación',
            children: [
              AppTextField(
                controller: _codigo,
                label: 'Código / SKU',
                icon: Icons.qr_code_2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el código' : null,
              ),
              AppTextField(
                controller: _nombre,
                label: 'Nombre del producto',
                icon: Icons.inventory_2_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppFormSection(
            title: 'Clasificación',
            children: [
              AppSelect<int>(
                label: 'Categoría',
                icon: Icons.category_outlined,
                value: _categoriaId,
                options: _opts(widget.categorias),
                onChanged: (v) => setState(() => _categoriaId = v),
              ),
              AppSelect<int>(
                label: 'Marca',
                icon: Icons.sell_outlined,
                value: _marcaId,
                options: _opts(widget.marcas),
                onChanged: (v) => setState(() {
                  _marcaId = v;
                  _subMarcaId = null;
                }),
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
                options: _opts(widget.unidades),
                onChanged: (v) => setState(() => _unidadId = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppFormSection(
            title: 'Unidades y Conversión',
            children: [
              AppSelect<int>(
                label: 'Unidad de compra (opcional)',
                icon: Icons.shopping_bag_outlined,
                value: _unidadCompraId,
                options: _opts(widget.unidades),
                onChanged: (v) => setState(() => _unidadCompraId = v),
              ),
              AppSelect<int>(
                label: 'Unidad base (inventario)',
                icon: Icons.straighten,
                value: _unidadBaseId,
                options: _opts(widget.unidades),
                onChanged: (v) => setState(() => _unidadBaseId = v),
              ),
              AppTextField(
                controller: _factorCompra,
                label: '1 unidad compra = ? unidad base',
                icon: Icons.calculate,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKey2,
      child: Column(
        children: [
          AppFormSection(
            title: 'Presentaciones',
            trailing: TextButton.icon(
              onPressed: _agregarPresentacion,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
            children: [
              if (_presentaciones.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Agregue al menos una presentación (ej: 500g, 1kg, 3L)',
                    style: TextStyle(color: AppColors.textMuted)),
                ),
              ..._presentaciones.asMap().entries.map((entry) => _buildPresentacionCard(entry.key, entry.value)),
            ],
          ),
          const SizedBox(height: 12),
          AppFormSection(
            title: 'Precio y detalle',
            children: [
              AppTextField(
                controller: _precio,
                label: 'Precio base (S/)',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              AppTextArea(controller: _descripcion, label: 'Descripción'),
              AppToggle(label: 'Afecto a IGV', value: _afectoIgv, onChanged: (v) => setState(() => _afectoIgv = v)),
              AppToggle(label: 'Activo', value: _activo, onChanged: (v) => setState(() => _activo = v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresentacionCard(int index, _PresentacionEntry p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('Presentación ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                  onPressed: () => setState(() => _presentaciones.removeAt(index)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: p.nombreCtrl,
              label: 'Nombre (ej: 500g, 1kg, 3L)',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: p.codigoCtrl,
                    label: 'Código barras',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextField(
                    controller: p.precioCtrl,
                    label: 'Precio venta S/',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: p.factorCtrl,
                    label: 'Factor (a unidad base)',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppSelect<int>(
                    label: 'Unidad base',
                    value: p.unidadBaseId,
                    options: _opts(widget.unidades),
                    onChanged: (v) => setState(() => p.unidadBaseId = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: SecondaryButton(
                label: 'Anterior',
                onPressed: () => setState(() => _step--),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            child: _step < 1
                ? PrimaryButton(
                    label: 'Siguiente',
                    onPressed: () {
                      if (_formKey1.currentState!.validate()) {
                        setState(() => _step++);
                      }
                    },
                  )
                : PrimaryButton(label: 'Guardar producto', onPressed: _guardar),
          ),
        ],
      ),
    );
  }
}

class _PresentacionEntry {
  final TextEditingController nombreCtrl;
  final TextEditingController codigoCtrl;
  final TextEditingController precioCtrl;
  final TextEditingController factorCtrl;
  int? unidadBaseId;

  _PresentacionEntry({
    required this.nombreCtrl,
    required this.codigoCtrl,
    required this.precioCtrl,
    required this.factorCtrl,
    this.unidadBaseId,
  });

  void dispose() {
    nombreCtrl.dispose();
    codigoCtrl.dispose();
    precioCtrl.dispose();
    factorCtrl.dispose();
  }
}
