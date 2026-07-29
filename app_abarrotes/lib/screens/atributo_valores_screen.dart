import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';

class AtributoValoresScreen extends StatefulWidget {
  const AtributoValoresScreen({super.key});

  @override
  State<AtributoValoresScreen> createState() => _AtributoValoresScreenState();
}

class _AtributoValoresScreenState extends State<AtributoValoresScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _atributos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.atributoValores);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
      _atributos = await CrudService(_api, ApiEndpoints.atributos).getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item, int? index}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo valor' : 'Editar valor',
      child: _ValorFormSheet(initial: item, atributos: _atributos),
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
        showAppSnackbar(
          context,
          item == null ? 'Valor creado' : 'Valor actualizado',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  Future<void> _delete(int index) async {
    final item = _items[index];
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar valor',
      message: '¿Eliminar "${item['valor']}"?',
    );
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Valor eliminado',
          type: AppSnackbarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  String _atributoNombre(Map<String, dynamic> item) {
    if (item['atributo'] is Map) {
      return (item['atributo'] as Map)['nombre']?.toString() ?? '';
    }
    final id = item['atributo_id'];
    final match = _atributos.firstWhere(
      (a) => a['id'] == id,
      orElse: () => const {},
    );
    return match['nombre']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Valores de atributo',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay valores'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return DataCard(
                  title: item['valor']?.toString() ?? '',
                  rows: [
                    DataCardRow.text('Atributo', _atributoNombre(item)),
                    DataCardRow.text('Valor', item['valor']?.toString() ?? ''),
                  ],
                  actions: [
                    DataCardAction(
                      icon: Icons.edit_outlined,
                      color: AppColors.primary,
                      tooltip: 'Editar',
                      onTap: () => _openForm(item: item, index: index),
                    ),
                    DataCardAction(
                      icon: Icons.delete_outline,
                      color: AppColors.danger,
                      tooltip: 'Eliminar',
                      onTap: () => _delete(index),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _ValorFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> atributos;

  const _ValorFormSheet({this.initial, required this.atributos});

  @override
  State<_ValorFormSheet> createState() => _ValorFormSheetState();
}

class _ValorFormSheetState extends State<_ValorFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valor;
  int? _atributoId;

  @override
  void initState() {
    super.initState();
    _valor = TextEditingController(text: widget.initial?['valor'] ?? '');
    _atributoId = widget.initial?['atributo_id'] as int?;
    if (_atributoId == null && widget.initial?['atributo'] is Map) {
      _atributoId = (widget.initial!['atributo'] as Map)['id'] as int?;
    }
  }

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'atributo_id': _atributoId,
      'valor': _valor.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final opciones = widget.atributos
        .map(
          (a) => AppSelectOption<int>(
            a['id'] as int,
            a['nombre']?.toString() ?? '',
          ),
        )
        .toList();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormSection(
            title: 'Datos del valor',
            children: [
              AppSelect<int>(
                label: 'Atributo',
                icon: Icons.tune,
                value: _atributoId,
                options: opciones,
                onChanged: (v) => setState(() => _atributoId = v),
                validator: (v) => v == null ? 'Seleccione un atributo' : null,
              ),
              AppTextField(
                controller: _valor,
                label: 'Valor (ej. Rojo, XL)',
                icon: Icons.label_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingrese el valor' : null,
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
