import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_badge.dart';
import 'app_button.dart';
import 'app_search_select.dart';
import 'app_select.dart';
import 'app_snackbar.dart';
import 'app_text_field.dart';
import 'producto_picker_sheet.dart';

String _money(num n) => 'S/ ${n.toStringAsFixed(2)}';
String _fmt(num n) => n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);

/// Línea de producto de una orden / compra: producto + unidad + cantidad + precio.
class LineaProducto {
  int productoId;
  int? presentacionId;
  final TextEditingController cantidad;
  final TextEditingController precio;

  LineaProducto({required this.productoId, this.presentacionId, String cantidad = '1', String precio = '0'})
    : cantidad = TextEditingController(text: cantidad),
      precio = TextEditingController(text: precio);

  double get cant => double.tryParse(cantidad.text.trim()) ?? 0;
  double get precioVal => double.tryParse(precio.text.trim()) ?? 0;
  double get subtotal => cant * precioVal;

  void dispose() {
    cantidad.dispose();
    precio.dispose();
  }
}

/// Panel "Buscar producto" + tabla de productos agregados, equivalente móvil
/// del panel de la web en crear orden de compra / compra.
///
/// El padre es dueño de [lineas]; el panel las agrega/edita/quita y avisa con
/// [onChanged] para que recalcule totales.
class ProductoLineasPanel extends StatefulWidget {
  final List<Map<String, dynamic>> productos;
  /// Stock por producto (unidad base) para mostrar en el panel y filtrar en la lupa.
  final Map<int, double> stockPorProducto;
  final List<LineaProducto> lineas;
  final VoidCallback onChanged;
  final String priceLabel;
  /// Precio sugerido para una presentación (por defecto su precio de compra).
  final double Function(Map<String, dynamic> presentacion)? precioDe;
  /// Muestra la lupa con filtros de stock (compras) o no (ventas).
  final bool stockFilter;

  const ProductoLineasPanel({
    super.key,
    required this.productos,
    required this.lineas,
    required this.onChanged,
    this.stockPorProducto = const {},
    this.priceLabel = 'Precio',
    this.precioDe,
    this.stockFilter = true,
  });

  @override
  State<ProductoLineasPanel> createState() => _ProductoLineasPanelState();
}

class _ProductoLineasPanelState extends State<ProductoLineasPanel> {
  int? _productoId;
  int? _presentacionId;
  final _cantidad = TextEditingController(text: '1');
  final _precio = TextEditingController(text: '0');

