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
import '../widgets/data_card.dart';

/// Inventario → Movimientos. Entradas y salidas de stock.
class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  final List<Map<String, dynamic>> _items = [
    {
      'tipo_movimiento': 'entrada',
      'producto': 'Leche evaporada 400g',
      'cantidad': '120',
      'almacen': 'Almacén Central',
      'origen': 'Compra OC-0001',
    },
    {
      'tipo_movimiento': 'salida',
      'producto': 'Gaseosa 1.5L',
      'cantidad': '12',
      'almacen': 'Tienda',
      'origen': 'Venta',
    },
  ];

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo movimiento' : 'Editar movimiento',
      child: _MovimientoFormSheet(initial: item),
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
      item == null ? 'Movimiento registrado' : 'Movimiento actualizado',
      type: AppSnackbarType.success,
    );
  }

  Future<void> _delete(int index) async {
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar movimiento',
      message: '¿Eliminar este movimiento?',
    );
    if (!confirmado) return;

    setState(() => _items.removeAt(index));
    if (!mounted) return;
    showAppSnackbar(
      context,
      'Movimiento eliminado',
      type: AppSnackbarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Movimientos',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final esEntrada = item['tipo_movimiento'] == 'entrada';
          return DataCard(
            title: item['producto'] as String,
            rows: [
              DataCardRow(
                label: 'Tipo',
                value: AppBadge(
                  esEntrada ? 'Entrada' : 'Salida',
                  type: esEntrada ? AppBadgeType.success : AppBadgeType.danger,
                ),
              ),
              DataCardRow.text('Cantidad', item['cantidad'] as String),
              DataCardRow.text('Almacén', item['almacen'] as String),
              DataCardRow.text('Origen', item['origen'] as String),
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

class _MovimientoFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const _MovimientoFormSheet({this.initial});

  @override
  State<_MovimientoFormSheet> createState() => _MovimientoFormSheetState();
}

class _MovimientoFormSheetState extends State<_MovimientoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cantidad;
  late final TextEditingController _origen;
  String? _tipo;
  String? _producto;
  String? _almacen;

  static const _productos = [
    'Leche evaporada 400g',
    'Gaseosa 1.5L',
    'Arroz 1kg',
  ];
  static const _almacenes = ['Almacén Central', 'Tienda'];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _cantidad = TextEditingController(text: i?['cantidad'] ?? '');
    _origen = TextEditingController(text: i?['origen'] ?? '');
    _tipo = i?['tipo_movimiento'] as String? ?? 'entrada';
    _producto = i?['producto'] as String?;
    _almacen = i?['almacen'] as String?;
  }

  @override
  void dispose() {
    _cantidad.dispose();
    _origen.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'tipo_movimiento': _tipo,
      'producto': _producto,
      'cantidad': _cantidad.text.trim(),
      'almacen': _almacen,
      'origen': _origen.text.trim(),
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
            title: 'Datos del movimiento',
            children: [
              AppSelect<String>(
                label: 'Tipo de movimiento',
                icon: Icons.swap_vert,
                value: _tipo,
                options: const [
                  AppSelectOption('entrada', 'Entrada'),
                  AppSelectOption('salida', 'Salida'),
                ],
                onChanged: (v) => setState(() => _tipo = v),
              ),
              AppSelect<String>(
                label: 'Producto',
                icon: Icons.inventory_2_outlined,
                value: _producto,
                options: [for (final p in _productos) AppSelectOption(p, p)],
                onChanged: (v) => setState(() => _producto = v),
                validator: (v) => v == null ? 'Seleccione un producto' : null,
              ),
              AppTextField(
                controller: _cantidad,
                label: 'Cantidad',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese la cantidad'
                    : null,
              ),
              AppSelect<String>(
                label: 'Almacén',
                icon: Icons.warehouse_outlined,
                value: _almacen,
                options: [for (final a in _almacenes) AppSelectOption(a, a)],
                onChanged: (v) => setState(() => _almacen = v),
                validator: (v) => v == null ? 'Seleccione un almacén' : null,
              ),
              AppTextField(
                controller: _origen,
                label: 'Origen / referencia',
                icon: Icons.description_outlined,
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
