import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/data_card.dart';
import '../widgets/pdf_viewer_sheet.dart';

String _money(dynamic v) =>
    'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';

String _fechaHora(dynamic v) {
  if (v == null) return '—';
  final d = DateTime.tryParse('$v');
  if (d == null) return '$v';
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mi = d.minute.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year} $hh:$mi';
}

String _metodoLabel(Map m) {
  final cuenta = m['cuenta_bancaria'] as Map?;
  if (cuenta != null) {
    return 'Transf. · ${cuenta['alias'] ?? cuenta['numero_cuenta'] ?? ''}';
  }
  final billetera = m['billetera'] as Map?;
  if (billetera != null) return billetera['nombre']?.toString() ?? 'Billetera';
  return 'Efectivo';
}

/// Registro de arqueos: lo esperado, lo contado y los movimientos de cada
/// apertura. Los cierres se hacen desde Mi Caja; aquí solo se consultan.
class CierresCajaScreen extends StatefulWidget {
  const CierresCajaScreen({super.key});

  @override
  State<CierresCajaScreen> createState() => _CierresCajaScreenState();
}

class _CierresCajaScreenState extends State<CierresCajaScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _busqueda = '';
  String? _filtroDiferencia;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await CrudService(_api, ApiEndpoints.cierresCaja).getAll();
    } catch (_) {
      _error = 'No se pudieron cargar los cierres de caja.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    return _items.where((c) {
      final dif = double.tryParse('${c['diferencia'] ?? 0}') ?? 0;
      if (_filtroDiferencia == 'cuadra' && dif.abs() > 0.001) return false;
      if (_filtroDiferencia == 'falta' && dif >= -0.001) return false;
      if (_filtroDiferencia == 'sobra' && dif <= 0.001) return false;

      if (q.isEmpty) return true;
      final ap = c['apertura'] as Map?;
      final caja = (ap?['caja'] as Map?)?['nombre'] ?? '';
      final cajero = (ap?['usuario'] as Map?)?['name'] ?? '';
      return '$caja $cajero'.toLowerCase().contains(q);
    }).toList();
  }

  /// Verde si cuadró; rojo si faltó dinero, ámbar si sobró.
  AppBadge _badgeDiferencia(Map<String, dynamic> c) {
    final dif = double.tryParse('${c['diferencia'] ?? 0}') ?? 0;
    if (dif.abs() < 0.001) {
      return const AppBadge('Cuadró', type: AppBadgeType.success);
    }
    return AppBadge(
      '${dif < 0 ? 'Faltó' : 'Sobró'} ${_money(dif.abs())}',
      type: dif < 0 ? AppBadgeType.danger : AppBadgeType.warning,
    );
  }

  /// Movimientos entre la apertura y el cierre.
  Future<void> _verMovimientos(Map<String, dynamic> c) async {
    List<Map<String, dynamic>> movimientos = [];
    var error = false;

    try {
      final data = await _api.get(ApiEndpoints.cierreCaja(c['id']));
      movimientos = ((data['movimientos'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    } catch (_) {
      error = true;
    }
    if (!mounted) return;

    final ap = c['apertura'] as Map?;
    await showAppModal<void>(
      context,
      title: 'Movimientos · ${(ap?['caja'] as Map?)?['nombre'] ?? ''}',
      child: error
          ? const AppMessage(text: 'No se pudieron cargar los movimientos.')
          : movimientos.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Esta apertura no tuvo movimientos.')),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        '${movimientos.length} movimientos',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      const Spacer(),
                      Text(
                        'Efectivo: ${_money((double.tryParse('${ap?['monto_inicial'] ?? 0}') ?? 0) + (double.tryParse('${c['efectivo_ingresos'] ?? 0}') ?? 0) - (double.tryParse('${c['efectivo_egresos'] ?? 0}') ?? 0))}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                for (final m in movimientos) _movimientoCard(m),
              ],
            ),
    );
  }

  Widget _movimientoCard(Map<String, dynamic> m) {
    final esIngreso = m['tipo'] == 'ingreso';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (m['motivo'] as Map?)?['nombre']?.toString() ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (m['descripcion'] != null)
                    Text(
                      m['descripcion'].toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  Text(
                    '${_fechaHora(m['fecha'])} · ${_metodoLabel(m)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${esIngreso ? '+' : '−'} ${_money(m['monto'])}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: esIngreso ? AppColors.success : AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cierres de Caja',
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
                  hintText: 'Buscar cierres...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Diferencia',
                      value: _filtroDiferencia,
                      options: const [
                        AppListFilterOption(null, 'Todas'),
                        AppListFilterOption('cuadra', 'Cuadró'),
                        AppListFilterOption('falta', 'Faltó dinero'),
                        AppListFilterOption('sobra', 'Sobró dinero'),
                      ],
                      onChanged: (v) => setState(() => _filtroDiferencia = v),
                    ),
                  ],
                  activeFilters: _filtroDiferencia != null ? 1 : 0,
                  onClearFilters: () =>
                      setState(() => _filtroDiferencia = null),
                  resultCount: _visibles.length,
                ),
                Expanded(
                  child: _visibles.isEmpty
                      ? Center(
                          child: Text(
                            _items.isEmpty
                                ? 'Todavía no hay cierres de caja'
                                : 'Ningún cierre coincide con la búsqueda',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _visibles.length,
                          itemBuilder: (context, index) {
                            final c = _visibles[index];
                            final ap = c['apertura'] as Map?;

                            return DataCard(
                              title:
                                  (ap?['caja'] as Map?)?['nombre']
                                      ?.toString() ??
                                  'Caja',
                              subtitle: (ap?['usuario'] as Map?)?['name']
                                  ?.toString(),
                              onTap: () => _verMovimientos(c),
                              actions: [
                                DataCardAction(
                                  icon: Icons.picture_as_pdf_outlined,
                                  color: AppColors.textMuted,
                                  tooltip: 'Imprimir / PDF',
                                  onTap: () => mostrarPdf(context,
                                      tipo: 'cierre-caja',
                                      id: c['id'] as int,
                                      nombre: 'Cierre #${c['id'].toString().padLeft(5, '0')}',
                                      titulo: 'Cierre de caja',
                                      formatos: const ['ticket']),
                                ),
                              ],
                              rows: [
                                DataCardRow.text(
                                  'Apertura',
                                  _fechaHora(ap?['fecha_apertura']),
                                ),
                                DataCardRow.text(
                                  'Cierre',
                                  _fechaHora(c['fecha_cierre']),
                                ),
                                DataCardRow.text(
                                  'Inicial',
                                  _money(ap?['monto_inicial']),
                                ),
                                DataCardRow.text(
                                  'Ingresos',
                                  _money(c['ingresos']),
                                ),
                                DataCardRow.text('Gastos', _money(c['egresos'])),
                                DataCardRow.text(
                                  'Esperado',
                                  _money(c['monto_sistema']),
                                ),
                                DataCardRow.text(
                                  'Contado',
                                  _money(c['monto_contado']),
                                ),
                                DataCardRow(
                                  label: 'Diferencia',
                                  value: _badgeDiferencia(c),
                                ),
                                DataCardRow.text(
                                  'Movs.',
                                  '${c['movimientos_count'] ?? 0}',
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
