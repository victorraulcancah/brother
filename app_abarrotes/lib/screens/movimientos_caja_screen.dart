import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_message.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/data_card.dart';

String _money(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return 'S/ ${n.toStringAsFixed(2)}';
}


class MovimientosCajaScreen extends StatefulWidget {
  const MovimientosCajaScreen({super.key});

  @override
  State<MovimientosCajaScreen> createState() => _MovimientosCajaScreenState();
}

class _MovimientosCajaScreenState extends State<MovimientosCajaScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.movimientosCaja);
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
      // Antes se tragaba el error y la lista salia como "vacia".
      _error = 'No se pudieron cargar los movimientos: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Los mapas anidados del JSON no siempre son `Map<String, dynamic>`;
  /// un cast duro ahi tumba el render de toda la lista.
  Map<String, dynamic>? _map(dynamic v) =>
      v is Map ? v.cast<String, dynamic>() : null;

  Future<void> _registrar() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegistrarMovimientoCajaScreen()),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Movimientos de Caja',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _registrar,
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Padding(padding: const EdgeInsets.all(16), child: AppMessage(text: _error!))
          : _items.isEmpty
          ? const Center(child: Text('No hay movimientos de caja'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final esIngreso = item['tipo'] == 'ingreso';
                final apertura = _map(item['apertura']);
                final caja = _map(apertura?['caja']);
                final cuenta = _map(item['cuenta_bancaria']);
                final billetera = _map(item['billetera']);
                final metodoTxt = cuenta != null
                    ? 'Transf. · ${cuenta['alias'] ?? cuenta['numero_cuenta'] ?? ''}'
                    : billetera != null
                    ? (billetera['nombre']?.toString() ?? 'Billetera')
                    : 'Efectivo';
                final motivo = _map(item['motivo']);
                return DataCard(
                  title: '${item['fecha'] ?? ''}'.split('T').first,
                  rows: [
                    DataCardRow(
                      label: 'Tipo',
                      value: AppBadge(
                        esIngreso ? 'Ingreso' : 'Egreso',
                        type: esIngreso ? AppBadgeType.success : AppBadgeType.danger,
                      ),
                    ),
                    DataCardRow.text('Caja', caja?['nombre']?.toString() ?? '—'),
                    DataCardRow.text('Motivo', motivo?['nombre']?.toString() ?? '—'),
                    DataCardRow.text('Método', metodoTxt),
                    if ((item['numero_operacion'] ?? '').toString().isNotEmpty)
                      DataCardRow.text('N° Operación', '${item['numero_operacion']}'),
                    DataCardRow.text('Monto', '${esIngreso ? '+' : '-'} ${_money(item['monto'])}'),
                  ],
                );
              },
            ),
    );
  }
}

/// Pantalla completa: envuelve la hoja del formulario en un scaffold.
class RegistrarMovimientoCajaScreen extends StatelessWidget {
  final String? tipoInicial;
  const RegistrarMovimientoCajaScreen({super.key, this.tipoInicial});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Registrar Movimiento',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RegistrarMovimientoCajaSheet(tipoInicial: tipoInicial),
      ),
    );
  }
}

/// Formulario de ingreso/egreso de caja. Sirve dentro de una pantalla o de un
/// modal: hace Navigator.pop(context, true) al guardar.
class RegistrarMovimientoCajaSheet extends StatefulWidget {
  final String? tipoInicial;

  /// En "Mi Caja" el movimiento va siempre a la caja del usuario: no se
  /// elige caja aunque sea super-admin. En "Movimientos de Caja" si.
  final bool soloMiCaja;

  const RegistrarMovimientoCajaSheet({
    super.key,
    this.tipoInicial,
    this.soloMiCaja = false,
  });

  @override
  State<RegistrarMovimientoCajaSheet> createState() => _RegistrarMovimientoCajaSheetState();
}

