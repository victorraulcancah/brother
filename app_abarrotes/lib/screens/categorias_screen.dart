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
import '../widgets/app_segmented.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle.dart';
import '../widgets/data_card.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  /// 0 = categorías raíz, 1 = sub-categorías.
  int _tab = 0;
  String _busqueda = '';
  String? _filtroNivel;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.categorias);
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
      _error = 'No se pudieron cargar las categorías.';
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Nombre de la categoría padre, si la respuesta la trae anidada.
  String? _padreDe(Map<String, dynamic> c) {
    final padre = c['padre'];
    if (padre is Map) return padre['nombre']?.toString();

    final padreId = c['categoria_padre_id'];
    if (padreId == null) return null;
    final encontrada = _items.firstWhere(
      (x) => x['id'].toString() == padreId.toString(),
      orElse: () => const {},
    );
    return encontrada['nombre']?.toString();
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((c) {
      final esRaiz = c['categoria_padre_id'] == null;
      if (_tab == 0 && !esRaiz) return false;
      if (_tab == 1 && esRaiz) return false;

      if (_filtroNivel != null && c['nivel']?.toString() != _filtroNivel) {
        return false;
      }
      if (q.isEmpty) return true;
      return '${c['nombre']} ${_padreDe(c) ?? ''}'.toLowerCase().contains(q);
    }).toList();
  }

  List<AppListFilterOption> get _niveles {
    final valores =
        _items
            .map((c) => c['nivel']?.toString())
            .where((n) => n != null && n.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return [
      const AppListFilterOption(null, 'Todos los niveles'),
      for (final n in valores) AppListFilterOption(n, 'Nivel $n'),
    ];
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva categoría' : 'Editar categoría',
      child: _CategoriaFormSheet(
        initial: item,
        categorias: _items,
        // Al crear desde la pestaña de sub-categorías se asume que lleva padre.
        forzarSubcategoria: item == null && _tab == 1,
      ),
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
          item == null ? 'Categoría creada' : 'Categoría actualizada',
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
      title: 'Eliminar categoría',
      message:
          '¿Eliminar "${item['nombre']}"? Las subcategorías asociadas podrían quedar huérfanas.',
    );
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Categoría eliminada',
          type: AppSnackbarType.error,
        );
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
      title: 'Categorías',
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
                  items: const ['Categorías', 'Sub-categorías'],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                AppListHeader(
                  hintText: 'Buscar categorías...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Nivel',
                      value: _filtroNivel,
                      options: _niveles,
                      onChanged: (v) => setState(() => _filtroNivel = v),
                    ),
                  ],
                  activeFilters: _filtroNivel != null ? 1 : 0,
                  onClearFilters: () => setState(() => _filtroNivel = null),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(
                          child: Text(
                            _tab == 0
                                ? 'No hay categorías'
                                : 'No hay sub-categorías',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _visibles.length,
                          itemBuilder: (context, index) {
                            final item = _visibles[index];
                            final activo = item['activo'] == true;
                            final padre = _padreDe(item);

                            return DataCard(
                              title: item['nombre']?.toString() ?? '',
                              rows: [
                                if (padre != null)
                                  DataCardRow.text('Categoría padre', padre),
                                DataCardRow(
                                  label: 'Nivel',
                                  value: AppBadge(
                                    'Nivel ${item['nivel'] ?? 1}',
                                    type: AppBadgeType.info,
                                  ),
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

class _CategoriaFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> categorias;
  final bool forzarSubcategoria;

  const _CategoriaFormSheet({
    this.initial,
    required this.categorias,
    this.forzarSubcategoria = false,
  });

  @override
  State<_CategoriaFormSheet> createState() => _CategoriaFormSheetState();
}

class _CategoriaFormSheetState extends State<_CategoriaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  String? _padreId;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _padreId = widget.initial?['categoria_padre_id']?.toString();
    _activo = widget.initial?['activo'] == true || widget.initial == null;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  /// El nivel se deriva del padre: raíz = 1, hija = nivel del padre + 1.
  int _nivelCalculado() {
    if (_padreId == null || _padreId!.isEmpty) return 1;
    final padre = widget.categorias.firstWhere(
      (c) => c['id'].toString() == _padreId,
      orElse: () => const {},
    );
    return (int.tryParse('${padre['nivel'] ?? 1}') ?? 1) + 1;
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nombre': _nombre.text.trim(),
      'categoria_padre_id': (_padreId?.isEmpty ?? true) ? null : _padreId,
      'nivel': _nivelCalculado(),
      'activo': _activo,
    });
  }

  @override
  Widget build(BuildContext context) {
    // Una categoría no puede ser su propio padre.
    final opciones = <AppSelectOption<String>>[
      const AppSelectOption<String>('', 'Sin padre (categoría raíz)'),
      for (final c in widget.categorias)
        if (c['id'].toString() != widget.initial?['id']?.toString())
          AppSelectOption<String>(
            c['id'].toString(),
            c['nombre']?.toString() ?? '',
          ),
    ];

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(
            title: 'Datos de la categoría',
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.category_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppSelect<String>(
                label: 'Categoría padre',
                value: _padreId,
                options: opciones,
                icon: Icons.account_tree_outlined,
                onChanged: (v) => setState(() => _padreId = v),
                validator: (v) =>
                    widget.forzarSubcategoria && (v == null || v.isEmpty)
                    ? 'Elija la categoría padre'
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
