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

class SubMarcasScreen extends StatefulWidget {
  const SubMarcasScreen({super.key});

  @override
  State<SubMarcasScreen> createState() => _SubMarcasScreenState();
}

class _SubMarcasScreenState extends State<SubMarcasScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _marcas = [];
  bool _loading = true;
  String? _error;
  String _busqueda = '';
  String? _filtroMarca;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.subMarcas);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await _crud.getAll();
      _marcas = await CrudService(_api, ApiEndpoints.marcas).getAll();
    } catch (_) {
      _error = 'No se pudieron cargar las sub-marcas.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((sm) {
      final marcaId = (sm['marca'] is Map)
          ? sm['marca']['id']?.toString()
          : sm['marca_id']?.toString();
      if (_filtroMarca != null && marcaId != _filtroMarca) return false;
      if (q.isEmpty) return true;
      return '${sm['nombre']} ${_marcaNombre(sm)}'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva sub-marca' : 'Editar sub-marca',
      child: _SubMarcaFormSheet(initial: item, marcas: _marcas),
    );
    if (result == null) return;
    try {
      if (item != null) {
        await _crud.update(item['id'], result);
      } else {
        await _crud.create(result);
      }
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          item == null ? 'Sub-marca creada' : 'Sub-marca actualizada',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar sub-marca',
      message: '¿Eliminar "${item['nombre']}"?',
    );
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Sub-marca eliminada',
          type: AppSnackbarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  String _marcaNombre(Map<String, dynamic> item) {
    if (item['marca'] is Map) {
      return (item['marca'] as Map)['nombre']?.toString() ?? '';
    }
    final id = item['marca_id'];
    final match = _marcas.firstWhere(
      (m) => m['id'] == id,
      orElse: () => const {},
    );
    return match['nombre']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Sub-marcas',
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
                  hintText: 'Buscar sub-marcas...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Marca',
                      value: _filtroMarca,
                      options: [
                        const AppListFilterOption(null, 'Todas las marcas'),
                        for (final m in _marcas)
                          AppListFilterOption(
                            m['id'].toString(),
                            m['nombre']?.toString() ?? '',
                          ),
                      ],
                      onChanged: (v) => setState(() => _filtroMarca = v),
                    ),
                  ],
                  activeFilters: _filtroMarca != null ? 1 : 0,
                  onClearFilters: () => setState(() => _filtroMarca = null),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(
                          child: Text(
                            _items.isEmpty ? 'No hay sub-marcas' : 'Ninguna sub-marca coincide con la busqueda',
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
                  rows: [
                    DataCardRow.text('Marca', _marcaNombre(item)),
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
                      icon: Icons.delete_outline,
                      color: AppColors.danger,
                      tooltip: 'Eliminar',
                      onTap: () => _delete(item),
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

class _SubMarcaFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> marcas;

  const _SubMarcaFormSheet({this.initial, required this.marcas});

  @override
  State<_SubMarcaFormSheet> createState() => _SubMarcaFormSheetState();
}

class _SubMarcaFormSheetState extends State<_SubMarcaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  int? _marcaId;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _marcaId = widget.initial?['marca_id'] as int?;
    if (_marcaId == null && widget.initial?['marca'] is Map) {
      _marcaId = (widget.initial!['marca'] as Map)['id'] as int?;
    }
    _activo = widget.initial?['activo'] == true || widget.initial == null;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'marca_id': _marcaId,
      'nombre': _nombre.text.trim(),
      'activo': _activo,
    });
  }

  @override
  Widget build(BuildContext context) {
    final opciones = widget.marcas
        .map(
          (m) => AppSelectOption<int>(
            m['id'] as int,
            m['nombre']?.toString() ?? '',
          ),
        )
        .toList();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(
            title: 'Datos de la sub-marca',
            children: [
              AppSelect<int>(
                label: 'Marca',
                icon: Icons.sell_outlined,
                value: _marcaId,
                options: opciones,
                onChanged: (v) => setState(() => _marcaId = v),
                validator: (v) => v == null ? 'Seleccione una marca' : null,
              ),
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.label_outline,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
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
