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
import '../widgets/app_text_area.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';

/// Compras → Recepciones de compra. Ingreso de mercadería de una orden.
class RecepcionesCompraScreen extends StatefulWidget {
  const RecepcionesCompraScreen({super.key});

  @override
  State<RecepcionesCompraScreen> createState() =>
      _RecepcionesCompraScreenState();
}

class _RecepcionesCompraScreenState extends State<RecepcionesCompraScreen> {
  final List<Map<String, dynamic>> _items = [
    {
      'numero_documento': 'F001-123',
      'orden_compra': 'OC-0001',
      'almacen': 'Almacén Central',
      'producto': 'Leche evaporada 400g',
      'cantidad_recibida': '120',
      'cantidad_conforme': '118',
      'cantidad_rechazada': '2',
      'lote': 'L2026-07',
      'fecha_recepcion': '2026-07-27',
      'estado': 'completa',
      'observaciones': '2 unidades con empaque dañado',
    },
  ];

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva recepción' : 'Editar recepción',
      child: _RecepcionFormSheet(initial: item),
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
      item == null ? 'Recepción registrada' : 'Recepción actualizada',
      type: AppSnackbarType.success,
    );
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar recepción',
      message: '¿Eliminar la recepción "${item['numero_documento']}"?',
    );
    if (!confirmado) return;

    setState(() => _items.removeAt(index));
    if (!mounted) return;
    showAppSnackbar(
      context,
      'Recepción eliminada',
      type: AppSnackbarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Recepciones de compra',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return DataCard(
            title: item['numero_documento'] as String,
            rows: [
              DataCardRow.text('Orden', item['orden_compra'] as String),
              DataCardRow.text('Producto', item['producto'] as String),
              DataCardRow.text('Almacén', item['almacen'] as String),
              DataCardRow.text('Recibida', item['cantidad_recibida'] as String),
              DataCardRow(
                label: 'Estado',
                value: AppBadge(
                  _estadoLabel(item['estado'] as String),
                  type: _estadoType(item['estado'] as String),
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

String _estadoLabel(String estado) => switch (estado) {
  'pendiente' => 'Pendiente',
  'parcial' => 'Parcial',
  'completa' => 'Completa',
  _ => estado,
};

AppBadgeType _estadoType(String estado) => switch (estado) {
  'completa' => AppBadgeType.success,
  'parcial' => AppBadgeType.info,
  _ => AppBadgeType.warning,
};

class _RecepcionFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const _RecepcionFormSheet({this.initial});

  @override
  State<_RecepcionFormSheet> createState() => _RecepcionFormSheetState();
}

class _RecepcionFormSheetState extends State<_RecepcionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numeroDoc;
  late final TextEditingController _recibida;
  late final TextEditingController _conforme;
  late final TextEditingController _rechazada;
  late final TextEditingController _lote;
  late final TextEditingController _fecha;
  late final TextEditingController _observaciones;
  String? _orden;
  String? _almacen;
  String? _producto;
  String? _estado;

  static const _ordenes = ['OC-0001', 'OC-0002'];
  static const _almacenes = ['Almacén Central', 'Tienda'];
  static const _productos = [
    'Leche evaporada 400g',
    'Gaseosa 1.5L',
    'Arroz 1kg',
  ];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _numeroDoc = TextEditingController(text: i?['numero_documento'] ?? '');
    _recibida = TextEditingController(text: i?['cantidad_recibida'] ?? '');
    _conforme = TextEditingController(text: i?['cantidad_conforme'] ?? '');
    _rechazada = TextEditingController(text: i?['cantidad_rechazada'] ?? '');
    _lote = TextEditingController(text: i?['lote'] ?? '');
    _fecha = TextEditingController(text: i?['fecha_recepcion'] ?? '');
    _observaciones = TextEditingController(text: i?['observaciones'] ?? '');
    _orden = i?['orden_compra'] as String?;
    _almacen = i?['almacen'] as String?;
    _producto = i?['producto'] as String?;
    _estado = i?['estado'] as String? ?? 'pendiente';
  }

  @override
  void dispose() {
    _numeroDoc.dispose();
    _recibida.dispose();
    _conforme.dispose();
    _rechazada.dispose();
    _lote.dispose();
    _fecha.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'numero_documento': _numeroDoc.text.trim(),
      'orden_compra': _orden,
      'almacen': _almacen,
      'producto': _producto,
      'cantidad_recibida': _recibida.text.trim(),
      'cantidad_conforme': _conforme.text.trim(),
      'cantidad_rechazada': _rechazada.text.trim(),
      'lote': _lote.text.trim(),
      'fecha_recepcion': _fecha.text.trim(),
      'estado': _estado,
      'observaciones': _observaciones.text.trim(),
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
            title: 'Datos de la recepción',
            children: [
              AppTextField(
                controller: _numeroDoc,
                label: 'N° de documento',
                icon: Icons.receipt_long_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el documento'
                    : null,
              ),
              AppSelect<String>(
                label: 'Orden de compra',
                icon: Icons.assignment_outlined,
                value: _orden,
                options: [for (final o in _ordenes) AppSelectOption(o, o)],
                onChanged: (v) => setState(() => _orden = v),
                validator: (v) => v == null ? 'Seleccione una orden' : null,
              ),
              AppSelect<String>(
                label: 'Producto',
                icon: Icons.inventory_2_outlined,
                value: _producto,
                options: [for (final p in _productos) AppSelectOption(p, p)],
                onChanged: (v) => setState(() => _producto = v),
                validator: (v) => v == null ? 'Seleccione un producto' : null,
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
                controller: _fecha,
                label: 'Fecha de recepción (AAAA-MM-DD)',
                icon: Icons.event_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppFormSection(
            title: 'Cantidades',
            children: [
              AppTextField(
                controller: _recibida,
                label: 'Cantidad recibida',
                icon: Icons.download_outlined,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese la cantidad recibida'
                    : null,
              ),
              AppTextField(
                controller: _conforme,
                label: 'Cantidad conforme',
                icon: Icons.check_circle_outline,
                keyboardType: TextInputType.number,
              ),
              AppTextField(
                controller: _rechazada,
                label: 'Cantidad rechazada',
                icon: Icons.cancel_outlined,
                keyboardType: TextInputType.number,
              ),
              AppTextField(
                controller: _lote,
                label: 'Lote',
                icon: Icons.qr_code_2,
              ),
              AppSelect<String>(
                label: 'Estado',
                icon: Icons.flag_outlined,
                value: _estado,
                options: const [
                  AppSelectOption('pendiente', 'Pendiente'),
                  AppSelectOption('parcial', 'Parcial'),
                  AppSelectOption('completa', 'Completa'),
                ],
                onChanged: (v) => setState(() => _estado = v),
              ),
              AppTextArea(controller: _observaciones, label: 'Observaciones'),
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
