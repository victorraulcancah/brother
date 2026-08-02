import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_select.dart';
import 'app_text_field.dart';

/// Una línea de producto editable (presentación + cantidad + precio/costo).
class ProductLine {
  int? presentacionId;
  final TextEditingController cantidad;
  final TextEditingController precio;

  ProductLine({this.presentacionId, String cantidad = '1', String precio = '0'})
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

/// Editor reutilizable de líneas de producto para Ventas, Compras,
/// Traslados, Ajustes y Préstamos. El padre mantiene la lista `[ProductLine]`
/// y reacciona a los callbacks para recalcular totales.
class ProductLinesEditor extends StatelessWidget {
  final List<ProductLine> lines;
  final List<AppSelectOption<int>> options;
  final bool showPrice;
  final String priceLabel;
  final String qtyLabel;
  final Map<int, double>? autoPrice;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onChanged;

  const ProductLinesEditor({
    super.key,
    required this.lines,
    required this.options,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
    this.showPrice = true,
    this.priceLabel = 'Precio',
    this.qtyLabel = 'Cantidad',
    this.autoPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < lines.length; i++) ...[
          _row(i),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar producto'),
          ),
        ),
      ],
    );
  }

  Widget _row(int i) {
    final line = lines[i];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6E8F5)),
      ),
      child: Column(
        children: [
          AppSelect<int>(
            label: 'Producto',
            icon: Icons.inventory_2_outlined,
            value: line.presentacionId,
            options: options,
            onChanged: (v) {
              line.presentacionId = v;
              if (autoPrice != null && v != null && autoPrice!.containsKey(v)) {
                line.precio.text = autoPrice![v]!.toStringAsFixed(2);
              }
              onChanged();
            },
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: line.cantidad,
                  label: qtyLabel,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                ),
              ),
              if (showPrice) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextField(
                    controller: line.precio,
                    label: priceLabel,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
              IconButton(
                onPressed: lines.length == 1 ? null : () => onRemove(i),
                icon: const Icon(Icons.delete_outline),
                color: AppColors.danger,
                tooltip: 'Quitar',
              ),
            ],
          ),
          if (showPrice)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Subtotal: S/ ${line.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
