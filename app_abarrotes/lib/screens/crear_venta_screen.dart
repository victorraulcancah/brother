import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_endpoints.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_message.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_search_select.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/metodo_picker.dart';
import '../widgets/producto_lineas_panel.dart';
import '../utils/almacenes.dart';

/// Venta al paso: no se identifica al comprador.
const _clienteGenerico = 'Clientes varios';

String _money(dynamic v) =>
    'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';

String _num(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
}

class _Pago {
  String tipo = 'efectivo';
  int? cuentaId;
  int? billeteraId;
  final TextEditingController monto = TextEditingController();
  double get valor => double.tryParse(monto.text.trim()) ?? 0;
  void dispose() => monto.dispose();
}

class CrearVentaScreen extends StatefulWidget {
  /// Con id se edita una venta existente; sin id, se crea una nueva.
  final int? ventaId;

  const CrearVentaScreen({super.key, this.ventaId});

  @override
  State<CrearVentaScreen> createState() => _CrearVentaScreenState();
}

class _CrearVentaScreenState extends State<CrearVentaScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;
  bool get _editando => widget.ventaId != null;
  String? _error;

  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _almacenes = [];
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _existencias = [];
  List<Map<String, dynamic>> _cuentas = [];
  List<Map<String, dynamic>> _billeteras = [];

  int? _clienteId;
  int? _almacenId;
  String _tipoPago = 'contado';
  DateTime _fecha = DateTime.now();
  final _observaciones = TextEditingController();

  final List<LineaProducto> _lineas = [];
  final List<_Pago> _pagos = [_Pago()];
  /// Off = un solo cobro que cubre el total. On = varios métodos.
  bool _mixto = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _observaciones.dispose();
    for (final l in _lineas) {
      l.dispose();
    }
    for (final p in _pagos) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Future.wait([
        CrudService(_api, ApiEndpoints.clientes).getAll(),
        CrudService(_api, ApiEndpoints.almacenes).getAll(),
        // Sin per_page el backend pagina a 15: el resto del catálogo
        // quedaba invendible desde la app.
        CrudService(_api, '${ApiEndpoints.productos}?per_page=500').getAll(),
        CrudService(_api, ApiEndpoints.existencias).getAll(),
        CrudService(_api, ApiEndpoints.cuentasBancarias).getAll(),
        CrudService(_api, ApiEndpoints.billeterasDigitales).getAll(),
      ]);
      _clientes = r[0];
      _almacenes = r[1];
      _productos = r[2];
      _existencias = r[3];
      _cuentas = r[4];
      _billeteras = r[5];

      // Con un solo almacén no tiene sentido hacer elegir.
      if (_almacenes.length == 1) _almacenId = _almacenes.first['id'] as int?;

      if (widget.ventaId != null) await _cargarVenta();
    } catch (_) {
      _error = 'No se pudieron cargar los datos.';
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Vuelca una venta existente al formulario, sus líneas y sus pagos.
  Future<void> _cargarVenta() async {
    // Laravel envuelve los Resource en {"data": {...}}.
    final res = await _api.get(ApiEndpoints.notaVenta(widget.ventaId!));
    final venta = Map<String, dynamic>.from(
      (res is Map && res['data'] is Map) ? res['data'] as Map : res as Map,
    );

    _clienteId = venta['cliente_id'] as int?;
    _almacenId = venta['almacen_id'] as int?;
    _tipoPago = venta['tipo_pago']?.toString() ?? 'contado';
    _observaciones.text = venta['observaciones']?.toString() ?? '';
    final fecha = DateTime.tryParse('${venta['fecha_emision'] ?? ''}');
    if (fecha != null) _fecha = fecha;

    for (final l in _lineas) {
      l.dispose();
    }
    _lineas.clear();
    for (final d in ((venta['detalles'] as List?) ?? []).whereType<Map>()) {
      final producto = (d['presentacion'] as Map?)?['producto'] as Map?;
      _lineas.add(LineaProducto(
        productoId: (producto?['id'] as int?) ?? 0,
        presentacionId: d['producto_presentacion_id'] as int?,
        cantidad: '${d['cantidad'] ?? 0}',
        precio: '${d['precio_unitario'] ?? 0}',
      ));
    }

    // Al crédito el pago es un apunte automático, no un cobro real.
    final cobros = ((venta['pagos'] as List?) ?? [])
        .whereType<Map>()
        .where((p) => p['forma_pago'] != 'credito')
        .toList();
    if (cobros.isNotEmpty) {
      for (final p in _pagos) {
        p.dispose();
      }
      _pagos.clear();
      for (final c in cobros) {
        _pagos.add(_Pago()
          ..tipo = c['forma_pago']?.toString() ?? 'efectivo'
          ..cuentaId = c['cuenta_bancaria_id'] as int?
          ..billeteraId = c['billetera_id'] as int?
          ..monto.text = '${c['monto'] ?? 0}');
      }
    }
  }

  /// Stock en unidad base de cada producto del almacén elegido.
  Map<int, double> get _stockDelAlmacen {
    if (_almacenId == null) return {};
    return {
      for (final e in _existencias)
        if (e['almacen_id'] == _almacenId)
          e['producto_id'] as int:
              double.tryParse('${e['stock_actual']}') ?? 0,
    };
  }

  Map<String, dynamic>? _productoDe(int? id) {
    if (id == null) return null;
    for (final p in _productos) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  Map<String, dynamic>? _presentacionDe(LineaProducto l) {
    for (final pres in ((_productoDe(l.productoId)?['presentaciones'] as List?) ?? []).whereType<Map<String, dynamic>>()) {
      if (pres['id'] == l.presentacionId) return pres;
    }
    return null;
  }

  /// Disponible de la línea en su unidad (el stock vive en unidad base).
  double _disponibleDe(LineaProducto l) =>
      ProductoLineasPanel.disponibleDe(_presentacionDe(l), _stockDelAlmacen[l.productoId] ?? 0);

  double get _total => _lineas.fold(0, (acc, l) => acc + l.subtotal);
  bool get _esContado => _tipoPago == 'contado';

  /// En modo simple hay un solo cobro que cubre el total.
  List<({String tipo, int? cuentaId, int? billeteraId, double monto})>
  get _pagosEfectivos => _mixto
      ? [
          for (final p in _pagos)
            (
              tipo: p.tipo,
              cuentaId: p.cuentaId,
              billeteraId: p.billeteraId,
              monto: p.valor,
            ),
        ]
      : [
          (
            tipo: _pagos.first.tipo,
            cuentaId: _pagos.first.cuentaId,
            billeteraId: _pagos.first.billeteraId,
            monto: _total,
          ),
        ];

  double get _cobrado => _pagosEfectivos.fold(0, (acc, p) => acc + p.monto);
  double get _saldo => _total - _cobrado;

  Future<void> _guardar() async {
    if (_almacenId == null) {
      return showAppSnackbar(
        context,
        'Selecciona el almacén',
        type: AppSnackbarType.error,
      );
    }
    if (_tipoPago == 'credito' && _clienteId == null) {
      return showAppSnackbar(
        context,
        'Una venta al crédito necesita un cliente identificado',
        type: AppSnackbarType.error,
      );
    }

    final validas = _lineas
        .where((l) => l.presentacionId != null && l.cant > 0)
        .toList();
    if (validas.isEmpty) {
      return showAppSnackbar(
        context,
        'Agrega al menos un producto',
        type: AppSnackbarType.error,
      );
    }

    // El stock se descuenta al vender: se avisa antes de que falle el backend.
    for (final l in validas) {
      final disp = _disponibleDe(l);
      if (l.cant > disp) {
        final nombre = _productoDe(l.productoId)?['nombre'] ?? 'El producto';
        return showAppSnackbar(
          context,
          '"$nombre" solo tiene ${_num(disp)} disponibles',
          type: AppSnackbarType.error,
        );
      }
    }

    final fecha = _fecha.toIso8601String().substring(0, 10);
    final auth = context.read<AuthProvider>();

    setState(() => _saving = true);
    try {
      final cuerpo = <String, dynamic>{
        'cliente_id': _clienteId,
        'almacen_id': _almacenId,
        'vendedor_id': auth.user?.id,
        'fecha_emision': fecha,
        'moneda': 'PEN',
        'tipo_pago': _tipoPago,
        'subtotal': _total,
        'descuento_total': 0,
        'total': _total,
        'observaciones': _observaciones.text.trim().isEmpty
            ? null
            : _observaciones.text.trim(),
        'serie': 'NV01',
        'detalles': [
          for (final l in validas)
            {
              'producto_presentacion_id': l.presentacionId,
              'cantidad': l.cant,
              'precio_unitario': l.precioVal,
              'descuento': 0,
              'subtotal': l.subtotal,
            },
        ],
        'pagos': _esContado
            ? [
                for (final p in _pagosEfectivos)
                  if (p.monto > 0)
                    {
                      'metodo_pago_id': null,
                      'forma_pago': p.tipo,
                      'cuenta_bancaria_id': p.tipo == 'transferencia'
                          ? p.cuentaId
                          : null,
                      'billetera_id': p.tipo == 'billetera'
                          ? p.billeteraId
                          : null,
                      'monto': p.monto,
                      'fecha': fecha,
                      'referencia': null,
                    },
              ]
            : [
                {
                  'metodo_pago_id': null,
                  'forma_pago': 'credito',
                  'monto': _total,
                  'fecha': fecha,
                  'referencia': null,
                },
              ],
      };

      if (_editando) {
        await _api.put(ApiEndpoints.notaVenta(widget.ventaId!), body: cuerpo);
      } else {
        await _api.post(ApiEndpoints.notasVenta, body: cuerpo);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        title: _editando ? 'Editar Venta' : 'Nueva Venta',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final clienteNombre = _clientes
        .where((c) => c['id'] == _clienteId)
        .map((c) => c['nombre']?.toString() ?? '')
        .firstOrNull;

    return AppScaffold(
      title: _editando ? 'Editar Venta' : 'Nueva Venta',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              AppMessage(text: _error!),
              const SizedBox(height: 12),
            ],

            AppFormSection(
              title: 'Datos de la venta',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.today_outlined),
                  title: const Text('Fecha'),
                  subtitle: Text(_fecha.toIso8601String().substring(0, 10)),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _fecha = d);
                  },
                ),
                AppSearchSelect<int>(
                  label: _esContado ? 'Cliente (opcional)' : 'Cliente',
                  hint: _clienteGenerico,
                  icon: Icons.person_outline,
                  value: _clienteId,
                  options: [
                    for (final c in _clientes)
                      AppSearchOption<int>(
                        c['id'] as int,
                        c['nombre']?.toString() ?? c['razon_social']?.toString() ?? '#${c['id']}',
                        subtitle: c['numero_documento']?.toString(),
                        keywords: '${c['numero_documento'] ?? ''}',
                      ),
                  ],
                  onChanged: (v) => setState(() => _clienteId = v),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _clienteId == null
                        ? (_esContado
                              ? 'Sin cliente se registra como "$_clienteGenerico".'
                              : 'Una venta al crédito necesita un cliente identificado.')
                        : '',
                    style: TextStyle(
                      fontSize: 12,
                      color: _clienteId == null && !_esContado
                          ? AppColors.danger
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                AppSelect<int>(
                  label: 'Almacén',
                  icon: Icons.warehouse_outlined,
                  value: _almacenId,
                  options: opcionesAlmacen(_almacenes, _almacenId),
                  // El stock es de otro almacén: las líneas dejan de valer.
                  onChanged: (v) => setState(() {
                    _almacenId = v;
                    for (final l in _lineas) {
                      l.dispose();
                    }
                    _lineas.clear();
                  }),
                ),
                AppSelect<String>(
                  label: 'Tipo de pago',
                  icon: Icons.payments_outlined,
                  value: _tipoPago,
                  options: const [
                    AppSelectOption('contado', 'Contado'),
                    AppSelectOption('credito', 'Crédito'),
                  ],
                  onChanged: (v) => setState(() => _tipoPago = v ?? 'contado'),
                ),
                AppTextField(
                  controller: _observaciones,
                  label: 'Observaciones',
                  icon: Icons.notes_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),

            AppFormSection(
              title: 'Buscar producto',
              children: [
                if (_almacenId == null)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Elige un almacén para ver los productos con stock.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else
                  ProductoLineasPanel(
                    // Al cambiar de almacén el panel se reinicia con su stock.
                    key: ValueKey(_almacenId),
                    productos: _productos,
                    stockPorProducto: _stockDelAlmacen,
                    lineas: _lineas,
                    priceLabel: 'Precio S/',
                    // Se vende lo que hay, al precio de venta de la presentación.
                    soloConStock: true,
                    mostrarDisponible: true,
                    stockFilter: false,
                    precioDe: (pres) => double.tryParse('${pres['precio_venta'] ?? 0}') ?? 0,
                    onChanged: () => setState(() {}),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_esContado)
              AppFormSection(
                title: 'Cobro',
                trailing: TextButton.icon(
                  onPressed: () => setState(() {
                    _mixto = !_mixto;
                    if (!_mixto) {
                      while (_pagos.length > 1) {
                        _pagos.removeLast().dispose();
                      }
                    }
                  }),
                  icon: Icon(
                    _mixto ? Icons.toggle_on : Icons.toggle_off_outlined,
                    size: 20,
                  ),
                  label: const Text('Pago mixto'),
                ),
                children: [
                  if (!_mixto) ...[
                    MetodoPicker(
                      cuentas: _cuentas,
                      billeteras: _billeteras,
                      tipo: _pagos.first.tipo,
                      cuentaId: _pagos.first.cuentaId,
                      billeteraId: _pagos.first.billeteraId,
                      onChanged: (t, c, b) => setState(() {
                        _pagos.first.tipo = t ?? 'efectivo';
                        _pagos.first.cuentaId = c;
                        _pagos.first.billeteraId = b;
                      }),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Se cobra el total'),
                          Text(
                            _money(_total),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    for (var i = 0; i < _pagos.length; i++) _pagoCard(i),
                    TextButton.icon(
                      onPressed: () => setState(() => _pagos.add(_Pago())),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar pago'),
                    ),
                    _resumenFila('Cobrado', _money(_cobrado)),
                    if (_saldo.abs() > 0.001)
                      _resumenFila(
                        _saldo > 0 ? 'Falta cobrar' : 'Vuelto',
                        _money(_saldo.abs()),
                        color: _saldo > 0 ? AppColors.warning : AppColors.danger,
                      ),
                  ],
                ],
              )
            else
              const AppMessage(
                text:
                    'Venta al crédito: queda como cuenta por cobrar del cliente, '
                    'sin cobro ahora.',
                type: AppMessageType.success,
              ),

            const SizedBox(height: 12),
            AppFormSection(
              title: 'Resumen',
              children: [
                _resumenFila('Cliente', clienteNombre ?? _clienteGenerico),
                _resumenFila('Total', _money(_total), destacado: true),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Al registrar la venta se descuenta el stock del almacén elegido.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
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
                    label: _editando ? 'Guardar cambios' : 'Registrar venta',
                    loading: _saving,
                    onPressed: _guardar,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenFila(
    String label,
    String valor, {
    Color? color,
    bool destacado = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
        Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: destacado ? 18 : null,
            color: color ?? (destacado ? AppColors.primary : null),
          ),
        ),
      ],
    ),
  );

  Widget _pagoCard(int index) {
    final p = _pagos[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            MetodoPicker(
              cuentas: _cuentas,
              billeteras: _billeteras,
              tipo: p.tipo,
              cuentaId: p.cuentaId,
              billeteraId: p.billeteraId,
              onChanged: (t, c, b) => setState(() {
                p.tipo = t ?? 'efectivo';
                p.cuentaId = c;
                p.billeteraId = b;
              }),
            ),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: p.monto,
                    label: 'Monto',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_pagos.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppColors.danger,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _pagos.removeAt(index).dispose()),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
