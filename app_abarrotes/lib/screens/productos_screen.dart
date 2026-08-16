import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
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
  String? _error;
  String _busqueda = '';
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.productos);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // En paralelo: eran cinco llamadas encadenadas.
      final r = await Future.wait([
        _crud.getAll(),
        CrudService(_api, ApiEndpoints.categorias).getAll(),
        CrudService(_api, ApiEndpoints.marcas).getAll(),
        CrudService(_api, ApiEndpoints.subMarcas).getAll(),
        CrudService(_api, ApiEndpoints.unidades).getAll(),
      ]);
      _items = r[0];
      _categorias = r[1];
      _marcas = r[2];
      _subMarcas = r[3];
      _unidades = r[4];
    } catch (_) {
      _error = 'No se pudieron cargar los productos.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((p) {
      if (_filtroEstado == 'activos' && p['activo'] != true) return false;
      if (_filtroEstado == 'inactivos' && p['activo'] == true) return false;
      if (q.isEmpty) return true;
      final texto =
          '${p['codigo']} ${p['codigo_barras'] ?? ''} ${p['nombre']} '
          '${_nested(p, 'marca')} ${_nested(p, 'categoria')}';
      return texto.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
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
      // El backend acepta las presentaciones dentro del payload del producto,
      // así que todo se guarda en una sola llamada (antes se borraban y se
      // recreaban por endpoints aparte: si fallaba a medias, se perdían).
      if (item != null) {
        await _crud.update(item['id'], result);
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

  Future<void> _delete(Map<String, dynamic> item) async {
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
          : Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AppMessage(text: _error!),
                  ),
                AppListHeader(
                  hintText: 'Buscar productos...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Estado',
                      value: _filtroEstado,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('activos', 'Activos'),
                        AppListFilterOption('inactivos', 'Inactivos'),
                      ],
                      onChanged: (v) => setState(() => _filtroEstado = v),
                    ),
                  ],
                  activeFilters: _filtroEstado != null ? 1 : 0,
                  onClearFilters: () => setState(() => _filtroEstado = null),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(
                          child: Text(
                            _items.isEmpty
                                ? 'No hay productos'
                                : 'Ningun producto coincide con la busqueda',
                          ),
                        )
                      : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _visibles.length,
              itemBuilder: (context, index) {
                final item = _visibles[index];
                final activo = item['activo'] == true;
                final presCount = _presentacionesCount(item);
                return DataCard(
                  title: item['nombre']?.toString() ?? '',
                  subtitle: '${item['codigo']}  ·  $presCount presentac.  ·  ${_nested(item, 'categoria')}',
                  rows: [
                    DataCardRow.text('Marca', _nested(item, 'marca')),
                    DataCardRow.text(
                      'Unidad',
                      (item['unidad_medida'] is Map)
                          ? (item['unidad_medida']['abreviatura'] ??
                                    item['unidad_medida']['nombre'] ??
                                    '-')
                                .toString()
                          : '-',
                    ),
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
                      onTap: () => _openForm(item: item),
                    ),
                    DataCardAction(
                      icon: Icons.delete_outline,
                      color: AppColors.danger,
                      tooltip: 'Eliminar',
                      onTap: () => _delete(item),
                    ),
                  ],
                );
              },
            ),
                ),
              ],
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
  late final TextEditingController _codigoBarras;
  late final TextEditingController _descripcionTicket;
  late final TextEditingController _stockMinimo;
  late final TextEditingController _stockMaximo;
  int? _subCategoriaId;
  late final TextEditingController _descripcion;
  bool _activo = true;

  int? _relId(String directField, String relField) {
    final i = widget.initial;
    if (i == null) return null;
    // Casts tolerantes: un id que llega como string o un campo inesperado no
    // deben tumbar el formulario de edicion.
    if (i[directField] != null) return int.tryParse('${i[directField]}');
    if (i[relField] is Map) return int.tryParse('${(i[relField] as Map)['id']}');
    return null;
  }

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    String txt(dynamic v) => v == null ? '' : '$v';
    _codigo = TextEditingController(text: txt(i?['codigo']));
    _nombre = TextEditingController(text: txt(i?['nombre']));
    _precio = TextEditingController(text: i?['precio_base']?.toString() ?? '');
    _codigoBarras = TextEditingController(text: txt(i?['codigo_barras']));
    _descripcionTicket = TextEditingController(
      text: txt(i?['descripcion_ticket']),
    );
    _stockMinimo = TextEditingController(
      text: i?['stock_minimo']?.toString() ?? '',
    );
    _stockMaximo = TextEditingController(
      text: i?['stock_maximo']?.toString() ?? '',
    );
    _descripcion = TextEditingController(text: txt(i?['descripcion']));
    _factorCompra = TextEditingController(text: i?['factor_compra_base']?.toString() ?? '1');

    _categoriaId = _relId('categoria_id', 'categoria');
    _subCategoriaId = _relId('sub_categoria_id', 'sub_categoria');
    _marcaId = _relId('marca_id', 'marca');
    _subMarcaId = _relId('sub_marca_id', 'sub_marca');
    _unidadId = _relId('unidad_medida_id', 'unidad_medida');
    _unidadCompraId = _relId('unidad_compra_id', 'unidad_compra');
    _unidadBaseId = _relId('unidad_base_id', 'unidad_base');
    _activo = i?['activo'] == true || i == null;

    if (i != null) {
      final pres = i['presentaciones'];
      if (pres is List) {
        for (final p in pres) {
          _presentaciones.add(_PresentacionEntry(
            nombreCtrl: TextEditingController(text: txt(p['nombre'])),
            codigoCtrl: TextEditingController(text: txt(p['codigo_barras'])),
            costoCtrl: TextEditingController(text: (p['precio_compra'] ?? '').toString()),
            margenCtrl: TextEditingController(text: (p['margen'] ?? '').toString()),
            precioCtrl: TextEditingController(text: (p['precio_venta'] ?? '').toString()),
            factorCtrl: TextEditingController(text: (p['factor_conversion'] ?? '1').toString()),
            unidadBaseId: int.tryParse('${p['unidad_base']?['id']}'),
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
    _codigoBarras.dispose();
    _descripcionTicket.dispose();
    _stockMinimo.dispose();
    _stockMaximo.dispose();
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
      'precio_compra': double.tryParse(p.costoCtrl.text.trim()) ?? 0,
      'margen': double.tryParse(p.margenCtrl.text.trim()) ?? 0,
      'precio_venta': double.tryParse(p.precioCtrl.text.trim()) ?? 0,
      'factor_conversion': double.tryParse(p.factorCtrl.text.trim()) ?? 1,
      'unidad_base_id': p.unidadBaseId,
    }).toList();

    Navigator.pop(context, {
      'codigo': _codigo.text.trim(),
      'codigo_barras': _codigoBarras.text.trim().isEmpty
          ? null
          : _codigoBarras.text.trim(),
      'nombre': _nombre.text.trim(),
      'descripcion_ticket': _descripcionTicket.text.trim().isEmpty
          ? null
          : _descripcionTicket.text.trim(),
      'categoria_id': _categoriaId,
      'sub_categoria_id': _subCategoriaId,
      'marca_id': _marcaId,
      'sub_marca_id': _subMarcaId,
      'unidad_medida_id': _unidadId,
      'unidad_compra_id': _unidadCompraId,
      'unidad_base_id': _unidadBaseId,
      'factor_compra_base': double.tryParse(_factorCompra.text.trim()) ?? 1,
      'descripcion': _descripcion.text.trim(),
      'precio_base': double.tryParse(_precio.text.trim()) ?? 0,
      'stock_minimo': double.tryParse(_stockMinimo.text.trim()) ?? 0,
      'stock_maximo': double.tryParse(_stockMaximo.text.trim()) ?? 0,
      'activo': _activo,
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

  /// Sub-categorías de la categoría elegida; sin categoría, ninguna.
  List<Map<String, dynamic>> _subCategoriasDeCategoria() {
    if (_categoriaId == null) return const [];
    return widget.categorias
        .where((c) => c['categoria_padre_id']?.toString() == '$_categoriaId')
        .toList();
  }

  double _unidadFactor(int? id) {
    final u = widget.unidades.firstWhere((e) => e['id'] == id, orElse: () => <String, dynamic>{});
    return double.tryParse('${u['factor_base'] ?? 1}') ?? 1;
  }

  // Al elegir la unidad de una presentación, auto-sugiere el factor a la unidad base (editable).
  void _setPresUnidad(_PresentacionEntry p, int? id) {
    p.unidadBaseId = id;
    final base = _unidadFactor(_unidadBaseId);
    final f = base > 0 ? _unidadFactor(id) / base : _unidadFactor(id);
    p.factorCtrl.text = f == f.roundToDouble() ? f.toInt().toString() : f.toStringAsFixed(4);
  }

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
                controller: _codigoBarras,
                label: 'Código de barras',
                icon: Icons.barcode_reader,
              ),
              AppTextField(
                controller: _nombre,
                label: 'Nombre del producto',
                icon: Icons.inventory_2_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null,
              ),
              AppTextField(
                controller: _descripcionTicket,
                label: 'Descripción para ticket',
                icon: Icons.receipt_long_outlined,
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
                // Cambiar de categoría invalida la sub-categoría elegida.
                onChanged: (v) => setState(() {
                  _categoriaId = v;
                  _subCategoriaId = null;
                }),
              ),
              AppSelect<int>(
                label: 'Sub-categoría',
                icon: Icons.account_tree_outlined,
                value: _subCategoriaId,
                options: _opts(_subCategoriasDeCategoria()),
                onChanged: (v) => setState(() => _subCategoriaId = v),
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
              AppTextField(
                controller: _stockMinimo,
                label: 'Stock mínimo',
                icon: Icons.trending_down,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              AppTextField(
                controller: _stockMaximo,
                label: 'Stock máximo',
                icon: Icons.trending_up,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              AppTextArea(controller: _descripcion, label: 'Descripción'),
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
            AppTextField(controller: p.codigoCtrl, label: 'Código barras'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: p.costoCtrl,
                    label: 'Costo S/',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    // El precio de venta sale del costo y el margen.
                    onChanged: (_) => setState(p.recalcularPrecio),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextField(
                    controller: p.margenCtrl,
                    label: 'Margen %',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(p.recalcularPrecio),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextField(
                    controller: p.precioCtrl,
                    label: 'Precio venta S/',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppSelect<int>(
                    label: 'Unidad',
                    value: p.unidadBaseId,
                    options: _opts(widget.unidades),
                    onChanged: (v) => setState(() => _setPresUnidad(p, v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextField(
                    controller: p.factorCtrl,
                    label: 'Equivale a (base)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
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
  final TextEditingController costoCtrl;
  final TextEditingController margenCtrl;
  final TextEditingController precioCtrl;
  final TextEditingController factorCtrl;
  int? unidadBaseId;

  _PresentacionEntry({
    required this.nombreCtrl,
    required this.codigoCtrl,
    required this.precioCtrl,
    required this.factorCtrl,
    TextEditingController? costoCtrl,
    TextEditingController? margenCtrl,
    this.unidadBaseId,
  }) : costoCtrl = costoCtrl ?? TextEditingController(),
       margenCtrl = margenCtrl ?? TextEditingController();

  /// Precio de venta = costo + margen%, como lo calcula la web.
  void recalcularPrecio() {
    final costo = double.tryParse(costoCtrl.text.trim()) ?? 0;
    final margen = double.tryParse(margenCtrl.text.trim()) ?? 0;
    if (costo <= 0) return;
    precioCtrl.text = (costo * (1 + margen / 100)).toStringAsFixed(2);
  }

  void dispose() {
    nombreCtrl.dispose();
    codigoCtrl.dispose();
    costoCtrl.dispose();
    margenCtrl.dispose();
    precioCtrl.dispose();
    factorCtrl.dispose();
  }
}
