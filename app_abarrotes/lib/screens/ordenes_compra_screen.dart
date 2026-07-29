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

/// Compras → Órdenes de compra. Listado en cards, crear/editar en modal.
class OrdenesCompraScreen extends StatefulWidget {
  const OrdenesCompraScreen({super.key});

  @override
  State<OrdenesCompraScreen> createState() => _OrdenesCompraScreenState();
}

class _OrdenesCompraScreenState extends State<OrdenesCompraScreen> {
  final List<Map<String, dynamic>> _items = [
    {
      'codigo': 'OC-0001',
      'proveedor': 'Distribuidora Lima S.A.C.',
      'fecha_emision': '2026-07-25',
      'moneda': 'PEN',
      'estado': 'enviada',
      'observaciones': '',
    },
    {
      'codigo': 'OC-0002',
      'proveedor': 'Alicorp S.A.A.',
      'fecha_emision': '2026-07-27',
      'moneda': 'PEN',
      'estado': 'borrador',
      'observaciones': '',
    },
  ];

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva orden' : 'Editar orden',
      child: _OrdenFormSheet(initial: item),
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
      item == null ? 'Orden creada' : 'Orden actualizada',
      type: AppSnackbarType.success,
    );
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar orden',
      message: '¿Eliminar la orden "${item['codigo']}"?',
    );
    if (!confirmado) return;

    setState(() => _items.removeAt(index));
    if (!mounted) return;
    showAppSnackbar(context, 'Orden eliminada', type: AppSnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Órdenes de compra',
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
            title: item['codigo'] as String,
            rows: [
              DataCardRow.text('Proveedor', item['proveedor'] as String),
              DataCardRow.text('Fecha', item['fecha_emision'] as String),
              DataCardRow.text('Moneda', item['moneda'] as String),
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
  'borrador' => 'Borrador',
  'enviada' => 'Enviada',
  'recibida' => 'Recibida',
  'anulada' => 'Anulada',
  _ => estado,
};

AppBadgeType _estadoType(String estado) => switch (estado) {
  'enviada' => AppBadgeType.info,
  'recibida' => AppBadgeType.success,
  'anulada' => AppBadgeType.danger,
  _ => AppBadgeType.neutral,
};

class _OrdenFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const _OrdenFormSheet({this.initial});

  @override
  State<_OrdenFormSheet> createState() => _OrdenFormSheetState();
}

class _OrdenFormSheetState extends State<_OrdenFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _fecha;
  late final TextEditingController _observaciones;
  String? _proveedor;
  String? _moneda;
  String? _estado;

  static const _proveedores = [
    'Distribuidora Lima S.A.C.',
    'Alicorp S.A.A.',
    'Gloria S.A.',
  ];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _codigo = TextEditingController(text: i?['codigo'] ?? '');
    _fecha = TextEditingController(text: i?['fecha_emision'] ?? '');
    _observaciones = TextEditingController(text: i?['observaciones'] ?? '');
    _proveedor = i?['proveedor'] as String?;
    _moneda = i?['moneda'] as String? ?? 'PEN';
    _estado = i?['estado'] as String? ?? 'borrador';
  }

  @override
  void dispose() {
    _codigo.dispose();
    _fecha.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'codigo': _codigo.text.trim(),
      'proveedor': _proveedor,
      'fecha_emision': _fecha.text.trim(),
      'moneda': _moneda,
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
            title: 'Datos de la orden',
            children: [
              AppTextField(
                controller: _codigo,
                label: 'Código',
                icon: Icons.tag,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el código'
                    : null,
              ),
              AppSelect<String>(
                label: 'Proveedor',
                icon: Icons.local_shipping_outlined,
                value: _proveedor,
                options: [for (final p in _proveedores) AppSelectOption(p, p)],
                onChanged: (v) => setState(() => _proveedor = v),
                validator: (v) => v == null ? 'Seleccione un proveedor' : null,
              ),
              AppTextField(
                controller: _fecha,
                label: 'Fecha de emisión (AAAA-MM-DD)',
                icon: Icons.event_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingrese la fecha' : null,
              ),
              AppSelect<String>(
                label: 'Moneda',
                icon: Icons.payments_outlined,
                value: _moneda,
                options: const [
                  AppSelectOption('PEN', 'Soles (PEN)'),
                  AppSelectOption('USD', 'Dólares (USD)'),
                ],
                onChanged: (v) => setState(() => _moneda = v),
              ),
              AppSelect<String>(
                label: 'Estado',
                icon: Icons.flag_outlined,
                value: _estado,
                options: const [
                  AppSelectOption('borrador', 'Borrador'),
                  AppSelectOption('enviada', 'Enviada'),
                  AppSelectOption('recibida', 'Recibida'),
                  AppSelectOption('anulada', 'Anulada'),
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
