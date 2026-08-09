import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';

class UnidadesScreen extends StatefulWidget {
  const UnidadesScreen({super.key});

  @override
  State<UnidadesScreen> createState() => _UnidadesScreenState();
}

class _UnidadesScreenState extends State<UnidadesScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.unidades);
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
      _error = 'No se pudieron cargar las unidades.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items
        .where(
          (u) => '${u['nombre']} ${u['abreviatura']}'.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nueva unidad' : 'Editar unidad',
      child: _UnidadFormSheet(initial: item),
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
          item == null ? 'Unidad creada' : 'Unidad actualizada',
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
      title: 'Eliminar unidad',
      message: '¿Eliminar "${item['nombre']}"?',
    );
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Unidad eliminada',
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
      title: 'Unidades de Medida',
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
                  hintText: 'Buscar unidades...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(
                          child: Text(
                            _items.isEmpty ? 'No hay unidades' : 'Ninguna unidad coincide con la busqueda',
                          ),
                        )
                      : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _visibles.length,
              itemBuilder: (context, index) {
                final item = _visibles[index];
                return DataCard(
                  title: item['nombre'] as String,
                  rows: [
                    DataCardRow.text(
                      'Abreviatura',
                      item['abreviatura'] as String? ?? '',
                    ),
                    DataCardRow.text(
                      'Factor base',
                      '${item['factor_base'] ?? 1}',
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

class _UnidadFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _UnidadFormSheet({this.initial});

  @override
  State<_UnidadFormSheet> createState() => _UnidadFormSheetState();
}

class _UnidadFormSheetState extends State<_UnidadFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _abreviatura;
  late final TextEditingController _factorBase;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
    _abreviatura = TextEditingController(text: widget.initial?['abreviatura'] ?? '');
    _factorBase = TextEditingController(text: '${widget.initial?['factor_base'] ?? '1'}');
  }

  @override
  void dispose() {
    _nombre.dispose();
    _abreviatura.dispose();
    _factorBase.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nombre': _nombre.text.trim(),
      'abreviatura': _abreviatura.text.trim(),
      'factor_base': double.tryParse(_factorBase.text.trim()) ?? 1,
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
            title: 'Datos de la unidad',
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.straighten,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppTextField(
                controller: _abreviatura,
                label: 'Abreviatura',
                icon: Icons.short_text,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese la abreviatura'
                    : null,
              ),
              AppTextField(
                controller: _factorBase,
                label: 'Equivale a (en su unidad mínima)',
                icon: Icons.calculate_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
