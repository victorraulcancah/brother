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

/// Compras → Solicitudes de compra. Listado en cards, crear/editar en modal.
class SolicitudesCompraScreen extends StatefulWidget {
  const SolicitudesCompraScreen({super.key});

  @override
  State<SolicitudesCompraScreen> createState() =>
      _SolicitudesCompraScreenState();
}

class _SolicitudesCompraScreenState extends State<SolicitudesCompraScreen> {
  final List<Map<String, dynamic>> _items = [
    {
      'codigo': 'SC-0001',
      'producto': 'Leche evaporada 400g',
      'cantidad': '50',
      'fecha_solicitud': '2026-07-24',
      'estado': 'pendiente',
      'observaciones': '',
    },
    {
      'codigo': 'SC-0002',
      'producto': 'Arroz 1kg',
      'cantidad': '100',
      'fecha_solicitud': '2026-07-26',
      'estado': 'aprobada',
      'observaciones': '',
    },
  ];

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva solicitud' : 'Editar solicitud',
      child: _SolicitudFormSheet(initial: item),
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
      item == null ? 'Solicitud creada' : 'Solicitud actualizada',
      type: AppSnackbarType.success,
    );
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar solicitud',
      message: '¿Eliminar la solicitud "${item['codigo']}"?',
    );
    if (!confirmado) return;

    setState(() => _items.removeAt(index));
    if (!mounted) return;
    showAppSnackbar(
      context,
      'Solicitud eliminada',
      type: AppSnackbarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Solicitudes de compra',
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
              DataCardRow.text('Producto', item['producto'] as String),
              DataCardRow.text('Cantidad', item['cantidad'] as String),
              DataCardRow.text('Fecha', item['fecha_solicitud'] as String),
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
  'aprobada' => 'Aprobada',
  'rechazada' => 'Rechazada',
  _ => estado,
};

AppBadgeType _estadoType(String estado) => switch (estado) {
  'aprobada' => AppBadgeType.success,
  'rechazada' => AppBadgeType.danger,
  _ => AppBadgeType.warning,
};

class _SolicitudFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const _SolicitudFormSheet({this.initial});

  @override
  State<_SolicitudFormSheet> createState() => _SolicitudFormSheetState();
}

class _SolicitudFormSheetState extends State<_SolicitudFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _cantidad;
  late final TextEditingController _fecha;
  late final TextEditingController _observaciones;
  String? _producto;
  String? _estado;

  static const _productos = [
    'Leche evaporada 400g',
    'Gaseosa 1.5L',
    'Arroz 1kg',
  ];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _codigo = TextEditingController(text: i?['codigo'] ?? '');
    _cantidad = TextEditingController(text: i?['cantidad'] ?? '');
    _fecha = TextEditingController(text: i?['fecha_solicitud'] ?? '');
    _observaciones = TextEditingController(text: i?['observaciones'] ?? '');
    _producto = i?['producto'] as String?;
    _estado = i?['estado'] as String? ?? 'pendiente';
  }

  @override
  void dispose() {
    _codigo.dispose();
    _cantidad.dispose();
    _fecha.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'codigo': _codigo.text.trim(),
      'producto': _producto,
      'cantidad': _cantidad.text.trim(),
      'fecha_solicitud': _fecha.text.trim(),
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
            title: 'Datos de la solicitud',
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
                label: 'Producto',
                icon: Icons.inventory_2_outlined,
                value: _producto,
                options: [for (final p in _productos) AppSelectOption(p, p)],
                onChanged: (v) => setState(() => _producto = v),
                validator: (v) => v == null ? 'Seleccione un producto' : null,
              ),
              AppTextField(
                controller: _cantidad,
                label: 'Cantidad solicitada',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese la cantidad'
                    : null,
              ),
              AppTextField(
                controller: _fecha,
                label: 'Fecha (AAAA-MM-DD)',
                icon: Icons.event_outlined,
              ),
              AppSelect<String>(
                label: 'Estado',
                icon: Icons.flag_outlined,
                value: _estado,
                options: const [
                  AppSelectOption('pendiente', 'Pendiente'),
                  AppSelectOption('aprobada', 'Aprobada'),
                  AppSelectOption('rechazada', 'Rechazada'),
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
