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
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _productos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.movimientos);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
      _productos = await CrudService(_api, ApiEndpoints.productos).getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context, title: item == null ? 'Nuevo movimiento' : 'Editar movimiento',
      child: _MovimientoFormSheet(initial: item, productos: _productos),
    );
    if (result == null) return;
    try {
      if (index != null) { await _crud.update(item!['id'], result); }
      else { await _crud.create(result); }
      await _load();
      if (mounted) showAppSnackbar(context, item == null ? 'Movimiento creado' : 'Movimiento actualizado', type: AppSnackbarType.success);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(context, title: 'Eliminar movimiento', message: '¿Eliminar movimiento #${item['id']}?');
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Movimiento eliminado', type: AppSnackbarType.error);
    } catch (e) { if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error); }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Movimientos de Inventario',
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty ? const Center(child: Text('No hay movimientos'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final tipo = item['tipo'] as String? ?? '';
                final esEntrada = tipo == 'entrada';
                return DataCard(
                  title: '${item['producto_nombre'] ?? ''} x ${item['cantidad']}',
                  rows: [
                    DataCardRow(label: 'Tipo', value: AppBadge(tipo, type: esEntrada ? AppBadgeType.success : AppBadgeType.danger)),
                    DataCardRow.text('Nota', item['nota'] as String? ?? ''),
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

class _MovimientoFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> productos;
  const _MovimientoFormSheet({this.initial, required this.productos});

  @override
  State<_MovimientoFormSheet> createState() => _MovimientoFormSheetState();
}

class _MovimientoFormSheetState extends State<_MovimientoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cantidad;
  late final TextEditingController _nota;
  int? _productoId;
  String _tipo = 'entrada';

  @override
  void initState() {
    super.initState();
    _productoId = widget.initial?['producto_id'] as int?;
    _cantidad = TextEditingController(text: widget.initial?['cantidad']?.toString() ?? '');
    _tipo = widget.initial?['tipo'] as String? ?? 'entrada';
    _nota = TextEditingController(text: widget.initial?['nota'] ?? '');
  }

  @override
  void dispose() { _cantidad.dispose(); _nota.dispose(); super.dispose(); }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {'producto_id': _productoId, 'cantidad': int.tryParse(_cantidad.text.trim()) ?? 0, 'tipo': _tipo, 'nota': _nota.text.trim()});
  }

  @override
  Widget build(BuildContext context) {
    final productos = widget.productos.map((p) => AppSelectOption<int>(p['id'] as int, p['nombre'] as String)).toList();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(title: 'Datos del Movimiento', children: [
            AppSelect<int>(label: 'Producto', value: _productoId, options: productos, onChanged: (v) => setState(() => _productoId = v)),
            AppTextField(controller: _cantidad, label: 'Cantidad', icon: Icons.numbers, keyboardType: TextInputType.number),
            AppSelect<String>(label: 'Tipo', value: _tipo, options: const [AppSelectOption('entrada', 'Entrada'), AppSelectOption('salida', 'Salida')], onChanged: (v) => setState(() => _tipo = v ?? 'entrada')),
            AppTextField(controller: _nota, label: 'Nota', icon: Icons.note_outlined),
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
