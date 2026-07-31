import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_tabs.dart';
import '../widgets/app_text_field.dart';

/// Existencias por almacén: una pestaña por almacén (+ Todos), cada una
/// con la tabla de productos y su stock. Los almacenes se gestionan con
/// los botones de la barra superior (crear / editar / desactivar).
class AlmacenesScreen extends StatefulWidget {
  const AlmacenesScreen({super.key});

  @override
  State<AlmacenesScreen> createState() => _AlmacenesScreenState();
}

class _AlmacenesScreenState extends State<AlmacenesScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _almacenes = [];
  List<Map<String, dynamic>> _existencias = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.almacenes);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _almacenes = await _crud.getAll();
      final ex = await _api.get(ApiEndpoints.existencias);
      _existencias = ex is List
          ? ex.whereType<Map<String, dynamic>>().toList()
          : [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _nuevo() async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: 'Nuevo almacén',
      child: const _AlmacenFormSheet(),
    );
    if (result == null) return;
    try {
      await _crud.create(result);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Almacén creado',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  Future<void> _editar() async {
    if (_almacenes.isEmpty) return;
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: 'Editar almacén',
      child: _EditarAlmacenSheet(almacenes: _almacenes),
    );
    if (result == null) return;
    final id = result.remove('id');
    try {
      await _crud.update(id, result);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Almacén actualizado',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  Future<void> _desactivar() async {
    if (_almacenes.isEmpty) return;
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: 'Desactivar almacén',
      child: _DesactivarSheet(almacenes: _almacenes),
    );
    if (result == null) return;
    final id = result['id'];
    try {
      await _crud.update(id, {
        'nombre': result['nombre'],
        'codigo': result['codigo'],
        'tipo': result['tipo'],
        'direccion': result['direccion'],
        'activo': false,
      });
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Almacén desactivado',
          type: AppSnackbarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  Widget _list(int? almacenId) {
    final items = _existencias.where((e) {
      if (almacenId == null) return true;
      if (e['almacen_id'] == almacenId) return true;
      return e['almacen'] is Map && (e['almacen'] as Map)['id'] == almacenId;
    }).toList();

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Sin existencias en este almacén',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surface),
          columnSpacing: 22,
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textStrong,
          ),
          columns: const [
            DataColumn(label: Text('Código')),
            DataColumn(label: Text('Producto — Presentación')),
            DataColumn(label: Text('Categoría')),
            DataColumn(label: Text('Stock (unidad base)')),
            DataColumn(label: Text('Precio Venta')),
          ],
          rows: [for (final e in items) _fila(e)],
        ),
      ),
    );
  }

  DataRow _fila(Map<String, dynamic> e) {
    final pres = e['presentacion'] is Map ? e['presentacion'] as Map : const {};
    final prod = pres['producto'] is Map ? pres['producto'] as Map : const {};
    final stock = (e['stock_actual'] as num?)?.toDouble() ?? 0;
    final categoria = prod['categoria'] is Map
        ? (prod['categoria'] as Map)['nombre']?.toString() ?? ''
        : '';
    final presentacionNombre = pres['nombre']?.toString() ?? '';
    final prodUnidad = prod['unidad_base'] is Map
        ? (prod['unidad_base'] as Map)['abreviatura']?.toString() ?? ''
        : '';
    final presUnidad = pres['unidad_base'] is Map
        ? (pres['unidad_base'] as Map)['abreviatura']?.toString() ?? ''
        : '';
    final unidad = presUnidad.isNotEmpty ? presUnidad : prodUnidad;

    final stockStr = stock == stock.roundToDouble()
        ? '${stock.toInt()}'
        : stock.toStringAsFixed(2);

    return DataRow(
      cells: [
        DataCell(Text(prod['codigo']?.toString() ?? '')),
        DataCell(Text('${prod['nombre']?.toString() ?? ''} — $presentacionNombre')),
        DataCell(
          categoria.isEmpty
              ? const Text('—', style: TextStyle(color: AppColors.textMuted))
              : AppBadge(categoria, type: AppBadgeType.neutral),
        ),
        DataCell(
          AppBadge(
            '$stockStr $unidad',
            type: stock <= 0
                ? AppBadgeType.danger
                : (stock <= 5 ? AppBadgeType.warning : AppBadgeType.success),
          ),
        ),
        DataCell(Text('S/ ${pres['precio_venta'] ?? prod['precio_base'] ?? ''}')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Existencias por almacén',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Nuevo almacén',
          onPressed: _nuevo,
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Editar almacén',
          onPressed: _editar,
        ),
        IconButton(
          icon: const Icon(Icons.block),
          tooltip: 'Desactivar almacén',
          onPressed: _desactivar,
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _almacenes.isEmpty
          ? const Center(
              child: Text('No hay almacenes. Crea uno con el botón +'),
            )
          : AppTabs(
              tabs: [
                for (final a in _almacenes)
                  AppTab(
                    icon: Icons.warehouse_outlined,
                    label: a['nombre']?.toString() ?? '',
                    content: _list(a['id'] as int?),
                  ),
                AppTab(icon: Icons.apps, label: 'Todos', content: _list(null)),
              ],
            ),
    );
  }
}

/// Formulario de "Nuevo almacén": nombre, código, descripción (dirección).
class _AlmacenFormSheet extends StatefulWidget {
  const _AlmacenFormSheet();

  @override
  State<_AlmacenFormSheet> createState() => _AlmacenFormSheetState();
}

class _AlmacenFormSheetState extends State<_AlmacenFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _codigo = TextEditingController();
  final _descripcion = TextEditingController();

  @override
  void dispose() {
    _nombre.dispose();
    _codigo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nombre': _nombre.text.trim(),
      'codigo': _codigo.text.trim(),
      'direccion': _descripcion.text.trim(),
      'tipo': 'principal',
      'activo': true,
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
                icon: Icons.warehouse_outlined,
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
              AppTextField(
                controller: _descripcion,
                label: 'Descripción',
                icon: Icons.notes,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AccionesFormulario(onGuardar: _guardar),
        ],
      ),
    );
  }
}

