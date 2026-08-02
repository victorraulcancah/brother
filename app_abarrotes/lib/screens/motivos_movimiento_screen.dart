import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';

class MotivosMovimientoScreen extends StatefulWidget {
  const MotivosMovimientoScreen({super.key});

  @override
  State<MotivosMovimientoScreen> createState() => _MotivosMovimientoScreenState();
}

class _MotivosMovimientoScreenState extends State<MotivosMovimientoScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.motivosMovimiento);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _editar([Map<String, dynamic>? motivo]) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _MotivoDialog(crud: _crud, motivo: motivo),
    );
    if (ok == true) _load();
  }

  Future<void> _eliminar(Map<String, dynamic> motivo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar motivo'),
        content: Text('¿Eliminar el motivo "${motivo['nombre']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _crud.delete(motivo['id'] as int);
      await _load();
      if (mounted) showAppSnackbar(context, 'Motivo eliminado', type: AppSnackbarType.success);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Motivos de Movimiento',
      floatingActionButton: FloatingActionButton(onPressed: () => _editar(), child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay motivos'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final esEntrada = item['tipo'] == 'entrada';
                final esSistema = item['es_sistema'] == true;
                final activo = item['activo'] == true;
                return DataCard(
                  title: item['nombre'] as String? ?? '—',
                  rows: [
                    DataCardRow(
                      label: 'Tipo',
                      value: AppBadge(esEntrada ? 'Entrada' : 'Salida',
                          type: esEntrada ? AppBadgeType.success : AppBadgeType.danger),
                    ),
                    DataCardRow.text('Ámbito', '${item['ambito'] ?? '—'}'),
                    DataCardRow(
                      label: 'Estado',
                      value: AppBadge(activo ? 'Activo' : 'Inactivo',
                          type: activo ? AppBadgeType.info : AppBadgeType.neutral),
                    ),
                    if (esSistema)
                      const DataCardRow(label: 'Origen', value: AppBadge('Sistema', type: AppBadgeType.neutral)),
                  ],
                  actions: esSistema
                      ? []
                      : [
                          DataCardAction(
                            icon: Icons.edit_outlined,
                            color: AppColors.primary,
                            tooltip: 'Editar',
                            onTap: () => _editar(item),
                          ),
                          DataCardAction(
                            icon: Icons.delete_outline,
                            color: AppColors.danger,
                            tooltip: 'Eliminar',
                            onTap: () => _eliminar(item),
                          ),
                        ],
                );
              },
            ),
    );
  }
}

class _MotivoDialog extends StatefulWidget {
  final CrudService crud;
  final Map<String, dynamic>? motivo;
  const _MotivoDialog({required this.crud, this.motivo});

  @override
  State<_MotivoDialog> createState() => _MotivoDialogState();
}

class _MotivoDialogState extends State<_MotivoDialog> {
  late final TextEditingController _nombre;
  String _tipo = 'entrada';
  String _categoria = 'operativo';
  bool _activo = true;
  bool _saving = false;

  bool get _esNuevo => widget.motivo == null;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.motivo?['nombre'] as String? ?? '');
    _tipo = widget.motivo?['tipo'] as String? ?? 'entrada';
    _categoria = widget.motivo?['categoria_gasto'] as String? ?? 'operativo';
    _activo = widget.motivo?['activo'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty) {
      showAppSnackbar(context, 'Ingresa el nombre', type: AppSnackbarType.error);
      return;
    }
    setState(() => _saving = true);
    try {
      final body = {
        'nombre': _nombre.text.trim(),
        'tipo': _tipo,
        'activo': _activo,
        'ambito': 'caja',
        'categoria_gasto': _tipo == 'salida' ? _categoria : null,
      };
      if (_esNuevo) {
        await widget.crud.create(body);
      } else {
        await widget.crud.update(widget.motivo!['id'] as int, body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esNuevo ? 'Nuevo motivo' : 'Editar motivo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(controller: _nombre, label: 'Nombre', icon: Icons.label_outline),
          const SizedBox(height: 8),
          AppSelect<String>(
            label: 'Tipo',
            value: _tipo,
            options: const [
              AppSelectOption('entrada', 'Entrada (ingreso)'),
              AppSelectOption('salida', 'Salida (egreso)'),
            ],
            onChanged: (v) => setState(() => _tipo = v ?? 'entrada'),
          ),
          if (_tipo == 'salida') ...[
            const SizedBox(height: 8),
            AppSelect<String>(
              label: 'Clasificación (reporte de utilidades)',
              value: _categoria,
              options: const [
                AppSelectOption('operativo', 'Operativo (resta en utilidad)'),
                AppSelectOption('compra', 'Compra a proveedor (no resta)'),
                AppSelectOption('no_operativo', 'No operativo'),
              ],
              onChanged: (v) => setState(() => _categoria = v ?? 'operativo'),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activo'),
            value: _activo,
            onChanged: (v) => setState(() => _activo = v),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        PrimaryButton(label: 'Guardar', loading: _saving, onPressed: _guardar),
      ],
    );
  }
}
