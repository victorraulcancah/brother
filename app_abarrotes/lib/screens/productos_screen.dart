import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../utils/unidades.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
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

  // Paso 1: datos del producto
  late final TextEditingController _nombre;
  late final TextEditingController _codigoBarras;
  int? _categoriaId;
  int? _subCategoriaId;
  int? _marcaId;
  int? _subMarcaId;
  bool _activo = true;

  // Paso 2: cómo lo compro
  int? _unidadCompraId;
  int? _unidadContenidoId;
  late final TextEditingController _cantidadCompra;
  late final TextEditingController _precioCompra;

  // Paso 2: cómo lo vendo
  final List<_VentaEntry> _ventas = [];

  // Campos que ya no se piden pero se conservan al editar (los genera o los
  // mantiene el backend): código, descripción de ticket y niveles de stock.
  late final TextEditingController _codigo;
  late final TextEditingController _descripcionTicket;
  late final TextEditingController _stockMinimo;
  late final TextEditingController _stockMaximo;
  late final TextEditingController _descripcion;

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

    _nombre = TextEditingController(text: txt(i?['nombre']));
    _codigoBarras = TextEditingController(text: txt(i?['codigo_barras']));
    _codigo = TextEditingController(text: txt(i?['codigo']));
    _descripcionTicket = TextEditingController(text: txt(i?['descripcion_ticket']));
    _stockMinimo = TextEditingController(text: i?['stock_minimo']?.toString() ?? '');
    _stockMaximo = TextEditingController(text: i?['stock_maximo']?.toString() ?? '');
    _descripcion = TextEditingController(text: txt(i?['descripcion']));

    _categoriaId = _relId('categoria_id', 'categoria');
    _subCategoriaId = _relId('sub_categoria_id', 'sub_categoria');
    _marcaId = _relId('marca_id', 'marca');
    _subMarcaId = _relId('sub_marca_id', 'sub_marca');
    _activo = i?['activo'] == true || i == null;

    // Se reconstruye "compro / vendo" desde lo guardado.
    final baseId = _relId('unidad_medida_id', 'unidad_medida');
    final contenido = describirContenido(widget.unidades, baseId, i?['factor_compra_base']);
    _unidadCompraId = _relId('unidad_compra_id', 'unidad_compra');
    _unidadContenidoId = contenido.unidadContenidoId;
    _cantidadCompra = TextEditingController(text: contenido.cantidad);

    final pres = (i?['presentaciones'] is List) ? i!['presentaciones'] as List : const [];
    final factorCompra = double.tryParse('${i?['factor_compra_base']}') ?? 0;

    // El precio de compra no se guarda tal cual: se deduce del costo unitario.
    double precioTotal = 0;
    for (final p in pres) {
      final factor = double.tryParse('${p['factor_conversion']}') ?? 1;
      final costo = double.tryParse('${p['precio_compra']}') ?? 0;
      if (factor > 0 && costo > 0) {
        precioTotal = (costo / factor) * factorCompra;
        break;
      }
    }
    _precioCompra = TextEditingController(
      text: precioTotal > 0 ? sinCerosSobrantes(precioTotal, 2) : '',
    );

    for (final p in pres) {
      _ventas.add(_VentaEntry(
        unidadId: int.tryParse('${p['unidad_base']?['id']}'),
        margenCtrl: TextEditingController(text: txt(p['margen'])),
        precioCtrl: TextEditingController(text: txt(p['precio_venta'])),
      ));
    }
    if (_ventas.isEmpty) _ventas.add(_VentaEntry.vacia());
  }

  @override
  void dispose() {
    _nombre.dispose();
    _codigoBarras.dispose();
    _codigo.dispose();
    _descripcionTicket.dispose();
    _stockMinimo.dispose();
    _stockMaximo.dispose();
    _descripcion.dispose();
    _cantidadCompra.dispose();
    _precioCompra.dispose();
    for (final v in _ventas) {
      v.dispose();
    }
    super.dispose();
  }

  // ---- Cálculo ----

  CompraInput get _compra => CompraInput(
        unidadCompraId: _unidadCompraId,
        cantidad: double.tryParse(_cantidadCompra.text.trim()) ?? 0,
        unidadContenidoId: _unidadContenidoId,
        precio: double.tryParse(_precioCompra.text.trim()) ?? 0,
      );

  CalculoUnidades get _calculo => calcularPresentaciones(
        unidades: widget.unidades,
        compra: _compra,
        ventas: _ventas.map((v) => v.aInput()).toList(),
      );

  String _nombreUnidad(int? id) => nombreUnidad(widget.unidades, id);

  String _money(double n) => 'S/ ${sinCerosSobrantes(n, 4)}';

  /// El % y el precio son dos vistas del mismo dato: al mover uno se recalcula
  /// el otro sobre el costo de esa fila.
  void _onPrecioVentaEditado(_VentaEntry v, String valor) {
    final costo = _calculo.filaDe(v.unidadId)?.precioCompra ?? 0;
    final precio = double.tryParse(valor.trim());
    if (costo > 0 && precio != null) {
      v.margenCtrl.text = sinCerosSobrantes((precio / costo - 1) * 100, 1);
    }
    setState(() {});
  }

  void _onMargenEditado(_VentaEntry v) {
    // Se limpia el precio para que vuelva a derivarse del %.
    v.precioCtrl.text = '';
    setState(() {});
  }

  // ---- Guardar ----

  void _guardar() {
    if (!_formKey1.currentState!.validate()) {
      setState(() => _step = 0);
      return;
    }
    if (!_formKey2.currentState!.validate()) return;

    final calculo = _calculo;

    if (_unidadCompraId == null || _compra.cantidad <= 0 || _unidadContenidoId == null) {
      showAppSnackbar(context, 'Completa cómo compras el producto',
          type: AppSnackbarType.warning);
      return;
    }
    if (calculo.filas.isEmpty) {
      showAppSnackbar(context, 'Agrega al menos un formato de venta',
          type: AppSnackbarType.warning);
      return;
    }
    final elegidas = _ventas.where((v) => v.unidadId != null).map((v) => v.unidadId).toList();
    if (elegidas.toSet().length != elegidas.length) {
      showAppSnackbar(context, 'Hay formatos de venta repetidos',
          type: AppSnackbarType.warning);
      return;
    }

    final presData = calculo.filas
        .map((f) => {
              'nombre': _nombreUnidad(f.unidadId),
              'unidad_base_id': f.unidadId,
              'factor_conversion': f.factor,
              'precio_compra': double.parse(f.precioCompra.toStringAsFixed(4)),
              'margen': f.margen,
              'precio_venta': double.parse(f.precioVenta.toStringAsFixed(4)),
              'cantidad_complementaria': 0,
            })
        .toList();

    String? vacioANulo(String s) => s.trim().isEmpty ? null : s.trim();

    Navigator.pop(context, {
      // Vacío al crear: el backend genera PROD001, PROD002…
      'codigo': vacioANulo(_codigo.text),
      'codigo_barras': vacioANulo(_codigoBarras.text),
      'nombre': _nombre.text.trim(),
      'descripcion_ticket': vacioANulo(_descripcionTicket.text),
      'categoria_id': _categoriaId,
      'sub_categoria_id': _subCategoriaId,
      'marca_id': _marcaId,
      'sub_marca_id': _subMarcaId,
      // La unidad base es el formato de venta más pequeño, calculado solo.
      'unidad_medida_id': calculo.baseId,
      'unidad_base_id': calculo.baseId,
      'unidad_compra_id': _unidadCompraId,
      'factor_compra_base': calculo.factorCompraBase,
      'descripcion': _descripcion.text.trim(),
      'stock_minimo': double.tryParse(_stockMinimo.text.trim()) ?? 0,
      'stock_maximo': double.tryParse(_stockMaximo.text.trim()) ?? 0,
      'activo': _activo,
      'presentaciones': presData,
    });
  }

  List<AppSelectOption<int>> _opts(List<Map<String, dynamic>> list) => list
      .map((e) => AppSelectOption<int>(e['id'] as int, e['nombre']?.toString() ?? ''))
      .toList();

  List<AppSelectOption<int>> get _optsUnidades => widget.unidades
      .map((u) => AppSelectOption<int>(
            u['id'] as int,
            u['abreviatura'] != null ? '${u['nombre']} (${u['abreviatura']})' : '${u['nombre']}',
          ))
      .toList();

  /// Sub-categorías de la categoría elegida; sin categoría, ninguna.
  List<Map<String, dynamic>> _subCategoriasDeCategoria() {
    if (_categoriaId == null) return const [];
    return widget.categorias
        .where((c) => c['categoria_padre_id']?.toString() == '$_categoriaId')
        .toList();
  }

  // ---- Interfaz ----

  @override
  Widget build(BuildContext context) {
    // El modal ya envuelve al hijo en un scroll de altura no acotada: un
    // Expanded aqui lanza "unbounded height" y el sheet queda en blanco.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepper(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _step == 0 ? _buildStep1() : _buildStep2(),
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
          _stepIndicator(1, 'Precios'),
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
              child: Text('${index + 1}',
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
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
                controller: _nombre,
                label: 'Producto',
                icon: Icons.inventory_2_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null,
              ),
              AppTextField(
                controller: _codigoBarras,
                label: 'Código de barras (opcional)',
                icon: Icons.barcode_reader,
              ),
              AppToggle(
                label: 'Producto activo',
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
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
                label: 'Sub-categoría (opcional)',
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final calculo = _calculo;

    return Form(
      key: _formKey2,
      child: Column(
        children: [
          AppFormSection(
            title: 'Cómo lo compro',
            children: [
              AppSelect<int>(
                label: 'Compro por',
                icon: Icons.shopping_bag_outlined,
                value: _unidadCompraId,
                options: _optsUnidades,
                onChanged: (v) => setState(() => _unidadCompraId = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _cantidadCompra,
                      label: 'Que trae',
                      icon: Icons.numbers,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppSelect<int>(
                      label: 'De',
                      value: _unidadContenidoId,
                      options: _optsUnidades,
                      onChanged: (v) => setState(() => _unidadContenidoId = v),
                    ),
                  ),
                ],
              ),
              AppTextField(
                controller: _precioCompra,
                label: 'Precio de compra (S/)',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              if (calculo.baseId != null && calculo.factorCompraBase > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _unidadCompraId != null
                        ? '1 ${_nombreUnidad(_unidadCompraId)} = '
                            '${sinCerosSobrantes(calculo.factorCompraBase, 2)} '
                            '${_nombreUnidad(calculo.baseId)}'
                            '${calculo.costoBase > 0 ? '\nCosto por ${_nombreUnidad(calculo.baseId).toLowerCase()}: ${_money(calculo.costoBase)}' : ''}'
                        : 'Elige en qué unidad compras el producto.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AppFormSection(
            title: 'Cómo lo vendo',
            trailing: TextButton.icon(
              onPressed: () => setState(() => _ventas.add(_VentaEntry.vacia())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
            children: [
              ..._ventas.asMap().entries.map((e) => _buildVentaCard(e.key, e.value)),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'El costo de cada formato sale de tu precio de compra. El precio de venta se '
                  'calcula con el % de ganancia; si escribes uno a mano, manda el tuyo.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVentaCard(int index, _VentaEntry v) {
    final fila = _calculo.filaDe(v.unidadId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppSelect<int>(
                    label: 'Vendo por',
                    value: v.unidadId,
                    options: _optsUnidades,
                    onChanged: (nuevo) => setState(() => v.unidadId = nuevo),
                  ),
                ),
                if (_ventas.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.danger, size: 20),
                    onPressed: () => setState(() {
                      _ventas.removeAt(index).dispose();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: v.margenCtrl,
                    label: '% ganancia',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _onMargenEditado(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextField(
                    controller: v.precioCtrl,
                    label: 'Precio de venta',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (valor) => _onPrecioVentaEditado(v, valor),
                  ),
                ),
              ],
            ),
            if (fila != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Me cuesta ${_money(fila.precioCompra)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text(
                    'Ganas ${_money(fila.ganancia)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fila.ganancia < 0 ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
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
                : PrimaryButton(label: 'Guardar', onPressed: _guardar),
          ),
        ],
      ),
    );
  }
}

/// Un formato de venta en edición.
class _VentaEntry {
  int? unidadId;
  final TextEditingController margenCtrl;
  final TextEditingController precioCtrl;

  _VentaEntry({
    this.unidadId,
    required this.margenCtrl,
    required this.precioCtrl,
  });

  factory _VentaEntry.vacia() => _VentaEntry(
        margenCtrl: TextEditingController(text: '25'),
        precioCtrl: TextEditingController(),
      );

  VentaInput aInput() => VentaInput(
        unidadId: unidadId,
        margen: double.tryParse(margenCtrl.text.trim()),
        precioVenta: precioCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(precioCtrl.text.trim()),
      );

  void dispose() {
    margenCtrl.dispose();
    precioCtrl.dispose();
  }
}
