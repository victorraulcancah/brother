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

/// Marcas y sus sub-marcas en una sola pantalla con pestañas, igual que la web
/// (las sub-marcas ya no tienen entrada propia en el menú).
class MarcasScreen extends StatefulWidget {
  const MarcasScreen({super.key});

  @override
  State<MarcasScreen> createState() => _MarcasScreenState();
}

class _MarcasScreenState extends State<MarcasScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crudMarcas;
  late final CrudService _crudSub;

  List<Map<String, dynamic>> _marcas = [];
  List<Map<String, dynamic>> _subMarcas = [];
  bool _loading = true;
  String? _error;

  /// 0 = marcas, 1 = sub-marcas.
  int _tab = 0;

  String _busqueda = '';
  String? _filtroEstado;
  String _busquedaSub = '';
  String? _filtroSubMarca;

  @override
  void initState() {
    super.initState();
    _crudMarcas = CrudService(_api, ApiEndpoints.marcas);
    _crudSub = CrudService(_api, ApiEndpoints.subMarcas);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Future.wait([_crudMarcas.getAll(), _crudSub.getAll()]);
      _marcas = r[0];
      _subMarcas = r[1];
    } catch (_) {
      _error = 'No se pudieron cargar las marcas.';
    }
    if (mounted) setState(() => _loading = false);
  }

  // ─────────────────────────── Marcas ───────────────────────────

  List<Map<String, dynamic>> get _marcasVisibles {
    final q = _busqueda.trim().toLowerCase();
    return _marcas.where((m) {
      if (_filtroEstado == 'activos' && m['activo'] != true) return false;
      if (_filtroEstado == 'inactivos' && m['activo'] == true) return false;
      if (q.isEmpty) return true;
      return '${m['nombre']}'.toLowerCase().contains(q);
    }).toList();
  }

  int _subMarcasDe(Map<String, dynamic> m) {
    final subs = m['sub_marcas'];
    if (subs is List) return subs.length;
    // Si la marca no trae el conteo, se cuenta desde la lista cargada.
    return _subMarcas.where((s) {
      final id = s['marca'] is Map ? (s['marca'] as Map)['id'] : s['marca_id'];
      return id == m['id'];
    }).length;
  }

  Future<void> _openMarcaForm({Map<String, dynamic>? item}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva marca' : 'Editar marca',
      child: _MarcaFormSheet(initial: item),
    );
    if (result == null) return;
    try {
      if (item != null) {
        await _crudMarcas.update(item['id'], result);
      } else {
        await _crudMarcas.create(result);
      }
      await _load();
      if (mounted) {
        showAppSnackbar(context, item == null ? 'Marca creada' : 'Marca actualizada', type: AppSnackbarType.success);
      }
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  Future<void> _deleteMarca(Map<String, dynamic> item) async {
    final ok = await showAppConfirmDialog(context, title: 'Eliminar marca', message: '¿Eliminar "${item['nombre']}"?');
    if (!ok) return;
    try {
      await _crudMarcas.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Marca eliminada', type: AppSnackbarType.error);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  // ───────────────────────── Sub-marcas ─────────────────────────

  String _marcaNombre(Map<String, dynamic> item) {
    if (item['marca'] is Map) return (item['marca'] as Map)['nombre']?.toString() ?? '';
    final match = _marcas.firstWhere((m) => m['id'] == item['marca_id'], orElse: () => const {});
    return match['nombre']?.toString() ?? '';
  }

  List<Map<String, dynamic>> get _subVisibles {
    final q = _busquedaSub.trim().toLowerCase();
    return _subMarcas.where((sm) {
      final marcaId = sm['marca'] is Map ? (sm['marca'] as Map)['id']?.toString() : sm['marca_id']?.toString();
      if (_filtroSubMarca != null && marcaId != _filtroSubMarca) return false;
      if (q.isEmpty) return true;
      return '${sm['nombre']} ${_marcaNombre(sm)}'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openSubForm({Map<String, dynamic>? item}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva sub-marca' : 'Editar sub-marca',
      child: _SubMarcaFormSheet(initial: item, marcas: _marcas),
    );
    if (result == null) return;
    try {
      if (item != null) {
        await _crudSub.update(item['id'], result);
      } else {
        await _crudSub.create(result);
      }
      await _load();
      if (mounted) {
        showAppSnackbar(context, item == null ? 'Sub-marca creada' : 'Sub-marca actualizada', type: AppSnackbarType.success);
      }
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  Future<void> _deleteSub(Map<String, dynamic> item) async {
    final ok = await showAppConfirmDialog(context, title: 'Eliminar sub-marca', message: '¿Eliminar "${item['nombre']}"?');
    if (!ok) return;
    try {
      await _crudSub.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Sub-marca eliminada', type: AppSnackbarType.error);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  // ─────────────────────────── Build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Marcas',
      floatingActionButton: FloatingActionButton(
        onPressed: _tab == 0 ? () => _openMarcaForm() : () => _openSubForm(),
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
                  items: const ['Marcas', 'Sub-marcas'],
                  icons: const [Icons.sell_outlined, Icons.style_outlined],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                Expanded(child: _tab == 0 ? _listaMarcas() : _listaSubMarcas()),
              ],
            ),
    );
  }

  Widget _listaMarcas() {
    return Column(
      children: [
        AppListHeader(
          hintText: 'Buscar marcas...',
          searchValue: _busqueda,
          onSearch: (v) => setState(() => _busqueda = v),
          filters: [
            AppListFilter(
              label: 'Estado',
              value: _filtroEstado,
              options: const [
                AppListFilterOption(null, 'Todos'),
                AppListFilterOption('activos', 'Activas'),
                AppListFilterOption('inactivos', 'Inactivas'),
              ],
              onChanged: (v) => setState(() => _filtroEstado = v),
            ),
          ],
          activeFilters: _filtroEstado != null ? 1 : 0,
          onClearFilters: () => setState(() => _filtroEstado = null),
          resultCount: _marcasVisibles.length,
        ),
        Expanded(
          child: _marcasVisibles.isEmpty
              ? Center(child: Text(_marcas.isEmpty ? 'No hay marcas' : 'Ninguna marca coincide con la búsqueda'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _marcasVisibles.length,
                  itemBuilder: (context, index) {
                    final item = _marcasVisibles[index];
                    final activo = item['activo'] == true;
                    return DataCard(
                      title: item['nombre']?.toString() ?? '',
                      rows: [
                        DataCardRow.text('Sub-marcas', '${_subMarcasDe(item)}'),
                        DataCardRow(
                          label: 'Estado',
                          value: AppBadge(activo ? 'Activo' : 'Inactivo', type: activo ? AppBadgeType.success : AppBadgeType.danger),
                        ),
                      ],
                      actions: [
                        DataCardAction(icon: Icons.edit_outlined, color: AppColors.primary, tooltip: 'Editar', onTap: () => _openMarcaForm(item: item)),
                        DataCardAction(icon: Icons.delete_outline, color: AppColors.danger, tooltip: 'Eliminar', onTap: () => _deleteMarca(item)),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _listaSubMarcas() {
    return Column(
      children: [
        AppListHeader(
          hintText: 'Buscar sub-marcas...',
          searchValue: _busquedaSub,
          onSearch: (v) => setState(() => _busquedaSub = v),
          filters: [
            AppListFilter(
              label: 'Marca',
              value: _filtroSubMarca,
              options: [
                const AppListFilterOption(null, 'Todas las marcas'),
                for (final m in _marcas) AppListFilterOption(m['id'].toString(), m['nombre']?.toString() ?? ''),
              ],
              onChanged: (v) => setState(() => _filtroSubMarca = v),
            ),
          ],
          activeFilters: _filtroSubMarca != null ? 1 : 0,
          onClearFilters: () => setState(() => _filtroSubMarca = null),
          resultCount: _subVisibles.length,
        ),
        Expanded(
          child: _subVisibles.isEmpty
              ? Center(child: Text(_subMarcas.isEmpty ? 'No hay sub-marcas' : 'Ninguna sub-marca coincide con la búsqueda'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subVisibles.length,
                  itemBuilder: (context, index) {
                    final item = _subVisibles[index];
                    final activo = item['activo'] == true;
                    return DataCard(
                      title: item['nombre']?.toString() ?? '',
                      rows: [
                        DataCardRow.text('Marca', _marcaNombre(item)),
                        DataCardRow(
                          label: 'Estado',
                          value: AppBadge(activo ? 'Activo' : 'Inactivo', type: activo ? AppBadgeType.success : AppBadgeType.danger),
                        ),
                      ],
                      actions: [
                        DataCardAction(icon: Icons.edit_outlined, color: AppColors.primary, tooltip: 'Editar', onTap: () => _openSubForm(item: item)),
                        DataCardAction(icon: Icons.delete_outline, color: AppColors.danger, tooltip: 'Eliminar', onTap: () => _deleteSub(item)),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════ Formulario de marca ═══════════════════════

class _MarcaFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _MarcaFormSheet({this.initial});

  @override
  State<_MarcaFormSheet> createState() => _MarcaFormSheetState();
}

class _MarcaFormSheetState extends State<_MarcaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _logo;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _logo = TextEditingController(text: widget.initial?['logo'] ?? '');
    _activo = widget.initial?['activo'] == true || widget.initial == null;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _logo.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final logo = _logo.text.trim();
    Navigator.pop(context, {
      'nombre': _nombre.text.trim(),
      'logo': logo.isEmpty ? null : logo,
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
            title: 'Datos de la marca',
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.sell_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null,
              ),
              AppTextField(controller: _logo, label: 'Logo (URL)', icon: Icons.image_outlined),
              AppToggle(label: 'Activo', value: _activo, onChanged: (v) => setState(() => _activo = v)),
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

// ═══════════════════════ Formulario de sub-marca ═══════════════════════

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
    final opciones = widget.marcas.map((m) => AppSelectOption<int>(m['id'] as int, m['nombre']?.toString() ?? '')).toList();

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
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null,
              ),
              AppToggle(label: 'Activo', value: _activo, onChanged: (v) => setState(() => _activo = v)),
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
