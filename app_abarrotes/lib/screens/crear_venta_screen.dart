import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_endpoints.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/metodo_picker.dart';
import '../widgets/product_lines_editor.dart';

class _Pago {
  String tipo = 'efectivo';
  int? cuentaId;
  int? billeteraId;
  final TextEditingController monto = TextEditingController();
  double get valor => double.tryParse(monto.text.trim()) ?? 0;
  void dispose() => monto.dispose();
}

class CrearVentaScreen extends StatefulWidget {
  const CrearVentaScreen({super.key});

  @override
  State<CrearVentaScreen> createState() => _CrearVentaScreenState();
}

class _CrearVentaScreenState extends State<CrearVentaScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _almacenes = [];
  List<Map<String, dynamic>> _cuentas = [];
  List<Map<String, dynamic>> _billeteras = [];
  final List<AppSelectOption<int>> _presOptions = [];
  final Map<int, double> _precioMap = {};

  int? _clienteId;
  int? _almacenId;
  String _tipoPago = 'contado';

  final List<ProductLine> _lineas = [ProductLine()];
  final List<_Pago> _pagos = [_Pago()];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final l in _lineas) {
      l.dispose();
    }
    for (final p in _pagos) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        CrudService(_api, ApiEndpoints.clientes).getAll(),
        CrudService(_api, ApiEndpoints.almacenes).getAll(),
        CrudService(_api, ApiEndpoints.productos).getAll(),
        CrudService(_api, ApiEndpoints.cuentasBancarias).getAll(),
        CrudService(_api, ApiEndpoints.billeterasDigitales).getAll(),
      ]);
      _clientes = results[0];
      _almacenes = results[1];
      _cuentas = results[3];
      _billeteras = results[4];
      for (final p in results[2]) {
        final presentaciones = p['presentaciones'] as List? ?? [];
        for (final pres in presentaciones) {
          final id = pres['id'] as int;
          _presOptions.add(AppSelectOption(id, '${p['nombre']} — ${pres['nombre']}'));
          _precioMap[id] = double.tryParse('${pres['precio_venta'] ?? 0}') ?? 0;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double get _total => _lineas.fold(0, (a, l) => a + l.subtotal);
  double get _pagado => _pagos.fold(0, (a, p) => a + p.valor);

  Future<void> _guardar() async {
    final lineasValidas = _lineas.where((l) => l.presentacionId != null && l.cant > 0).toList();
    if (lineasValidas.isEmpty) {
      showAppSnackbar(context, 'Agrega al menos un producto', type: AppSnackbarType.error);
      return;
    }
    if (_almacenId == null) {
      showAppSnackbar(context, 'Selecciona el almacén', type: AppSnackbarType.error);
      return;
    }
    if (_tipoPago == 'credito' && _clienteId == null) {
      showAppSnackbar(context, 'Para crédito debes elegir un cliente', type: AppSnackbarType.error);
      return;
    }

    final vendedorId = context.read<AuthProvider>().user?.id;
    final fecha = DateTime.now().toIso8601String().substring(0, 10);

    final detalles = lineasValidas
        .map((l) => {
              'producto_presentacion_id': l.presentacionId,
              'cantidad': l.cant,
              'precio_unitario': l.precioVal,
              'descuento': 0,
              'subtotal': double.parse(l.subtotal.toStringAsFixed(2)),
            })
        .toList();

    final pagos = _tipoPago == 'contado'
        ? _pagos
            .where((p) => p.valor > 0)
            .map((p) => {
                  'metodo_pago_id': null,
                  'forma_pago': p.tipo,
                  'cuenta_bancaria_id': p.tipo == 'transferencia' ? p.cuentaId : null,
                  'billetera_id': p.tipo == 'billetera' ? p.billeteraId : null,
                  'monto': p.valor,
                  'fecha': fecha,
                  'referencia': null,
                })
            .toList()
        : [
            {'metodo_pago_id': null, 'forma_pago': 'credito', 'monto': _total, 'fecha': fecha, 'referencia': null}
          ];

    if (pagos.isEmpty) {
      showAppSnackbar(context, 'Agrega al menos un pago', type: AppSnackbarType.error);
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.post(ApiEndpoints.notasVenta, body: {
        'cliente_id': _clienteId,
        'almacen_id': _almacenId,
        'vendedor_id': vendedorId,
        'fecha_emision': fecha,
        'moneda': 'PEN',
        'tipo_pago': _tipoPago,
        'subtotal': _total,
        'descuento_total': 0,
        'total': _total,
        'serie': 'NV01',
        'detalles': detalles,
        'pagos': pagos,
      });
      if (mounted) {
        showAppSnackbar(context, 'Venta registrada. Stock descontado.', type: AppSnackbarType.success);
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
    return AppScaffold(
      title: 'Nueva Venta',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppFormSection(
                    title: 'Datos de la venta',
                    children: [
                      AppSelect<int>(
                        label: 'Cliente',
                        icon: Icons.person_outline,
                        value: _clienteId,
                        options: [
                          const AppSelectOption(0, 'Público general'),
                          for (final c in _clientes) AppSelectOption(c['id'] as int, c['nombre'] as String? ?? ''),
                        ],
                        onChanged: (v) => setState(() => _clienteId = (v == 0 ? null : v)),
                      ),
                      AppSelect<int>(
                        label: 'Almacén',
                        icon: Icons.warehouse_outlined,
                        value: _almacenId,
                        options: [for (final a in _almacenes) AppSelectOption(a['id'] as int, a['nombre'] as String? ?? '')],
                        onChanged: (v) => setState(() => _almacenId = v),
                      ),
                      AppSelect<String>(
                        label: 'Tipo de pago',
                        icon: Icons.payments_outlined,
                        value: _tipoPago,
                        options: const [AppSelectOption('contado', 'Contado'), AppSelectOption('credito', 'Crédito')],
                        onChanged: (v) => setState(() => _tipoPago = v ?? 'contado'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppFormSection(
                    title: 'Productos',
                    children: [
                      ProductLinesEditor(
                        lines: _lineas,
                        options: _presOptions,
                        priceLabel: 'Precio',
                        autoPrice: _precioMap,
                        onAdd: () => setState(() => _lineas.add(ProductLine())),
                        onRemove: (i) => setState(() => _lineas.removeAt(i).dispose()),
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_tipoPago == 'contado')
                    AppFormSection(
                      title: 'Pagos (mixto)',
                      children: [
                        for (int i = 0; i < _pagos.length; i++)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                            child: Column(
                              children: [
                                MetodoPicker(
                                  cuentas: _cuentas,
                                  billeteras: _billeteras,
                                  tipo: _pagos[i].tipo,
                                  cuentaId: _pagos[i].cuentaId,
                                  billeteraId: _pagos[i].billeteraId,
                                  onChanged: (t, c, b) => setState(() {
                                    _pagos[i].tipo = t ?? 'efectivo';
                                    _pagos[i].cuentaId = c;
                                    _pagos[i].billeteraId = b;
                                  }),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppTextField(
                                        controller: _pagos[i].monto,
                                        label: 'Monto',
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _pagos.length == 1 ? null : () => setState(() => _pagos.removeAt(i).dispose()),
                                      icon: const Icon(Icons.delete_outline),
                                      color: AppColors.danger,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _pagos.add(_Pago())),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Agregar pago'),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('Pagado: S/ ${_pagado.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.textMuted)),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE6E8F5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Text('S/ ${_total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: _saving ? 'Registrando…' : 'Registrar venta',
                    onPressed: _saving ? null : _guardar,
                  ),
                ],
              ),
            ),
    );
  }
}