class _RegistrarMovimientoCajaSheetState extends State<RegistrarMovimientoCajaSheet> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  List<Map<String, dynamic>> _motivos = [];
  List<Map<String, dynamic>> _cajas = [];
  int? _miCajaId;
  bool _esSuperAdmin = false;

  /// Si se muestra el selector de caja y se usa la elegida en vez de la propia.
  bool get _eligeCaja => _esSuperAdmin && !widget.soloMiCaja;

  // Form
  late String _tipo = widget.tipoInicial ?? 'ingreso'; // ingreso | egreso
  int? _motivoId;
  int? _cajaId;
  String? _metodoTipo; // 'efectivo' | 'transferencia' | 'billetera'
  int? _cuentaId;
  int? _billeteraId;
  final _numeroOperacion = TextEditingController();
  final _monto = TextEditingController();
  final _descripcion = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _numeroOperacion.dispose();
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Cada carga va por separado: antes un Future.wait con un solo catch
    // hacia que, si fallaba /cajas o /me (p. ej. un cajero sin permiso sobre
    // /cajas), se perdieran tambien los motivos y el select saliera vacio.
    try {
      _motivos = _asList(
        await _api.get('${ApiEndpoints.motivosMovimiento}?ambito=caja'),
      );
    } catch (_) {
      _error = 'No se pudieron cargar los motivos.';
    }

    try {
      final me = await _api.get(ApiEndpoints.me);
      final mapa = me is Map<String, dynamic> ? me : <String, dynamic>{};
      _miCajaId = int.tryParse('${mapa['caja_id']}');
      final roles = (mapa['roles'] as List?)?.map((r) => (r as Map)['name']).toList() ?? [];
      _esSuperAdmin = roles.contains('super-admin');
      if (!_eligeCaja) _cajaId = _miCajaId;
    } catch (_) {
      _error ??= 'No se pudo cargar tu usuario.';
    }

    if (_eligeCaja) {
      // El admin elige entre todas las cajas.
      try {
        _cajas = _asList(await _api.get(ApiEndpoints.cajas));
      } catch (_) {
        _error ??= 'No se pudieron cargar las cajas.';
      }
    } else {
      // Con la caja fija se lee de /mi-caja, que ya trae sus metodos de pago
      // (acepta_efectivo, cuentas y billeteras). Sin esto _caja quedaba null
      // y el select de "Tipo de metodo" salia vacio.
      try {
        final mi = await _api.get(ApiEndpoints.miCaja);
        final caja = mi is Map ? mi['caja'] : null;
        if (caja is Map) {
          _cajas = [caja.cast<String, dynamic>()];
          _miCajaId ??= int.tryParse('${caja['id']}');
          _cajaId = _miCajaId;
        }
      } catch (_) {
        _error ??= 'No se pudo cargar tu caja.';
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _asList(dynamic res) {
    if (res is List) return res.cast<Map<String, dynamic>>();
    if (res is Map && res['data'] is List) return (res['data'] as List).cast<Map<String, dynamic>>();
    return [];
  }

  Map<String, dynamic>? get _caja {
    final id = _eligeCaja ? _cajaId : _miCajaId;
    if (id == null) return null;
    for (final c in _cajas) {
      if (c['id'] == id) return c;
    }
    return null;
  }

  List<Map<String, dynamic>> get _cuentasCaja =>
      ((_caja?['cuentas_bancarias'] as List?) ?? []).cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> get _billeterasCaja =>
      ((_caja?['billeteras'] as List?) ?? []).cast<Map<String, dynamic>>();

  List<AppSelectOption<String>> get _tipoOptions {
    final opts = <AppSelectOption<String>>[];
    if (_caja?['acepta_efectivo'] == true) opts.add(const AppSelectOption('efectivo', 'Efectivo'));
    if (_cuentasCaja.isNotEmpty) opts.add(const AppSelectOption('transferencia', 'Transferencia'));
    if (_billeterasCaja.isNotEmpty) opts.add(const AppSelectOption('billetera', 'Billetera digital'));
    return opts;
  }

  String _cuentaLabel(Map c) =>
      [(c['banco'] as Map?)?['nombre'], c['alias'], c['numero_cuenta']].where((e) => e != null && '$e'.isNotEmpty).join(' · ');
  String _billeteraLabel(Map b) =>
      [b['nombre'], b['titular'], b['numero_asociado']].where((e) => e != null && '$e'.isNotEmpty).join(' · ');

  bool get _reqNumOp => _metodoTipo == 'transferencia' || _metodoTipo == 'billetera';

  List<Map<String, dynamic>> get _motivosTipo {
    final t = _tipo == 'ingreso' ? 'entrada' : 'salida';
    return _motivos.where((m) => m['tipo'] == t && m['es_sistema'] != true).toList();
  }

  Future<void> _guardar() async {
    final cajaId = _eligeCaja ? _cajaId : _miCajaId;
    if (cajaId == null) {
      showAppSnackbar(context, 'No tienes una caja asignada', type: AppSnackbarType.error);
      return;
    }
    if (_motivoId == null) {
      showAppSnackbar(context, 'Selecciona el motivo', type: AppSnackbarType.error);
      return;
    }
    if (_metodoTipo == null) {
      showAppSnackbar(context, 'Selecciona el método', type: AppSnackbarType.error);
      return;
    }
    if (_metodoTipo == 'transferencia' && _cuentaId == null) {
      showAppSnackbar(context, 'Selecciona la cuenta bancaria', type: AppSnackbarType.error);
      return;
    }
    if (_metodoTipo == 'billetera' && _billeteraId == null) {
      showAppSnackbar(context, 'Selecciona la billetera', type: AppSnackbarType.error);
      return;
    }
    if ((double.tryParse(_monto.text) ?? 0) <= 0) {
      showAppSnackbar(context, 'Ingresa un monto válido', type: AppSnackbarType.error);
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.post(ApiEndpoints.movimientosCaja, body: {
        'tipo': _tipo,
        'motivo_movimiento_id': _motivoId,
        'caja_id': cajaId,
        'forma': _metodoTipo,
        'cuenta_bancaria_id': _metodoTipo == 'transferencia' ? _cuentaId : null,
        'billetera_id': _metodoTipo == 'billetera' ? _billeteraId : null,
        'numero_operacion': _numeroOperacion.text.trim().isEmpty ? null : _numeroOperacion.text.trim(),
        'monto': double.tryParse(_monto.text) ?? 0,
        'descripcion': _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
      });
      if (mounted) {
        showAppSnackbar(context, _tipo == 'ingreso' ? 'Ingreso registrado' : 'Egreso registrado',
            type: AppSnackbarType.success);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sinCaja = !_eligeCaja && _miCajaId == null;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null) ...[
                    AppMessage(text: _error!),
                    const SizedBox(height: 12),
                  ],
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'ingreso', label: Text('Ingreso'), icon: Icon(Icons.south_west)),
                      ButtonSegment(value: 'egreso', label: Text('Egreso'), icon: Icon(Icons.north_east)),
                    ],
                    selected: {_tipo},
                    onSelectionChanged: (s) => setState(() {
                      _tipo = s.first;
                      _motivoId = null; // el motivo depende del tipo
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (sinCaja)
                    const AppBadge('No tienes una caja asignada. Pide al administrador que te asigne una.',
                        type: AppBadgeType.warning)
                  else
                    AppFormSection(
                      title: 'Datos del movimiento',
                      children: [
                        if (_eligeCaja)
                          AppSelect<int>(
                            label: 'Caja',
                            icon: Icons.point_of_sale_outlined,
                            value: _cajaId,
                            options: [
                              for (final c in _cajas) AppSelectOption(c['id'] as int, c['nombre'] as String? ?? '')
                            ],
                            onChanged: (v) => setState(() {
                              _cajaId = v;
                              _metodoTipo = null; // los métodos dependen de la caja
                              _cuentaId = null;
                              _billeteraId = null;
                            }),
                          ),
                        AppSelect<int>(
                          label: 'Motivo',
                          icon: Icons.label_outline,
                          value: _motivoId,
                          options: [
                            for (final m in _motivosTipo) AppSelectOption(m['id'] as int, m['nombre'] as String? ?? '')
                          ],
                          onChanged: (v) => setState(() => _motivoId = v),
                        ),
                        AppSelect<String>(
                          label: 'Tipo de método',
                          icon: Icons.payments_outlined,
                          value: _metodoTipo,
                          options: _tipoOptions,
                          onChanged: (v) => setState(() {
                            _metodoTipo = v;
                            _cuentaId = null;
                            _billeteraId = null;
                          }),
                        ),
                        if (_metodoTipo == 'transferencia')
                          AppSelect<int>(
                            label: 'Cuenta bancaria',
                            icon: Icons.account_balance_outlined,
                            value: _cuentaId,
                            options: [
                              for (final c in _cuentasCaja) AppSelectOption(c['id'] as int, _cuentaLabel(c))
                            ],
                            onChanged: (v) => setState(() => _cuentaId = v),
                          ),
                        if (_metodoTipo == 'billetera')
                          AppSelect<int>(
                            label: 'Billetera',
                            icon: Icons.account_balance_wallet_outlined,
                            value: _billeteraId,
                            options: [
                              for (final b in _billeterasCaja) AppSelectOption(b['id'] as int, _billeteraLabel(b))
                            ],
                            onChanged: (v) => setState(() => _billeteraId = v),
                          ),
                        if (_reqNumOp)
                          AppTextField(controller: _numeroOperacion, label: 'Número de operación (opcional)', icon: Icons.tag),
                        AppTextField(
                          controller: _monto,
                          label: 'Monto',
                          icon: Icons.attach_money,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        AppTextField(controller: _descripcion, label: 'Descripción (opcional)', icon: Icons.notes),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (!sinCaja)
                    PrimaryButton(
                      label: _tipo == 'ingreso' ? 'Registrar ingreso' : 'Registrar egreso',
                      loading: _saving,
                      onPressed: _guardar,
                    ),
                ],
              );
  }
}
