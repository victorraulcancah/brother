import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/metodo_picker.dart';

String _money(dynamic v) => 'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';
double _num(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
String _hoy() => DateTime.now().toIso8601String().substring(0, 10);

String _metodoTxt(Map p) {
  final cuenta = p['cuenta_bancaria'] as Map<String, dynamic>?;
  final billetera = p['billetera'] as Map<String, dynamic>?;
  if (cuenta != null) return 'Transf. · ${cuenta['alias'] ?? cuenta['numero_cuenta'] ?? ''}';
  if (billetera != null) return billetera['nombre'] as String? ?? 'Billetera';
  return 'Efectivo';
}

class _PagoLinea {
  String tipo = 'efectivo';
  int? cuentaId;
  int? billeteraId;
  final TextEditingController monto = TextEditingController();
  final TextEditingController referencia = TextEditingController();
  void dispose() {
    monto.dispose();
    referencia.dispose();
  }
}

/// Pantalla de pagos de una cuenta por cobrar o pagar (registrar mixto, editar, anular).
class PagosCuentaScreen extends StatefulWidget {
  final Map<String, dynamic> cuenta;
  final String apiPath;
  final bool esCobrar;

  const PagosCuentaScreen({super.key, required this.cuenta, required this.apiPath, required this.esCobrar});

  @override
  State<PagosCuentaScreen> createState() => _PagosCuentaScreenState();
}

class _PagosCuentaScreenState extends State<PagosCuentaScreen> {
  final ApiService _api = ApiService();
  late Map<String, dynamic> _cuenta;
  List<Map<String, dynamic>> _cuentas = [];
  List<Map<String, dynamic>> _billeteras = [];
  final List<_PagoLinea> _lineas = [_PagoLinea()];
  bool _saving = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _cuenta = Map<String, dynamic>.from(widget.cuenta);
    _loadFuentes();
  }

  Future<void> _loadFuentes() async {
    try {
      final results = await Future.wait([
        CrudService(_api, ApiEndpoints.cuentasBancarias).getAll(),
        CrudService(_api, ApiEndpoints.billeterasDigitales).getAll(),
      ]);
      _cuentas = results[0];
      _billeteras = results[1];
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final l in _lineas) {
      l.dispose();
    }
    super.dispose();
  }

  List<dynamic> get _pagos => _cuenta['pagos'] as List? ?? [];
  double get _saldo => _num(_cuenta['saldo']);
  bool get _anulada => _cuenta['estado'] == 'anulado';
  bool get _puedePagar => !_anulada && _saldo > 0.005;
  double get _nuevoTotal => _lineas.fold(0, (a, l) => a + _num(l.monto.text));

  String? get _nombre {
    final ent = (widget.esCobrar ? _cuenta['cliente'] : _cuenta['proveedor']) as Map<String, dynamic>?;
    return ent?['nombre'] as String?;
  }

  void _aplicarRespuesta(Map<String, dynamic> res) {
    setState(() {
      _cuenta = res;
      _changed = true;
    });
  }

  Map<String, dynamic> _payload(_PagoLinea l) => {
        'forma_pago': l.tipo,
        'cuenta_bancaria_id': l.tipo == 'transferencia' ? l.cuentaId : null,
        'billetera_id': l.tipo == 'billetera' ? l.billeteraId : null,
        'monto': _num(l.monto.text),
        'referencia': l.referencia.text.trim().isEmpty ? null : l.referencia.text.trim(),
      };

  Future<void> _registrar() async {
    final validos = _lineas.where((l) => _num(l.monto.text) > 0).toList();
    if (validos.isEmpty) {
      showAppSnackbar(context, 'Agrega al menos un pago con monto', type: AppSnackbarType.error);
      return;
    }
    if (_nuevoTotal > _saldo + 0.01) {
      showAppSnackbar(context, 'El pago excede el saldo pendiente', type: AppSnackbarType.error);
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await _api.post('${widget.apiPath}/${_cuenta['id']}/pagos', body: {
        'fecha': _hoy(),
        'pagos': validos.map(_payload).toList(),
      });
      _aplicarRespuesta(res);
      for (final l in _lineas) {
        l.dispose();
      }
      _lineas
        ..clear()
        ..add(_PagoLinea());
      if (mounted) showAppSnackbar(context, 'Pago registrado', type: AppSnackbarType.success);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editar(Map<String, dynamic> pago) async {
    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditarPagoDialog(apiPath: widget.apiPath, pago: pago, cuentas: _cuentas, billeteras: _billeteras),
    );
    if (res != null) _aplicarRespuesta(res);
  }

  Future<void> _anular(Map<String, dynamic> pago) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular pago'),
        content: Text('¿Anular este pago de ${_money(pago['monto'])}? Se revertirá el movimiento de caja.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Anular')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      final res = await _api.delete('${widget.apiPath}/pagos/${pago['id']}');
      _aplicarRespuesta(res);
      if (mounted) showAppSnackbar(context, 'Pago anulado', type: AppSnackbarType.success);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: AppScaffold(
        title: 'Pagos — ${_nombre ?? (widget.esCobrar ? 'Cliente' : 'Proveedor')}',
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _resumen(),
            const SizedBox(height: 16),
            AppFormSection(
              title: 'Pagos registrados',
              children: [
                if (_pagos.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Aún no hay pagos registrados', textAlign: TextAlign.center))
                else
                  ..._pagos.map((p) => _pagoTile(p as Map<String, dynamic>)),
              ],
            ),
            const SizedBox(height: 16),
            if (_anulada)
              const AppBadge('Cuenta anulada', type: AppBadgeType.neutral)
            else if (!_puedePagar)
              const AppBadge('Cuenta saldada', type: AppBadgeType.success)
            else
              _formRegistrar(),
          ],
        ),
      ),
    );
  }

  Widget _resumen() {
    Widget cell(String label, String value, Color color) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        cell('Total', _money(_cuenta['monto_total']), Colors.black87),
        cell('Pagado', _money(_cuenta['monto_pagado']), Colors.green.shade700),
        cell('Saldo', _money(_cuenta['saldo']), Colors.red.shade700),
      ]),
    );
  }

  Widget _pagoTile(Map<String, dynamic> p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AppBadge(_metodoTxt(p), type: AppBadgeType.info),
          const SizedBox(width: 8),
          Text(_money(p['monto']), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${p['fecha'] ?? ''}${(p['referencia'] ?? '').toString().isNotEmpty ? ' · ${p['referencia']}' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!_anulada) ...[
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18), color: AppColors.primary, onPressed: _saving ? null : () => _editar(p), tooltip: 'Editar'),
            IconButton(icon: const Icon(Icons.delete_outline, size: 18), color: AppColors.danger, onPressed: _saving ? null : () => _anular(p), tooltip: 'Anular'),
          ],
        ],
      ),
    );
  }

  Widget _formRegistrar() {
    return AppFormSection(
      title: 'Registrar pago (mixto)',
      children: [
        ..._lineas.asMap().entries.map((e) {
          final i = e.key;
          final l = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                MetodoPicker(
                  cuentas: _cuentas,
                  billeteras: _billeteras,
                  tipo: l.tipo,
                  cuentaId: l.cuentaId,
                  billeteraId: l.billeteraId,
                  onChanged: (t, c, b) => setState(() {
                    l.tipo = t ?? 'efectivo';
                    l.cuentaId = c;
                    l.billeteraId = b;
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: l.monto,
                        label: 'Monto',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: AppColors.danger,
                      onPressed: _lineas.length == 1 ? null : () => setState(() => _lineas.removeAt(i).dispose()),
                    ),
                  ],
                ),
                AppTextField(controller: l.referencia, label: 'Referencia (opcional)'),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: () => setState(() => _lineas.add(_PagoLinea())), icon: const Icon(Icons.add), label: const Text('Agregar forma')),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('A pagar: ${_money(_nuevoTotal)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (_nuevoTotal > _saldo + 0.01) Text('excede el saldo', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        PrimaryButton(label: 'Registrar pago', loading: _saving, onPressed: _registrar),
      ],
    );
  }
}

class _EditarPagoDialog extends StatefulWidget {
  final String apiPath;
  final Map<String, dynamic> pago;
  final List<Map<String, dynamic>> cuentas;
  final List<Map<String, dynamic>> billeteras;
  const _EditarPagoDialog({required this.apiPath, required this.pago, required this.cuentas, required this.billeteras});

  @override
  State<_EditarPagoDialog> createState() => _EditarPagoDialogState();
}

class _EditarPagoDialogState extends State<_EditarPagoDialog> {
  final ApiService _api = ApiService();
  late String _tipo;
  int? _cuentaId;
  int? _billeteraId;
  late final TextEditingController _monto;
  late final TextEditingController _ref;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tipo = widget.pago['forma_pago'] as String? ?? 'efectivo';
    _cuentaId = widget.pago['cuenta_bancaria_id'] as int?;
    _billeteraId = widget.pago['billetera_id'] as int?;
    _monto = TextEditingController(text: '${widget.pago['monto'] ?? ''}');
    _ref = TextEditingController(text: '${widget.pago['referencia'] ?? ''}');
  }

  @override
  void dispose() {
    _monto.dispose();
    _ref.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_num(_monto.text) <= 0) {
      showAppSnackbar(context, 'El monto debe ser mayor a 0', type: AppSnackbarType.error);
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await _api.put('${widget.apiPath}/pagos/${widget.pago['id']}', body: {
        'forma_pago': _tipo,
        'cuenta_bancaria_id': _tipo == 'transferencia' ? _cuentaId : null,
        'billetera_id': _tipo == 'billetera' ? _billeteraId : null,
        'monto': _num(_monto.text),
        'referencia': _ref.text.trim().isEmpty ? null : _ref.text.trim(),
      });
      if (mounted) Navigator.pop(context, res);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar pago'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MetodoPicker(
              cuentas: widget.cuentas,
              billeteras: widget.billeteras,
              tipo: _tipo,
              cuentaId: _cuentaId,
              billeteraId: _billeteraId,
              onChanged: (t, c, b) => setState(() {
                _tipo = t ?? 'efectivo';
                _cuentaId = c;
                _billeteraId = b;
              }),
            ),
            const SizedBox(height: 8),
            AppTextField(controller: _monto, label: 'Monto', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 8),
            AppTextField(controller: _ref, label: 'Referencia'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        PrimaryButton(label: 'Guardar', loading: _saving, onPressed: _guardar),
      ],
    );
  }
}
