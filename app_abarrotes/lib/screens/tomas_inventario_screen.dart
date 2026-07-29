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

/// Inventario → Tomas de inventario. Conteo físico vs sistema.
class TomasInventarioScreen extends StatefulWidget {
  const TomasInventarioScreen({super.key});

  @override
  State<TomasInventarioScreen> createState() => _TomasInventarioScreenState();
}

class _TomasInventarioScreenState extends State<TomasInventarioScreen> {
  final List<Map<String, dynamic>> _items = [
    {
      'fecha': '2026-07-26',
      'almacen': 'Almacén Central',
      'producto': 'Leche evaporada 400g',
      'stock_sistema': '120',
      'stock_contado': '118',
      'estado': 'cerrada',
      'observaciones': 'Faltante de 2 unidades',
    },
  ];

  int _diferencia(Map<String, dynamic> item) {
    final sistema = int.tryParse(item['stock_sistema'] as String) ?? 0;
    final contado = int.tryParse(item['stock_contado'] as String) ?? 0;
    return contado - sistema;
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva toma' : 'Editar toma',
      child: _TomaFormSheet(initial: item),
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
      item == null ? 'Toma registrada' : 'Toma actualizada',
      type: AppSnackbarType.success,
    );
  }

  Future<void> _delete(int index) async {
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar toma',
      message: '¿Eliminar esta toma de inventario?',
    );
    if (!confirmado) return;

    setState(() => _items.removeAt(index));
    if (!mounted) return;
    showAppSnackbar(context, 'Toma eliminada', type: AppSnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tomas de inventario',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final dif = _diferencia(item);
          final cerrada = item['estado'] == 'cerrada';
          return DataCard(
            title: item['producto'] as String,
            rows: [
              DataCardRow.text('Almacén', item['almacen'] as String),
              DataCardRow.text('Fecha', item['fecha'] as String),
              DataCardRow.text(
                'Stock sistema',
                item['stock_sistema'] as String,
              ),
              DataCardRow.text(
                'Stock contado',
                item['stock_contado'] as String,
              ),
              DataCardRow(
                label: 'Diferencia',
                value: AppBadge(
                  dif > 0 ? '+$dif' : '$dif',
                  type: dif == 0
                      ? AppBadgeType.success
                      : (dif > 0 ? AppBadgeType.info : AppBadgeType.danger),
                ),
              ),
              DataCardRow(
                label: 'Estado',
                value: AppBadge(
                  cerrada ? 'Cerrada' : 'En proceso',
                  type: cerrada ? AppBadgeType.success : AppBadgeType.info,
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

class _TomaFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const _TomaFormSheet({this.initial});

  @override
  State<_TomaFormSheet> createState() => _TomaFormSheetState();
}

class _TomaFormSheetState extends State<_TomaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fecha;
  late final TextEditingController _stockSistema;
  late final TextEditingController _stockContado;
  late final TextEditingController _observaciones;
  String? _almacen;
  String? _producto;
  String? _estado;

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
    _fecha = TextEditingController(text: i?['fecha'] ?? '');
    _stockSistema = TextEditingController(text: i?['stock_sistema'] ?? '');
    _stockContado = TextEditingController(text: i?['stock_contado'] ?? '');
    _observaciones = TextEditingController(text: i?['observaciones'] ?? '');
    _almacen = i?['almacen'] as String?;
    _producto = i?['producto'] as String?;
    _estado = i?['estado'] as String? ?? 'en_proceso';
  }

  @override
  void dispose() {
    _fecha.dispose();
    _stockSistema.dispose();
    _stockContado.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'fecha': _fecha.text.trim(),
      'almacen': _almacen,
      'producto': _producto,
      'stock_sistema': _stockSistema.text.trim(),
      'stock_contado': _stockContado.text.trim(),
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
            title: 'Datos de la toma',
            children: [
              AppSelect<String>(
                label: 'Almacén',
                icon: Icons.warehouse_outlined,
                value: _almacen,
                options: [for (final a in _almacenes) AppSelectOption(a, a)],
                onChanged: (v) => setState(() => _almacen = v),
                validator: (v) => v == null ? 'Seleccione un almacén' : null,
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
                controller: _fecha,
                label: 'Fecha (AAAA-MM-DD)',
                icon: Icons.event_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppFormSection(
            title: 'Conteo',
            children: [
              AppTextField(
                controller: _stockSistema,
                label: 'Stock sistema',
                icon: Icons.computer_outlined,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el stock del sistema'
                    : null,
              ),
              AppTextField(
                controller: _stockContado,
                label: 'Stock contado',
                icon: Icons.fact_check_outlined,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el stock contado'
                    : null,
              ),
              AppSelect<String>(
                label: 'Estado',
                icon: Icons.flag_outlined,
                value: _estado,
                options: const [
                  AppSelectOption('en_proceso', 'En proceso'),
                  AppSelectOption('cerrada', 'Cerrada'),
                ],
                onChanged: (v) => setState(() => _estado = v),
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
