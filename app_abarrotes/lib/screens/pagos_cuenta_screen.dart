import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';

const List<AppSelectOption<String>> kFormasPago = [
  AppSelectOption('efectivo', 'Efectivo'),
  AppSelectOption('transferencia', 'Transferencia'),
  AppSelectOption('tarjeta', 'Tarjeta'),
  AppSelectOption('yape', 'Yape'),
  AppSelectOption('plin', 'Plin'),
  AppSelectOption('otro', 'Otro'),
];

String _formaLabel(String? v) =>
    kFormasPago.firstWhere((f) => f.value == v, orElse: () => const AppSelectOption('otro', 'Otro')).label;

String _money(dynamic v) => 'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';
double _num(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
String _hoy() => DateTime.now().toIso8601String().substring(0, 10);

class _PagoLinea {
  String forma = 'efectivo';
  final TextEditingController monto = TextEditingController();
  final TextEditingController referencia = TextEditingController();
  void dispose() {
    monto.dispose();
    referencia.dispose();
  }
}

/// Pantalla reutilizable para gestionar los pagos de una cuenta por cobrar o pagar.
/// Soporta registrar pagos mixtos, editar y anular. Devuelve `true` al salir si hubo cambios.
class PagosCuentaScreen extends StatefulWidget {
  final Map<String, dynamic> cuenta;
  final String apiPath; // 'cuentas-por-cobrar' | 'cuentas-por-pagar'
  final bool esCobrar;

  const PagosCuentaScreen({
    super.key,
    required this.cuenta,
    required this.apiPath,
    required this.esCobrar,
  });

  @override
  State<PagosCuentaScreen> createState() => _PagosCuentaScreenState();
}

class _PagosCuentaScreenState extends State<PagosCuentaScreen> {
  final ApiService _api = ApiService();
  late Map<String, dynamic> _cuenta;
  final List<_PagoLinea> _lineas = [_PagoLinea()];
  bool _saving = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _cuenta = Map<String, dynamic>.from(widget.cuenta);
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
        'pagos': validos
            .map((l) => {
                  'forma_pago': l.forma,
                  'monto': _num(l.monto.text),
                  'referencia': l.referencia.text.trim().isEmpty ? null : l.referencia.text.trim(),
                })
            .toList(),
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
      builder: (_) => _EditarPagoDialog(apiPath: widget.apiPath, pago: pago),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Aún no hay pagos registrados', textAlign: TextAlign.center),
                  )
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
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          cell('Total', _money(_cuenta['monto_total']), Colors.black87),
          cell('Pagado', _money(_cuenta['monto_pagado']), Colors.green.shade700),
          cell('Saldo', _money(_cuenta['saldo']), Colors.red.shade700),
        ],
      ),
    );
  }

  Widget _pagoTile(Map<String, dynamic> p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AppBadge(_formaLabel(p['forma_pago'] as String?), type: AppBadgeType.info),
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
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.primary,
              onPressed: _saving ? null : () => _editar(p),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: AppColors.danger,
              onPressed: _saving ? null : () => _anular(p),
              tooltip: 'Anular',
            ),
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
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AppSelect<String>(
                    label: 'Forma',
                    value: l.forma,
                    options: kFormasPago,
                    onChanged: (v) => setState(() => l.forma = v ?? 'efectivo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
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
                  onPressed: _lineas.length == 1
                      ? null
                      : () => setState(() => _lineas.removeAt(i).dispose()),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _lineas.add(_PagoLinea())),
            icon: const Icon(Icons.add),
            label: const Text('Agregar forma'),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('A pagar: ${_money(_nuevoTotal)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            if (_nuevoTotal > _saldo + 0.01)
              Text('excede el saldo', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
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
  const _EditarPagoDialog({required this.apiPath, required this.pago});

  @override
  State<_EditarPagoDialog> createState() => _EditarPagoDialogState();
}

class _EditarPagoDialogState extends State<_EditarPagoDialog> {
  final ApiService _api = ApiService();
  late String _forma;
  late final TextEditingController _monto;
  late final TextEditingController _ref;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _forma = widget.pago['forma_pago'] as String? ?? 'efectivo';
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
        'forma_pago': _forma,
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSelect<String>(
            label: 'Forma',
            value: _forma,
            options: kFormasPago,
            onChanged: (v) => setState(() => _forma = v ?? 'efectivo'),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _monto,
            label: 'Monto',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 8),
          AppTextField(controller: _ref, label: 'Referencia'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        PrimaryButton(label: 'Guardar', loading: _saving, onPressed: _guardar),
      ],
    );
  }
}
