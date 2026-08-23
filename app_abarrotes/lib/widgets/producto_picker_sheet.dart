import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_badge.dart';
import 'app_button.dart';
import 'app_select.dart';

/// Un producto elegido en el buscador: producto, unidad (presentación) y cantidad.
class ProductoSeleccion {
  final Map<String, dynamic> producto;
  final Map<String, dynamic> presentacion;
  final double cantidad;
  const ProductoSeleccion({required this.producto, required this.presentacion, required this.cantidad});
}

String _fmt(num n) => n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);

/// Buscador avanzado de productos (equivalente móvil de `ProductoPickerModal`
/// de la web): texto + filtros de categoría / sub-categoría / marca / sub-marca
/// y, con [stockFilter], por estado de stock y "stock hasta N".
///
/// Devuelve la lista de seleccionados con unidad y cantidad, o `null` si se cierra.
Future<List<ProductoSeleccion>?> showProductoPicker(
  BuildContext context, {
  required List<Map<String, dynamic>> productos,
  /// Stock por producto (unidad base). Se usa para mostrar y filtrar.
  Map<int, double> stockPorProducto = const {},
  bool stockFilter = false,
  bool multiple = true,
  String initialQuery = '',
  String title = 'Buscar productos',
}) {
  return showModalBottomSheet<List<ProductoSeleccion>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _PickerSheet(
      productos: productos,
      stockPorProducto: stockPorProducto,
      stockFilter: stockFilter,
      multiple: multiple,
      initialQuery: initialQuery,
      title: title,
    ),
  );
}