/// Formulario de "Editar almacén": select para elegir, luego nombre y
/// descripción se precargan.
class _EditarAlmacenSheet extends StatefulWidget {
  final List<Map<String, dynamic>> almacenes;

  const _EditarAlmacenSheet({required this.almacenes});

  @override
  State<_EditarAlmacenSheet> createState() => _EditarAlmacenSheetState();
}

class _EditarAlmacenSheetState extends State<_EditarAlmacenSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  Map<String, dynamic>? _seleccionado;

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _seleccionar(int? id) {
    final almacen = widget.almacenes.firstWhere(
      (a) => a['id'] == id,
      orElse: () => const {},
    );
    setState(() {
      _seleccionado = almacen.isEmpty ? null : almacen;
      _nombre.text = almacen['nombre']?.toString() ?? '';
      _descripcion.text = almacen['direccion']?.toString() ?? '';
    });
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final sel = _seleccionado!;
    Navigator.pop(context, {
      'id': sel['id'],
      'nombre': _nombre.text.trim(),
      'codigo': sel['codigo'],
      'tipo': sel['tipo'] ?? 'principal',
      'direccion': _descripcion.text.trim(),
      'activo': sel['activo'] ?? true,
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
            title: 'Editar almacén',
            children: [
              AppSelect<int>(
                label: 'Almacén',
                icon: Icons.warehouse_outlined,
                value: _seleccionado?['id'] as int?,
                options: widget.almacenes
                    .map(
                      (a) => AppSelectOption<int>(
                        a['id'] as int,
                        a['nombre']?.toString() ?? '',
                      ),
                    )
                    .toList(),
                onChanged: _seleccionar,
                validator: (v) => v == null ? 'Seleccione un almacén' : null,
              ),
              AppTextField(
                controller: _nombre,
                label: 'Nombre',
                icon: Icons.badge_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              AppTextField(
                controller: _descripcion,
                label: 'Descripción',
                icon: Icons.notes,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AccionesFormulario(onGuardar: _guardar),
        ],
      ),
    );
  }
}

/// Modal de "Desactivar almacén": aviso + select. Devuelve el almacén elegido.
class _DesactivarSheet extends StatefulWidget {
  final List<Map<String, dynamic>> almacenes;

  const _DesactivarSheet({required this.almacenes});

  @override
  State<_DesactivarSheet> createState() => _DesactivarSheetState();
}

class _DesactivarSheetState extends State<_DesactivarSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _id;

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    final almacen = widget.almacenes.firstWhere((a) => a['id'] == _id);
    Navigator.pop(context, almacen);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'El almacén se desactivará. Los productos y movimientos '
            'históricos se conservan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          AppSelect<int>(
            label: 'Almacén',
            icon: Icons.warehouse_outlined,
            value: _id,
            options: widget.almacenes
                .map(
                  (a) => AppSelectOption<int>(
                    a['id'] as int,
                    a['nombre']?.toString() ?? '',
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _id = v),
            validator: (v) => v == null ? 'Seleccione un almacén' : null,
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
                child: PrimaryButton(label: 'Confirmar', onPressed: _confirmar),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fila de botones Cancelar / Enviar reutilizada por los formularios.
class _AccionesFormulario extends StatelessWidget {
  final VoidCallback onGuardar;

  const _AccionesFormulario({required this.onGuardar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton(label: 'Enviar', onPressed: onGuardar),
        ),
      ],
    );
  }
}