  @override
  void dispose() {
    _cantidad.dispose();
    _precio.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _productoDe(int? id) {
    if (id == null) return null;
    for (final p in widget.productos) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  List<Map<String, dynamic>> _unidadesDe(int? productoId) => ((_productoDe(productoId)?['presentaciones'] as List?) ?? [])
      .whereType<Map<String, dynamic>>()
      .where((x) => x['activo'] != false)
      .toList();

  Map<String, dynamic>? _presentacionDe(int? productoId, int? presId) {
    for (final u in _unidadesDe(productoId)) {
      if (u['id'] == presId) return u;
    }
    return null;
  }

  double _precioSugerido(Map<String, dynamic>? pres) {
    if (pres == null) return 0;
    if (widget.precioDe != null) return widget.precioDe!(pres);
    return double.tryParse('${pres['precio_compra'] ?? 0}') ?? 0;
  }

  List<AppSearchOption<int>> get _productosOptions => [
    for (final p in widget.productos)
      AppSearchOption<int>(
        p['id'] as int,
        p['nombre']?.toString() ?? '',
        subtitle: [p['codigo'], (p['marca'] as Map?)?['nombre']].where((x) => x != null).join(' · '),
        keywords: '${p['codigo'] ?? ''} ${p['codigo_barras'] ?? ''}',
      ),
  ];

  // ── Panel ──
  void _elegirProducto(int? id) {
    final us = _unidadesDe(id);
    final presId = us.length == 1 ? us.first['id'] as int : null;
    setState(() {
      _productoId = id;
      _presentacionId = presId;
      _cantidad.text = '1';
      _precio.text = _fmt(_precioSugerido(_presentacionDe(id, presId)));
    });
  }

  void _elegirUnidad(int? presId) => setState(() {
    _presentacionId = presId;
    _precio.text = _fmt(_precioSugerido(_presentacionDe(_productoId, presId)));
  });

  void _limpiarPanel() => setState(() {
    _productoId = null;
    _presentacionId = null;
    _cantidad.text = '1';
    _precio.text = '0';
  });

  void _agregar() {
    if (_productoId == null) return showAppSnackbar(context, 'Busca y elige un producto.', type: AppSnackbarType.error);
    if (_presentacionId == null) return showAppSnackbar(context, 'Elige la unidad de medida.', type: AppSnackbarType.error);
    final cant = double.tryParse(_cantidad.text.trim()) ?? 0;
    if (cant <= 0) return showAppSnackbar(context, 'La cantidad debe ser mayor a 0.', type: AppSnackbarType.error);
    _sumar(_productoId!, _presentacionId!, cant, double.tryParse(_precio.text.trim()) ?? 0);
    _limpiarPanel();
  }

  /// Si ya existe la misma presentación se acumula en vez de duplicar la línea.
  void _sumar(int productoId, int presId, double cant, double precio) {
    final i = widget.lineas.indexWhere((l) => l.presentacionId == presId);
    if (i != -1) {
      widget.lineas[i].cantidad.text = _fmt(widget.lineas[i].cant + cant);
      widget.lineas[i].precio.text = _fmt(precio);
    } else {
      widget.lineas.add(LineaProducto(productoId: productoId, presentacionId: presId, cantidad: _fmt(cant), precio: _fmt(precio)));
    }
    widget.onChanged();
  }

  Future<void> _abrirBuscador(String query) async {
    final sel = await showProductoPicker(
      context,
      productos: widget.productos,
      stockPorProducto: widget.stockPorProducto,
      stockFilter: widget.stockFilter,
      initialQuery: query,
    );
    if (sel == null || sel.isEmpty) return;
    for (final s in sel) {
      _sumar(s.producto['id'] as int, s.presentacion['id'] as int, s.cantidad, _precioSugerido(s.presentacion));
    }
    _limpiarPanel();
    if (mounted) {
      showAppSnackbar(context, sel.length == 1 ? 'Producto agregado.' : '${sel.length} productos agregados.', type: AppSnackbarType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prod = _productoDe(_productoId);
    final stock = prod == null ? null : (widget.stockPorProducto[prod['id']] ?? 0);
    final abrev = (prod?['unidad_medida'] as Map?)?['abreviatura']?.toString() ?? '';
    final unidades = _unidadesDe(_productoId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Buscar producto ──
        AppSearchSelect<int>(
          label: 'Producto',
          hint: 'Buscar por nombre o código…',
          icon: Icons.inventory_2_outlined,
          value: _productoId,
          options: _productosOptions,
          onChanged: _elegirProducto,
          onSearch: _abrirBuscador,
          searchTooltip: 'Buscador avanzado con filtros',
        ),
        if (prod != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  prod['descripcion']?.toString().isNotEmpty == true ? prod['descripcion'].toString() : (prod['nombre']?.toString() ?? ''),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.stockPorProducto.isNotEmpty)
                AppBadge('Stock ${_fmt(stock!)}${abrev.isEmpty ? '' : ' $abrev'}', type: stock <= 0 ? AppBadgeType.danger : AppBadgeType.neutral),
            ],
          ),
        ],
        const SizedBox(height: 12),
        AppSelect<int>(
          label: 'Unidad',
          icon: Icons.straighten,
          value: _presentacionId,
          options: [for (final u in unidades) AppSelectOption<int>(u['id'] as int, u['nombre']?.toString() ?? '')],
          onChanged: _productoId == null ? null : _elegirUnidad,
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _cantidad,
                label: 'Cantidad',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppTextField(
                controller: _precio,
                label: widget.priceLabel,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PrimaryButton(label: 'Agregar producto', icon: Icons.add, onPressed: _agregar),

        // ── Productos agregados ──
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.shopping_basket_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text('Productos', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(
              '${widget.lineas.length} ${widget.lineas.length == 1 ? 'ítem agregado' : 'ítems agregados'}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.lineas.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: const Center(child: Text('Busca un producto arriba para agregarlo', style: TextStyle(color: AppColors.textMuted))),
          )
        else
          for (var i = 0; i < widget.lineas.length; i++) _lineaCard(i),
      ],
    );
  }

  Widget _lineaCard(int i) {
    final l = widget.lineas[i];
    final p = _productoDe(l.productoId);
    final unidades = _unidadesDe(l.productoId);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p?['nombre']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (p?['codigo'] != null) Text('${p!['codigo']}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar',
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                  onPressed: () {
                    widget.lineas.removeAt(i).dispose();
                    widget.onChanged();
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                children: [
                  AppSelect<int>(
                    label: 'Unidad',
                    value: l.presentacionId,
                    options: [for (final u in unidades) AppSelectOption<int>(u['id'] as int, u['nombre']?.toString() ?? '')],
                    // Cambiar la unidad trae el precio de esa presentación.
                    onChanged: (v) {
                      l.presentacionId = v;
                      l.precio.text = _fmt(_precioSugerido(_presentacionDe(l.productoId, v)));
                      widget.onChanged();
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: l.cantidad,
                          label: 'Cant.',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => widget.onChanged(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          controller: l.precio,
                          label: widget.priceLabel,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => widget.onChanged(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            Text(_money(l.subtotal), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
