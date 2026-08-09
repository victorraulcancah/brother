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
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/metodo_picker.dart';

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

/// Una línea de la venta: producto + unidad derivada + cantidad + precio.
class _Linea {
  int? productoId;
  int? presentacionId;
  final TextEditingController cantidad = TextEditingController(text: '1');
  final TextEditingController precio = TextEditingController(text: '0');

  double get cant => double.tryParse(cantidad.text.trim()) ?? 0;
  double get precioVal => double.tryParse(precio.text.trim()) ?? 0;
  double get subtotal => cant * precioVal;

  void dispose() {
    cantidad.dispose();
    precio.dispose();
  }
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
  final _observaciones = TextEditingController();

  final List<_Linea> _lineas = [_Linea()];
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
    } catch (_) {
      _error = 'No se pudieron cargar los datos.';
    }
    if (mounted) setState(() => _loading = false);
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

  /// Se vende lo que hay: solo productos con stock en el almacén elegido.
  List<AppSelectOption<int>> get _productosOptions {
    final stock = _stockDelAlmacen;
    return [
      for (final p in _productos)
        if ((stock[p['id']] ?? 0) > 0)
          AppSelectOption<int>(p['id'] as int, p['nombre']?.toString() ?? ''),
    ];
  }

  Map<String, dynamic>? _productoDe(int? id) {
    if (id == null) return null;
    for (final p in _productos) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  /// Unidades derivadas del producto con el disponible ya convertido:
  /// el stock vive en unidad base, no en paquetes.
  List<({int id, String nombre, double factor, double precio, double disponible})>
  _unidadesDe(int? productoId) {
    final p = _productoDe(productoId);
    if (p == null) return [];

    final stockBase = _stockDelAlmacen[productoId] ?? 0;
    return [
      for (final pres in (p['presentaciones'] as List? ?? []))
        if (pres['activo'] != false)
          () {
            final factor =
                double.tryParse('${pres['factor_conversion']}') ?? 1;
            return (
              id: pres['id'] as int,
              nombre: pres['nombre']?.toString() ?? '',
              factor: factor,
              precio: double.tryParse('${pres['precio_venta']}') ?? 0,
              disponible: (stockBase / factor * 100).floor() / 100,
            );
          }(),
    ];
  }

  ({int id, String nombre, double factor, double precio, double disponible})?
  _unidadDe(_Linea l) {
    for (final u in _unidadesDe(l.productoId)) {
      if (u.id == l.presentacionId) return u;
    }
    return null;
  }

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
      final u = _unidadDe(l);
      if (u != null && l.cant > u.disponible) {
        final nombre = _productoDe(l.productoId)?['nombre'] ?? 'El producto';
        return showAppSnackbar(
          context,
          '"$nombre" solo tiene ${_num(u.disponible)} disponibles',
          type: AppSnackbarType.error,
        );
      }
    }

    final fecha = DateTime.now().toIso8601String().substring(0, 10);
    final auth = context.read<AuthProvider>();

    setState(() => _saving = true);
    try {
      await _api.post(
        ApiEndpoints.notasVenta,
        body: {
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
        },
      );
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
      return const AppScaffold(
        title: 'Nueva Venta',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final clienteNombre = _clientes
        .where((c) => c['id'] == _clienteId)
        .map((c) => c['nombre']?.toString() ?? '')
        .firstOrNull;

    return AppScaffold(
      title: 'Nueva Venta',
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
                AppSelect<int>(
                  label: _esContado ? 'Cliente (opcional)' : 'Cliente',
                  icon: Icons.person_outline,
                  value: _clienteId,
                  options: [
                    for (final c in _clientes)
                      AppSelectOption<int>(
                        c['id'] as int,
                        c['nombre']?.toString() ?? '',
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
                  options: [
                    for (final a in _almacenes)
                      AppSelectOption<int>(
                        a['id'] as int,
                        a['nombre']?.toString() ?? '',
                      ),
                  ],
                  // El stock es de otro almacén: las líneas dejan de valer.
                  onChanged: (v) => setState(() {
                    _almacenId = v;
                    for (final l in _lineas) {
                      l.dispose();
                    }
                    _lineas
                      ..clear()
                      ..add(_Linea());
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
              title: 'Productos',
              trailing: TextButton.icon(
                onPressed: _almacenId == null
                    ? null
                    : () => setState(() => _lineas.add(_Linea())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
              ),
              children: [
                if (_almacenId == null)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Elige un almacén para ver los productos con stock.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else if (_productosOptions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Este almacén no tiene productos con stock.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else
                  for (var i = 0; i < _lineas.length; i++) _lineaCard(i),
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
                    label: 'Registrar venta',
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

  Widget _lineaCard(int index) {
    final l = _lineas[index];
    final unidades = _unidadesDe(l.productoId);
    final u = _unidadDe(l);
    final excede = u != null && l.cant > u.disponible;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Producto ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  _money(l.subtotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                if (_lineas.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppColors.danger,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _lineas.removeAt(index).dispose()),
                  ),
              ],
            ),
            AppSelect<int>(
              label: 'Producto',
              value: l.productoId,
              options: _productosOptions,
              onChanged: (v) => setState(() {
                l.productoId = v;
                final us = _unidadesDe(v);
                // Con una sola unidad derivada, se elige sola.
                if (us.length == 1) {
                  l.presentacionId = us.first.id;
                  l.precio.text = us.first.precio.toStringAsFixed(2);
                } else {
                  l.presentacionId = null;
                  l.precio.text = '0';
                }
              }),
            ),
            AppSelect<int>(
              label: 'Unidad',
              value: l.presentacionId,
              options: [
                for (final x in unidades) AppSelectOption<int>(x.id, x.nombre),
              ],
              onChanged: (v) => setState(() {
                l.presentacionId = v;
                for (final x in unidades) {
                  if (x.id == v) l.precio.text = x.precio.toStringAsFixed(2);
                }
              }),
            ),
            if (u != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Disponible: ${_num(u.disponible)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: l.cantidad,
                    label: 'Cantidad',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (_) => excede ? 'Sin stock' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextField(
                    controller: l.precio,
                    label: 'Precio S/',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (excede)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Supera el stock disponible',
                  style: TextStyle(fontSize: 12, color: AppColors.danger),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