class _PickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> productos;
  final Map<int, double> stockPorProducto;
  final bool stockFilter;
  final bool multiple;
  final String initialQuery;
  final String title;
  const _PickerSheet({
    required this.productos,
    required this.stockPorProducto,
    required this.stockFilter,
    required this.multiple,
    required this.initialQuery,
    required this.title,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late final TextEditingController _texto = TextEditingController(text: widget.initialQuery);
  final _stockHasta = TextEditingController();
  bool _mostrarFiltros = false;
  // '' = sin filtro (el select no admite null como opción).
  String _categoria = '';
  String _subCategoria = '';
  String _marca = '';
  String _subMarca = '';
  String _stockEstado = '';

  /// Marcados: producto_id → true. Unidad y cantidad elegidas por producto.
  final Set<int> _marcados = {};
  final Map<int, int?> _unidad = {};
  final Map<int, TextEditingController> _cantidad = {};

  @override
  void initState() {
    super.initState();
    // Plegados: seis desplegables tapaban la lista, que es a lo que se viene.
    // El botón de filtros lleva una insignia con cuántos hay activos.
    _mostrarFiltros = false;
  }

  @override
  void dispose() {
    _texto.dispose();
    _stockHasta.dispose();
    for (final c in _cantidad.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[áàä]'), 'a')
      .replaceAll(RegExp('[éèë]'), 'e')
      .replaceAll(RegExp('[íìï]'), 'i')
      .replaceAll(RegExp('[óòö]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u');

  /// Opciones únicas de una relación (categoria, marca…) de los productos.
  List<AppSelectOption<String>> _opcionesDe(String clave, {String? padreClave, String? padreId}) {
    final mapa = <String, String>{};
    for (final p in widget.productos) {
      if (padreClave != null && padreId != null && padreId.isNotEmpty && '${(p[padreClave] as Map?)?['id']}' != padreId) continue;
      final rel = p[clave] as Map?;
      if (rel?['id'] != null) mapa['${rel!['id']}'] = rel['nombre']?.toString() ?? '';
    }
    final lista = mapa.entries.map((e) => AppSelectOption<String>(e.key, e.value)).toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return lista;
  }

  double _stockDe(Map p) => widget.stockPorProducto[p['id']] ?? 0;

  List<Map<String, dynamic>> get _filtrados {
    final q = _norm(_texto.text.trim());
    final partes = q.isEmpty ? const <String>[] : q.split(RegExp(r'\s+'));
    final hasta = double.tryParse(_stockHasta.text.trim());
    return widget.productos.where((p) {
      if (_categoria.isNotEmpty && '${(p['categoria'] as Map?)?['id']}' != _categoria) return false;
      if (_subCategoria.isNotEmpty && '${(p['sub_categoria'] as Map?)?['id']}' != _subCategoria) return false;
      if (_marca.isNotEmpty && '${(p['marca'] as Map?)?['id']}' != _marca) return false;
      if (_subMarca.isNotEmpty && '${(p['sub_marca'] as Map?)?['id']}' != _subMarca) return false;

      if (widget.stockFilter && (_stockEstado.isNotEmpty || hasta != null)) {
        final stock = _stockDe(p);
        final minimo = double.tryParse('${p['stock_minimo'] ?? 0}') ?? 0;
        final maximo = double.tryParse('${p['stock_maximo'] ?? 0}') ?? 0;
        // "Bajo/sobre" solo aplican si el producto tiene ese umbral definido.
        if (_stockEstado == 'sin' && stock > 0) return false;
        if (_stockEstado == 'con' && stock <= 0) return false;
        if (_stockEstado == 'bajo' && !(minimo > 0 && stock < minimo)) return false;
        if (_stockEstado == 'sobre' && !(maximo > 0 && stock > maximo)) return false;
        // "Stock hasta 10" = de 10 hacia abajo, incluyendo 0.
        if (hasta != null && stock > hasta) return false;
      }

      if (partes.isEmpty) return true;
      final heno = _norm([
        p['nombre'],
        p['codigo'],
        p['codigo_barras'],
        p['descripcion'],
        (p['marca'] as Map?)?['nombre'],
        (p['sub_marca'] as Map?)?['nombre'],
        (p['categoria'] as Map?)?['nombre'],
        (p['sub_categoria'] as Map?)?['nombre'],
      ].where((x) => x != null).join(' '));
      return partes.every(heno.contains);
    }).toList();
  }

  int get _filtrosActivos =>
      [_categoria, _subCategoria, _marca, _subMarca, _stockEstado].where((x) => x.isNotEmpty).length +
      (_stockHasta.text.trim().isEmpty ? 0 : 1);

  void _limpiarFiltros() => setState(() {
    _categoria = '';
    _subCategoria = '';
    _marca = '';
    _subMarca = '';
    _stockEstado = '';
    _stockHasta.clear();
  });

  List<Map> _presentacionesDe(Map p) =>
      ((p['presentaciones'] as List?) ?? []).whereType<Map>().where((x) => x['activo'] != false).toList();

  TextEditingController _cantCtrl(int productoId) => _cantidad.putIfAbsent(productoId, () => TextEditingController(text: '1'));

  void _toggle(Map<String, dynamic> p) {
    final id = p['id'] as int;
    final pres = _presentacionesDe(p);
    setState(() {
      if (_marcados.contains(id)) {
        _marcados.remove(id);
      } else {
        if (!widget.multiple) _marcados.clear();
        _marcados.add(id);
        _unidad[id] ??= pres.length == 1 ? pres.first['id'] as int : (pres.isNotEmpty ? pres.first['id'] as int : null);
        _cantCtrl(id);
      }
    });
  }

  void _confirmar() {
    final resultado = <ProductoSeleccion>[];
    for (final p in widget.productos) {
      final id = p['id'] as int;
      if (!_marcados.contains(id)) continue;
      final presId = _unidad[id];
      final pres = _presentacionesDe(p).cast<Map<String, dynamic>?>().firstWhere((x) => x?['id'] == presId, orElse: () => null);
      final cant = double.tryParse(_cantCtrl(id).text.trim()) ?? 0;
      if (pres == null || cant <= 0) continue;
      resultado.add(ProductoSeleccion(producto: p, presentacion: pres, cantidad: cant));
    }
    Navigator.pop(context, resultado);
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;
    final activos = _filtrosActivos;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.92,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textStrong),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),

              // Buscador + botón de filtros
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _texto,
                        autofocus: widget.initialQuery.isNotEmpty,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Nombre, código, barras, marca…',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _texto.text.isEmpty
                              ? null
                              : IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(_texto.clear)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Badge(
                      isLabelVisible: activos > 0,
                      label: Text('$activos'),
                      child: IconButton.filledTonal(
                        tooltip: 'Filtros',
                        isSelected: _mostrarFiltros,
                        icon: const Icon(Icons.tune),
                        onPressed: () => setState(() => _mostrarFiltros = !_mostrarFiltros),
                      ),
                    ),
                  ],
                ),
              ),

              if (_mostrarFiltros)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    spacing: 10,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppSelect<String>(
                              label: 'Categoría',
                              value: _categoria,
                              options: [const AppSelectOption('', 'Todas'), ..._opcionesDe('categoria')],
                              onChanged: (v) => setState(() {
                                _categoria = v ?? '';
                                _subCategoria = '';
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppSelect<String>(
                              label: 'Sub-categoría',
                              value: _subCategoria,
                              options: [
                                const AppSelectOption('', 'Todas'),
                                ..._opcionesDe('sub_categoria', padreClave: 'categoria', padreId: _categoria),
                              ],
                              onChanged: (v) => setState(() => _subCategoria = v ?? ''),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AppSelect<String>(
                              label: 'Marca',
                              value: _marca,
                              options: [const AppSelectOption('', 'Todas'), ..._opcionesDe('marca')],
                              onChanged: (v) => setState(() {
                                _marca = v ?? '';
                                _subMarca = '';
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppSelect<String>(
                              label: 'Sub-marca',
                              value: _subMarca,
                              options: [
                                const AppSelectOption('', 'Todas'),
                                ..._opcionesDe('sub_marca', padreClave: 'marca', padreId: _marca),
                              ],
                              onChanged: (v) => setState(() => _subMarca = v ?? ''),
                            ),
                          ),
                        ],
                      ),
                      if (widget.stockFilter)
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: AppSelect<String>(
                                label: 'Stock',
                                value: _stockEstado,
                                options: const [
                                  AppSelectOption('', 'Todos'),
                                  AppSelectOption('sin', 'Sin stock (0)'),
                                  AppSelectOption('con', 'Con stock'),
                                  AppSelectOption('bajo', 'Bajo el mínimo'),
                                  AppSelectOption('sobre', 'Sobre el máximo'),
                                ],
                                onChanged: (v) => setState(() => _stockEstado = v ?? ''),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _stockHasta,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Stock hasta',
                                  hintText: 'N',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (activos > 0)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _limpiarFiltros,
                            icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                            label: const Text('Limpiar filtros'),
                          ),
                        ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('${lista.length} producto${lista.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const Spacer(),
                    if (_marcados.isNotEmpty)
                      Text('${_marcados.length} seleccionado${_marcados.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Divider(height: 12),

              Expanded(
                child: lista.isEmpty
                    ? const Center(child: Text('Sin productos que coincidan', style: TextStyle(color: AppColors.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: lista.length,
                        itemBuilder: (context, i) => _fila(lista[i]),
                      ),
              ),

              // Pie: agregar seleccionados
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                child: Row(
                  children: [
                    Expanded(child: SecondaryButton(label: 'Cancelar', onPressed: () => Navigator.pop(context))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: _marcados.isEmpty ? 'Agregar' : 'Agregar (${_marcados.length})',
                        icon: Icons.add,
                        onPressed: _marcados.isEmpty ? null : _confirmar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fila(Map<String, dynamic> p) {
    final id = p['id'] as int;
    final marcado = _marcados.contains(id);
    final pres = _presentacionesDe(p);
    final stock = _stockDe(p);
    final abrev = (p['unidad_medida'] as Map?)?['abreviatura']?.toString() ?? '';
    final subt = [
      p['codigo'],
      (p['marca'] as Map?)?['nombre'],
      (p['categoria'] as Map?)?['nombre'],
    ].where((x) => x != null && '$x'.isNotEmpty).join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: marcado ? AppColors.primary.withValues(alpha: 0.06) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: marcado ? AppColors.primary : AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _toggle(p),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(value: marcado, onChanged: (_) => _toggle(p), visualDensity: VisualDensity.compact),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // A una línea cada uno: con nombres largos la fila
                        // crecía y la lista quedaba desalineada.
                        Text(
                          p['nombre']?.toString() ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (subt.isNotEmpty)
                          Text(
                            subt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.stockPorProducto.isNotEmpty)
                    AppBadge(
                      '${_fmt(stock)}${abrev.isEmpty ? '' : ' $abrev'}',
                      type: stock <= 0 ? AppBadgeType.danger : AppBadgeType.neutral,
                    ),
                ],
              ),
              if (marcado)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: AppSelect<int>(
                          label: 'Unidad',
                          value: _unidad[id],
                          options: [for (final x in pres) AppSelectOption<int>(x['id'] as int, x['nombre']?.toString() ?? '')],
                          onChanged: (v) => setState(() => _unidad[id] = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _cantCtrl(id),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(labelText: 'Cant.'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
