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
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle.dart';
import '../widgets/data_card.dart';

const _tipoLabel = {
  'principal': 'Principal',
  'secundario': 'Secundario',
  'tienda': 'Tienda',
};

/// Maestro de almacenes. El stock se consulta en Existencias.
class AlmacenesScreen extends StatefulWidget {
  const AlmacenesScreen({super.key});

  @override
  State<AlmacenesScreen> createState() => _AlmacenesScreenState();
}

class _AlmacenesScreenState extends State<AlmacenesScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _busqueda = '';
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.almacenes);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await _crud.getAll();
    } catch (_) {
      _error = 'No se pudieron cargar los almacenes.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((a) {
      if (_filtroEstado == 'activos' && a['activo'] != true) return false;
      if (_filtroEstado == 'inactivos' && a['activo'] == true) return false;
      if (q.isEmpty) return true;
      return '${a['nombre']} ${a['codigo'] ?? ''} ${a['direccion'] ?? ''}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final data = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo almacén' : 'Editar almacén',
      child: _AlmacenFormSheet(initial: item),
    );
    if (data == null) return;

    try {
      if (item != null) {
        await _crud.update(item['id'], data);
      } else {
        await _crud.create(data);
      }
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          item == null ? 'Almacén creado' : 'Almacén actualizado',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  /// Explica por qué no se puede borrar y ofrece desactivarlo.
  Future<void> _avisarNoSePuedeEliminar(
    Map<String, dynamic> item,
    ApiException e,
  ) async {
    final cuerpo = e.errors ?? const {};
    final motivos = ((cuerpo['motivos'] as List?) ?? []).map((x) => '$x').toList();
    final puedeDesactivar = cuerpo['puede_desactivar'] == true;

    final desactivar = await showAppModal<bool>(
      context,
      title: 'No se puede eliminar',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.detalle, style: const TextStyle(color: AppColors.textMuted)),
          if (motivos.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Está siendo usado por',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            ...motivos.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('•  $m'),
                )),
          ],
          const SizedBox(height: 16),
          if (puedeDesactivar)
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Desactivar almacén',
                onPressed: () => Navigator.pop(context, true),
              ),
            )
          else
            const Text('Este almacén ya está desactivado.',
                style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );

    if (desactivar == true) await _cambiarActivo(item, false);
  }

  /// Desactivar no es eliminar: apaga el almacén y conserva su historial.
  Future<void> _cambiarActivo(Map<String, dynamic> item, bool activo) async {
    try {
      await _crud.update(item['id'], {
        'nombre': item['nombre'],
        'codigo': item['codigo'],
        'tipo': item['tipo'],
        'direccion': item['direccion'],
        'activo': activo,
      });
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          activo
              ? '"${item['nombre']}" está activo de nuevo.'
              : '"${item['nombre']}" quedó desactivado. Su historial se conserva.',
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
      title: 'Eliminar almacén',
      message:
          '¿Eliminar "${item['nombre']}"?\n'
          'Solo se puede si está vacío: sin stock ni movimientos. '
          'Si tiene historial, se te ofrecerá desactivarlo.',
    );
    if (!ok) return;

    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Almacén eliminado',
          type: AppSnackbarType.error,
        );
      }
    } on ApiException catch (e) {
      // 409: tiene historial. No es un fallo, es que corresponde desactivar.
      if (e.statusCode == 409 && mounted) {
        await _avisarNoSePuedeEliminar(item, e);
        return;
      }
      if (mounted) {
        showAppSnackbar(context, 'Error: ${e.detalle}', type: AppSnackbarType.error);
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
      title: 'Almacenes',
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
                AppListHeader(
                  hintText: 'Buscar almacenes...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Estado',
                      value: _filtroEstado,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('activos', 'Activos'),
                        AppListFilterOption('inactivos', 'Inactivos'),
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
                            _items.isEmpty
                                ? 'No hay almacenes'
                                : 'Ningún almacén coincide con la búsqueda',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _visibles.length,
                          itemBuilder: (context, index) {
                            final item = _visibles[index];
                            final activo = item['activo'] == true;

                            return DataCard(
                              title: item['nombre']?.toString() ?? '',
                              subtitle: item['codigo']?.toString(),
                              rows: [
                                DataCardRow.text(
                                  'Tipo',
                                  _tipoLabel[item['tipo']] ??
                                      item['tipo']?.toString() ??
                                      '—',
                                ),
                                DataCardRow.text(
                                  'Dirección',
                                  item['direccion']?.toString() ?? '—',
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
                              actions: [
                                DataCardAction(
                                  icon: Icons.edit_outlined,
                                  color: AppColors.primary,
                                  tooltip: 'Editar',
                                  onTap: () => _openForm(item: item),
                                ),
                                DataCardAction(
                                  icon: activo ? Icons.power_settings_new : Icons.power_off,
                                  color: activo ? AppColors.warning : AppColors.success,
                                  tooltip: activo ? 'Desactivar' : 'Activar',
                                  onTap: () => _cambiarActivo(item, !activo),
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
                ),
              ],
            ),
    );
  }
}

class _AlmacenFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const _AlmacenFormSheet({this.initial});

  @override
  State<_AlmacenFormSheet> createState() => _AlmacenFormSheetState();
}

class _AlmacenFormSheetState extends State<_AlmacenFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _codigo;
  late final TextEditingController _direccion;
  String _tipo = 'principal';
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _nombre = TextEditingController(text: i?['nombre'] ?? '');
    _codigo = TextEditingController(text: i?['codigo'] ?? '');
    _direccion = TextEditingController(text: i?['direccion'] ?? '');
    _tipo = i?['tipo']?.toString() ?? 'principal';
    _activo = i?['activo'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _codigo.dispose();
    _direccion.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nombre': _nombre.text.trim(),
      'codigo': _codigo.text.trim(),
      'direccion': _direccion.text.trim(),
      'tipo': _tipo,
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
            title: 'Datos del almacén',
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.store_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppTextField(
                controller: _codigo,
                label: 'Código',
                icon: Icons.tag,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el código'
                    : null,
              ),
              AppSelect<String>(
                label: 'Tipo',
                icon: Icons.category_outlined,
                value: _tipo,
                options: const [
                  AppSelectOption('principal', 'Principal'),
                  AppSelectOption('secundario', 'Secundario'),
                  AppSelectOption('tienda', 'Tienda'),
                ],
                onChanged: (v) => setState(() => _tipo = v ?? 'principal'),
              ),
              AppTextField(
                controller: _direccion,
                label: 'Dirección',
                icon: Icons.location_on_outlined,
              ),
              AppToggle(
                label: 'Activo',
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
