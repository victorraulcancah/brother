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
import '../widgets/app_toggle.dart';
import '../widgets/data_card.dart';

String _cuentaLabel(Map c) =>
    '${c['alias'] ?? 'Cuenta'}${c['numero_cuenta'] != null ? ' · ${c['numero_cuenta']}' : ''}';

class CajasScreen extends StatefulWidget {
  const CajasScreen({super.key});

  @override
  State<CajasScreen> createState() => _CajasScreenState();
}

class _CajasScreenState extends State<CajasScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _cuentas = [];
  List<Map<String, dynamic>> _billeteras = [];
  List<Map<String, dynamic>> _usuarios = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.cajas);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _crud.getAll(),
        CrudService(_api, ApiEndpoints.cuentasBancarias).getAll(),
        CrudService(_api, ApiEndpoints.billeterasDigitales).getAll(),
        CrudService(_api, ApiEndpoints.usuarios).getAll(),
      ]);
      _items = results[0];
      _cuentas = results[1];
      _billeteras = results[2];
      _usuarios = results[3];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva caja' : 'Editar caja',
      child: _CajaFormSheet(
        initial: item,
        cuentas: _cuentas,
        billeteras: _billeteras,
        usuarios: _usuarios,
      ),
    );
    if (result == null) return;
    try {
      if (index != null) {
        await _crud.update(item!['id'], result);
      } else {
        await _crud.create(result);
      }
      await _load();
      if (mounted) {
        showAppSnackbar(context, item == null ? 'Caja creada' : 'Caja actualizada', type: AppSnackbarType.success);
      }
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final ok = await showAppConfirmDialog(context, title: 'Eliminar caja', message: '¿Eliminar "${item['nombre']}"?');
    if (!ok) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Caja eliminada', type: AppSnackbarType.error);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  String _acepta(Map item) {
    final partes = <String>[];
    if (item['acepta_efectivo'] == true) partes.add('Efectivo');
    final nc = (item['cuentas_bancarias'] as List?)?.length ?? 0;
    final nb = (item['billeteras'] as List?)?.length ?? 0;
    if (nc > 0) partes.add('$nc transferencia(s)');
    if (nb > 0) partes.add('$nb billetera(s)');
    return partes.isEmpty ? '—' : partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cajas',
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay cajas'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final activo = item['activo'] as bool? ?? true;
                final usuario = item['usuario'] as Map<String, dynamic>?;
                return DataCard(
                  title: item['nombre'] as String? ?? '',
                  rows: [
                    DataCardRow.text('Responsable', usuario?['name'] as String? ?? '—'),
                    DataCardRow.text('Acepta', _acepta(item)),
                    DataCardRow(
                      label: 'Estado',
                      value: AppBadge(activo ? 'Activa' : 'Inactiva',
                          type: activo ? AppBadgeType.success : AppBadgeType.danger),
                    ),
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

class _CajaFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> cuentas;
  final List<Map<String, dynamic>> billeteras;
  final List<Map<String, dynamic>> usuarios;
  const _CajaFormSheet({
    this.initial,
    required this.cuentas,
    required this.billeteras,
    required this.usuarios,
  });

  @override
  State<_CajaFormSheet> createState() => _CajaFormSheetState();
}

class _CajaFormSheetState extends State<_CajaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  int? _usuarioId;
  bool _aceptaEfectivo = true;
  final Set<int> _cuentasSel = {};
  final Set<int> _billeterasSel = {};
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _usuarioId = (widget.initial?['usuario'] as Map<String, dynamic>?)?['id'] as int?;
    _aceptaEfectivo = widget.initial?['acepta_efectivo'] as bool? ?? true;
    for (final c in (widget.initial?['cuentas_bancarias'] as List?) ?? []) {
      _cuentasSel.add((c as Map)['id'] as int);
    }
    for (final b in (widget.initial?['billeteras'] as List?) ?? []) {
      _billeterasSel.add((b as Map)['id'] as int);
    }
    _activo = widget.initial?['activo'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nombre': _nombre.text.trim(),
      'usuario_id': _usuarioId,
      'acepta_efectivo': _aceptaEfectivo,
      'cuentas_bancarias': _cuentasSel.toList(),
      'billeteras': _billeterasSel.toList(),
      'activo': _activo,
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
            title: 'Datos de la Caja',
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.point_of_sale_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null,
              ),
              AppSelect<int>(
                label: 'Usuario responsable (opcional)',
                icon: Icons.person_outline,
                value: _usuarioId,
                options: [
                  for (final u in widget.usuarios) AppSelectOption(u['id'] as int, u['name'] as String? ?? ''),
                ],
                onChanged: (v) => setState(() => _usuarioId = v),
              ),
              AppToggle(label: 'Activa', value: _activo, onChanged: (v) => setState(() => _activo = v)),
            ],
          ),
          const SizedBox(height: 12),
          AppFormSection(
            title: 'Métodos de pago aceptados',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Efectivo'),
                value: _aceptaEfectivo,
                onChanged: (v) => setState(() => _aceptaEfectivo = v),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 4),
                child: Align(alignment: Alignment.centerLeft, child: Text('Transferencia (cuentas bancarias)', style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
              ),
              if (widget.cuentas.isEmpty)
                const Text('No hay cuentas bancarias', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final c in widget.cuentas)
                      FilterChip(
                        label: Text(_cuentaLabel(c)),
                        selected: _cuentasSel.contains(c['id']),
                        onSelected: (sel) => setState(() {
                          final id = c['id'] as int;
                          sel ? _cuentasSel.add(id) : _cuentasSel.remove(id);
                        }),
                      ),
                  ],
                ),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: Align(alignment: Alignment.centerLeft, child: Text('Billeteras digitales', style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
              ),
              if (widget.billeteras.isEmpty)
                const Text('No hay billeteras', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final b in widget.billeteras)
                      FilterChip(
                        label: Text(b['nombre'] as String? ?? ''),
                        selected: _billeterasSel.contains(b['id']),
                        onSelected: (sel) => setState(() {
                          final id = b['id'] as int;
                          sel ? _billeterasSel.add(id) : _billeterasSel.remove(id);
                        }),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Cancelar', onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 12),
              Expanded(child: PrimaryButton(label: 'Guardar', onPressed: _guardar)),
            ],
          ),
        ],
      ),
    );
  }
}
