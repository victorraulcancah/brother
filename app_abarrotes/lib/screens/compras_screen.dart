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
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';
import '../widgets/recepcionar_compra_sheet.dart';
import 'crear_compra_screen.dart';

String _money(dynamic v) =>
    'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';

/// Etiqueta y color de cada estado de compra, igual que en la web.
({String label, AppBadgeType type}) _estadoInfo(String? estado) =>
    switch (estado) {
      'parcial' => (label: 'Recepción parcial', type: AppBadgeType.warning),
      'recepcionada' => (label: 'Recepcionada', type: AppBadgeType.info),
      'anulada' => (label: 'Anulada', type: AppBadgeType.danger),
      _ => (label: 'Registrada', type: AppBadgeType.success),
    };

const _docLabel = {
  'factura': 'Factura',
  'boleta': 'Boleta',
  'guia': 'Guía',
};

class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
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
    _crud = CrudService(_api, ApiEndpoints.compras);
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
      _error = 'No se pudieron cargar las compras.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((c) {
      if (_filtroEstado != null && c['estado'] != _filtroEstado) return false;
      if (q.isEmpty) return true;
      final prov = (c['proveedor'] as Map?)?['nombre'] ?? '';
      return '${c['numero_compra']} ${c['serie']}-${c['numero']} $prov'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  Future<void> _nueva() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CrearCompraScreen()),
    );
    if (ok == true) _load();
  }

  Future<void> _editar(Map<String, dynamic> item) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CrearCompraScreen(compraId: item['id'] as int),
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _anular(Map<String, dynamic> item) async {
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Anular compra',
      message: '¿Anular la compra ${item['numero_compra'] ?? ''}?',
    );
    if (!confirmado) return;
    try {
      await _api.post(ApiEndpoints.compraAnular(item['id']), body: {});
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Compra anulada',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  Future<void> _recepcionar(Map<String, dynamic> item) async {
    final ok = await showAppModal<bool>(
      context,
      title: 'Recepcionar ${item['numero_compra'] ?? ''}',
      child: RecepcionarCompraSheet(compraId: item['id'] as int),
    );
    if (ok != true) return;
    await _load();
    if (mounted) {
      showAppSnackbar(
        context,
        'Recepción registrada',
        type: AppSnackbarType.success,
      );
    }
  }

  Future<void> _finalizar(Map<String, dynamic> item) async {
    final motivo = await showAppModal<String>(
      context,
      title: 'Finalizar ${item['numero_compra'] ?? ''}',
      child: const _MotivoFinalizacionSheet(),
    );
    if (motivo == null) return;
    try {
      await _api.post(
        ApiEndpoints.compraFinalizar(item['id']),
        body: {'motivo': motivo},
      );
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Compra finalizada: se cerró lo pendiente',
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
    final confirmado = await showAppConfirmDialog(
      context,
      title: 'Eliminar compra',
      message:
          '¿Eliminar la compra ${item['numero_compra'] ?? ''}? '
          'Se eliminarán también sus pagos.',
    );
    if (!confirmado) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) {
        showAppSnackbar(
          context,
          'Compra eliminada',
          type: AppSnackbarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  /// Detalle de productos de la compra, con lo recibido y lo pendiente.
  Future<void> _verDetalle(Map<String, dynamic> item) async {
    final detalles = ((item['detalles'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();

    await showAppModal<void>(
      context,
      title: 'Detalle ${item['numero_compra'] ?? ''}',
      child: detalles.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Esta compra no tiene productos.')),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final d in detalles) _detalleCard(d),
              ],
            ),
    );
  }

  Widget _detalleCard(Map<String, dynamic> d) {
    final pres = d['presentacion'] as Map<String, dynamic>?;
    final producto = pres?['producto'] as Map<String, dynamic>?;
    final pendiente = double.tryParse('${d['pendiente'] ?? 0}') ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              producto?['nombre']?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${producto?['codigo'] ?? '-'} · ${pres?['nombre'] ?? '-'}'
              '${producto?['marca'] is Map ? ' · ${producto!['marca']['nombre']}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _dato('Cant.', '${d['cantidad']}'),
                _dato('Costo', _money(d['costo_unitario'])),
                _dato('Subtotal', _money(d['subtotal'])),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _dato('Recibido', '${d['recibido'] ?? 0}'),
                _dato(
                  'Pendiente',
                  '${d['pendiente'] ?? 0}',
                  color: pendiente > 0 ? AppColors.warning : null,
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato(String label, String valor, {Color? color}) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        Text(
          valor,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Compras',
      floatingActionButton: FloatingActionButton(
        onPressed: _nueva,
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
                  hintText: 'Buscar compras...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Estado',
                      value: _filtroEstado,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('registrada', 'Registrada'),
                        AppListFilterOption('parcial', 'Recepción parcial'),
                        AppListFilterOption('recepcionada', 'Recepcionada'),
                        AppListFilterOption('anulada', 'Anulada'),
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
                                ? 'No hay compras'
                                : 'Ninguna compra coincide con la búsqueda',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _visibles.length,
                          itemBuilder: (context, index) {
                            final item = _visibles[index];
                            final prov = item['proveedor'] as Map?;
                            final estado = item['estado']?.toString();
                            final anulada = estado == 'anulada';
                            final finalizada = item['finalizado'] == true;
                            final recepcionada = estado == 'recepcionada';
                            final contado = item['forma_pago'] == 'contado';
                            final info = _estadoInfo(estado);

                            return DataCard(
                              title:
                                  '${item['numero_compra'] ?? '#${item['id']}'} · '
                                  '${prov?['nombre'] ?? 'Sin proveedor'}',
                              onTap: () => _verDetalle(item),
                              rows: [
                                DataCardRow.text(
                                  'Documento',
                                  '${_docLabel[item['tipo_documento']] ?? item['tipo_documento'] ?? ''} '
                                  '${item['serie'] ?? ''}-${item['numero'] ?? ''}',
                                ),
                                DataCardRow.text(
                                  'Fecha',
                                  '${item['fecha'] ?? '—'}'.split('T').first,
                                ),
                                DataCardRow.text(
                                  'Ítems',
                                  '${item['detalles_count'] ?? (item['detalles'] as List?)?.length ?? 0}',
                                ),
                                DataCardRow(
                                  label: 'Pago',
                                  value: AppBadge(
                                    contado ? 'Contado' : 'Crédito',
                                    type: contado
                                        ? AppBadgeType.success
                                        : AppBadgeType.warning,
                                  ),
                                ),
                                DataCardRow.text('Total', _money(item['total'])),
                                DataCardRow(
                                  label: 'Estado',
                                  value: AppBadge(info.label, type: info.type),
                                ),
                                if (finalizada)
                                  DataCardRow(
                                    label: 'Finalización',
                                    value: AppBadge(
                                      'Finalizada',
                                      type: AppBadgeType.info,
                                    ),
                                  ),
                              ],
                              actions: [
                                if (!anulada && !recepcionada && !finalizada)
                                  DataCardAction(
                                    icon: Icons.inventory_outlined,
                                    color: AppColors.success,
                                    tooltip: 'Recepcionar',
                                    onTap: () => _recepcionar(item),
                                  ),
                                if (!anulada && !recepcionada && !finalizada)
                                  DataCardAction(
                                    icon: Icons.check_circle_outline,
                                    color: AppColors.info,
                                    tooltip: 'Finalizar',
                                    onTap: () => _finalizar(item),
                                  ),
                                if (!anulada)
                                  DataCardAction(
                                    icon: Icons.edit_outlined,
                                    color: AppColors.primary,
                                    tooltip: 'Editar',
                                    onTap: () => _editar(item),
                                  ),
                                if (!anulada)
                                  DataCardAction(
                                    icon: Icons.block,
                                    color: AppColors.warning,
                                    tooltip: 'Anular',
                                    onTap: () => _anular(item),
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

/// Pide el motivo por el que se cierra lo pendiente de recibir.
class _MotivoFinalizacionSheet extends StatefulWidget {
  const _MotivoFinalizacionSheet();

  @override
  State<_MotivoFinalizacionSheet> createState() =>
      _MotivoFinalizacionSheetState();
}

class _MotivoFinalizacionSheetState extends State<_MotivoFinalizacionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppMessage(
            text:
                'Lo que falte por recibir quedará registrado como cantidad '
                'finalizada y la compra ya no admitirá más recepciones.',
            type: AppMessageType.error,
          ),
          const SizedBox(height: 12),
          AppFormSection(
            title: 'Motivo',
            children: [
              AppTextField(
                controller: _motivo,
                label: 'Motivo de finalización',
                icon: Icons.edit_note_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Indique el motivo'
                    : null,
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
                child: PrimaryButton(
                  label: 'Finalizar',
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    Navigator.pop(context, _motivo.text.trim());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
