import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
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

class SolicitudesCompraScreen extends StatefulWidget {
  const SolicitudesCompraScreen({super.key});

  @override
  State<SolicitudesCompraScreen> createState() => _SolicitudesCompraScreenState();
}

class _SolicitudesCompraScreenState extends State<SolicitudesCompraScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.solicitudes);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _items = await _crud.getAll(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context, title: item == null ? 'Nueva solicitud' : 'Editar solicitud',
      child: _SolicitudFormSheet(initial: item),
    );
    if (result == null) return;
    try {
      if (index != null) { await _crud.update(item!['id'], result); }
      else { await _crud.create(result); }
      await _load();
      if (mounted) showAppSnackbar(context, item == null ? 'Solicitud creada' : 'Solicitud actualizada', type: AppSnackbarType.success);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(context, title: 'Eliminar solicitud', message: '¿Eliminar "${item['codigo']}"?');
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Solicitud eliminada', type: AppSnackbarType.error);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  String _estadoLabel(String estado) => switch (estado) {
    'pendiente' => 'Pendiente', 'aprobada' => 'Aprobada', 'rechazada' => 'Rechazada', _ => estado,
  };

  AppBadgeType _estadoType(String estado) => switch (estado) {
    'aprobada' => AppBadgeType.success, 'rechazada' => AppBadgeType.danger, _ => AppBadgeType.warning,
  };

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Solicitudes de compra',
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty ? const Center(child: Text('No hay solicitudes'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final estado = item['estado'] as String? ?? '';
                return DataCard(
                  title: item['codigo'] as String? ?? '',
                  rows: [
                    DataCardRow.text('Fecha', item['fecha_solicitud'] as String? ?? ''),
                    DataCardRow(label: 'Estado', value: AppBadge(_estadoLabel(estado), type: _estadoType(estado))),
                  ],
                  actions: [
                    DataCardAction(icon: Icons.edit_outlined, color: AppColors.primary, tooltip: 'Editar', onTap: () => _openForm(item: item, index: index)),
                    DataCardAction(icon: Icons.delete_outline, color: AppColors.danger, tooltip: 'Eliminar', onTap: () => _delete(index)),
                  ],
                );
              },
            ),
    );
  }
}

class _SolicitudFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _SolicitudFormSheet({this.initial});

  @override
  State<_SolicitudFormSheet> createState() => _SolicitudFormSheetState();
}

class _SolicitudFormSheetState extends State<_SolicitudFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _observaciones;
  String _estado = 'pendiente';

  @override
  void initState() {
    super.initState();
    _codigo = TextEditingController(text: widget.initial?['codigo'] ?? '');
    _observaciones = TextEditingController(text: widget.initial?['observaciones'] ?? '');
    _estado = widget.initial?['estado'] as String? ?? 'pendiente';
  }

  @override
  void dispose() { _codigo.dispose(); _observaciones.dispose(); super.dispose(); }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'codigo': _codigo.text.trim(),
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
          AppFormSection(title: 'Datos de la solicitud', children: [
            AppTextField(controller: _codigo, label: 'Código', icon: Icons.tag, validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el código' : null),
            AppSelect<String>(label: 'Estado', icon: Icons.flag_outlined, value: _estado, options: const [AppSelectOption('pendiente', 'Pendiente'), AppSelectOption('aprobada', 'Aprobada'), AppSelectOption('rechazada', 'Rechazada')], onChanged: (v) => setState(() => _estado = v ?? 'pendiente')),
            AppTextArea(controller: _observaciones, label: 'Observaciones'),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: SecondaryButton(label: 'Cancelar', onPressed: () => Navigator.pop(context))),
            const SizedBox(width: 12),
            Expanded(child: PrimaryButton(label: 'Guardar', onPressed: _guardar)),
          ]),
        ],
      ),
    );
  }
}
