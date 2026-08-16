import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_segmented.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle.dart';
import '../widgets/data_card.dart';

/// Clasificación del gasto para el reporte de utilidades. Solo aplica a salidas.
const _catGasto = {
  'operativo': ('Operativo', AppBadgeType.warning),
  'compra': ('Compra (proveedor)', AppBadgeType.info),
  'no_operativo': ('No operativo', AppBadgeType.neutral),
};

/// Motivos de caja (ámbito caja), separados en Egresos e Ingresos como en la
/// web. Los del sistema no se pueden editar ni borrar.
class MotivosMovimientoScreen extends StatefulWidget {
  const MotivosMovimientoScreen({super.key});

  @override
  State<MotivosMovimientoScreen> createState() =>
      _MotivosMovimientoScreenState();
}

class _MotivosMovimientoScreenState extends State<MotivosMovimientoScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _busqueda = '';
  String? _filtroEstado;

  /// 0 = Egresos (salida), 1 = Ingresos (entrada). Mismo orden que la web.
  int _tab = 0;
  String get _tipoTab => _tab == 0 ? 'salida' : 'entrada';

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, '${ApiEndpoints.motivosMovimiento}?ambito=caja');
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await _crud.getAll();
    } catch (e) {
      _error = 'No se pudieron cargar los motivos: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((m) {
      if (m['tipo'] != _tipoTab) return false;
      if (_filtroEstado == 'activo' && m['activo'] != true) return false;
      if (_filtroEstado == 'inactivo' && m['activo'] == true) return false;
      if (q.isEmpty) return true;
      return '${m['nombre']}'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final data = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo motivo' : 'Editar motivo',
      child: _MotivoFormSheet(initial: item, tipoInicial: _tipoTab),
    );
    if (data == null) return;

    try {
      // El endpoint base para crear/editar no lleva el query de ámbito.
      final crud = CrudService(_api, ApiEndpoints.motivosMovimiento);
      if (item != null) {
        await crud.update(item['id'], data);
      } else {
        await crud.create({...data, 'ambito': 'caja'});
      }
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          item == null ? 'Motivo creado' : 'Motivo actualizado',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  Future<void> _eliminar(Map<String, dynamic> item) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Eliminar motivo',
      message:
          '¿Eliminar "${item['nombre']}"? Los movimientos que lo usen '
          'quedarán sin motivo.',
    );
    if (!ok) return;
    try {
      await CrudService(_api, ApiEndpoints.motivosMovimiento).delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(context, 'Motivo eliminado', type: AppSnackbarType.error);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Motivos de Movimiento',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AppMessage(text: _error!),
                  ),
                AppSegmented(
                  items: const ['Egresos (salida)', 'Ingresos (entrada)'],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                AppListHeader(
                  hintText: 'Buscar motivos...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Estado',
                      value: _filtroEstado,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('activo', 'Activos'),
                        AppListFilterOption('inactivo', 'Inactivos'),
                      ],
                      onChanged: (v) => setState(() => _filtroEstado = v),
                    ),
                  ],
                  activeFilters: _filtroEstado != null ? 1 : 0,
                  onClearFilters: () => setState(() => _filtroEstado = null),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(
                          child: Text(
                            _tab == 0
                                ? 'No hay motivos de egreso'
                                : 'No hay motivos de ingreso',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _visibles.length,
                          itemBuilder: (context, index) {
                            final m = _visibles[index];
                            final sistema = m['es_sistema'] == true;
                            final activo = m['activo'] == true;
                            final cat = _catGasto[m['categoria_gasto']];

                            return DataCard(
                              title: m['nombre']?.toString() ?? '',
                              rows: [
                                DataCardRow(
                                  label: 'Origen',
                                  value: AppBadge(
                                    sistema ? 'Sistema' : 'Manual',
                                    type: sistema
                                        ? AppBadgeType.info
                                        : AppBadgeType.neutral,
                                  ),
                                ),
                                if (_tipoTab == 'salida')
                                  DataCardRow(
                                    label: 'Clasificación',
                                    value: cat == null
                                        ? const Text('—')
                                        : AppBadge(cat.$1, type: cat.$2),
                                  ),
                                DataCardRow(
                                  label: 'Estado',
                                  value: AppBadge(
                                    activo ? 'Activo' : 'Inactivo',
                                    type: activo
                                        ? AppBadgeType.success
                                        : AppBadgeType.danger,
                                  ),
                                ),
                              ],
                              // Los motivos del sistema son fijos.
                              actions: sistema
                                  ? const []
                                  : [
                                      DataCardAction(
                                        icon: Icons.edit_outlined,
                                        color: AppColors.primary,
                                        tooltip: 'Editar',
                                        onTap: () => _openForm(item: m),
                                      ),
                                      DataCardAction(
                                        icon: Icons.delete_outline,
                                        color: AppColors.danger,
                                        tooltip: 'Eliminar',
                                        onTap: () => _eliminar(m),
                                      ),
                                    ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

/// Mismo formulario que la web: nombre, tipo, clasificación (solo salidas)
/// y estado. Mismo diseño de hoja que el resto de altas de la app.
class _MotivoFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final String tipoInicial;

  const _MotivoFormSheet({this.initial, required this.tipoInicial});

  @override
  State<_MotivoFormSheet> createState() => _MotivoFormSheetState();
}

class _MotivoFormSheetState extends State<_MotivoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late String _tipo;
  late String _categoria;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _nombre = TextEditingController(text: i?['nombre']?.toString() ?? '');
    _tipo = i?['tipo']?.toString() ?? widget.tipoInicial;
    _categoria = i?['categoria_gasto']?.toString() ?? 'operativo';
    _activo = i?['activo'] as bool? ?? true;
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
      'tipo': _tipo,
      // La clasificación solo tiene sentido en salidas.
      'categoria_gasto': _tipo == 'salida' ? _categoria : null,
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
            title: 'Datos del motivo',
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.label_outline,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppSelect<String>(
                label: 'Tipo',
                icon: Icons.swap_vert,
                value: _tipo,
                options: const [
                  AppSelectOption('salida', 'Salida (egreso / gasto)'),
                  AppSelectOption('entrada', 'Entrada (ingreso)'),
                ],
                onChanged: (v) => setState(() => _tipo = v ?? 'salida'),
              ),
              if (_tipo == 'salida')
                AppSelect<String>(
                  label: 'Clasificación (reporte de utilidades)',
                  icon: Icons.category_outlined,
                  value: _categoria,
                  options: const [
                    AppSelectOption(
                      'operativo',
                      'Operativo — gasto del negocio (resta utilidad)',
                    ),
                    AppSelectOption(
                      'compra',
                      'Compra — pago a proveedor (ya está en el costo)',
                    ),
                    AppSelectOption(
                      'no_operativo',
                      'No operativo — otros (no afecta utilidad)',
                    ),
                  ],
                  onChanged: (v) => setState(() => _categoria = v ?? 'operativo'),
                ),
              AppToggle(
                label: 'Motivo activo',
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
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
