import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_endpoints.dart';
import '../models/pedido.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../utils/almacenes.dart';
import '../utils/stock.dart';
import '../widgets/app_button.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_message.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_search_select.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/producto_lineas_panel.dart';

String _money(dynamic v) =>
    'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';

String _num(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
}

String _iso(DateTime d) => d.toIso8601String().substring(0, 10);

/// Crea o edita un pedido de cliente. Es la pantalla de venta sin cobro ni
/// caja: al guardar, la mercadería queda reservada (no se descuenta).
class CrearPedidoScreen extends StatefulWidget {
  /// Con id se edita un pedido pendiente; sin id, se crea uno nuevo.
  final int? pedidoId;

  const CrearPedidoScreen({super.key, this.pedidoId});

  @override
  State<CrearPedidoScreen> createState() => _CrearPedidoScreenState();
}

class _CrearPedidoScreenState extends State<CrearPedidoScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;
  bool get _editando => widget.pedidoId != null;
  String? _error;

  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _almacenes = [];
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _existencias = [];

  int? _clienteId;
  int? _almacenId;
  DateTime _fecha = DateTime.now();
  DateTime? _fechaEntrega;
  final _observaciones = TextEditingController();
  final List<LineaProducto> _lineas = [];

  /// Lo que este pedido ya tiene reservado: al guardar se recalcula, así que
  /// cuenta como disponible mientras se edita.
  Map<int, double> _reservaPropia = {};

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
        // Sin per_page el backend pagina a 15 y el resto quedaría fuera.
        CrudService(_api, '${ApiEndpoints.productos}?per_page=500').getAll(),
        CrudService(_api, ApiEndpoints.existencias).getAll(),
      ]);
      _clientes = r[0];
      _almacenes = r[1];
      _productos = r[2];
      _existencias = r[3];

      // Con un solo almacén no tiene sentido hacer elegir.
      if (_almacenes.length == 1) _almacenId = _almacenes.first['id'] as int?;

      if (widget.pedidoId != null) await _cargarPedido();
    } catch (_) {
      _error = 'No se pudieron cargar los datos.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cargarPedido() async {
    final pedido = Pedido.fromResponse(
      await _api.get(ApiEndpoints.pedido(widget.pedidoId!)),
    );
    if (!pedido.esPendiente) {
      _error = 'Solo se pueden editar pedidos pendientes.';
      return;
    }
    _reservaPropia = reservaDePedido(pedido);
    _clienteId = pedido.clienteId;
    _almacenId = pedido.almacenId;
    _observaciones.text = pedido.observaciones ?? '';
    final f = DateTime.tryParse(pedido.fechaPedido ?? '');
    if (f != null) _fecha = f;
    _fechaEntrega = DateTime.tryParse(pedido.fechaEntrega ?? '');

    for (final l in _lineas) {
      l.dispose();
    }
    _lineas.clear();
    for (final d in pedido.detalles) {
      _lineas.add(LineaProducto(
        productoId: d.productoId ?? 0,
        presentacionId: d.productoPresentacionId,
        cantidad: '${d.cantidad}',
        precio: '${d.precioUnitario}',
      ));
    }
  }

  /// Stock vendible (físico − reservado) en unidad base del almacén elegido.
  Map<int, double> get _stockDelAlmacen => stockVendiblePorProducto(
    _existencias,
    _almacenId,
    reservaPropia: _reservaPropia,
  );

  Map<String, dynamic>? _productoDe(int? id) {
    if (id == null) return null;
    for (final p in _productos) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  Map<String, dynamic>? _presentacionDe(LineaProducto l) {
    for (final pres in ((_productoDe(l.productoId)?['presentaciones'] as List?) ?? [])
        .whereType<Map<String, dynamic>>()) {
      if (pres['id'] == l.presentacionId) return pres;
    }
    return null;
  }

  double _disponibleDe(LineaProducto l) => ProductoLineasPanel.disponibleDe(
    _presentacionDe(l),
    _stockDelAlmacen[l.productoId] ?? 0,
  );

  double get _total => _lineas.fold(0, (acc, l) => acc + l.subtotal);

  Future<void> _elegirFecha({required bool entrega}) async {
    final d = await showDatePicker(
      context: context,
      initialDate: (entrega ? _fechaEntrega : null) ?? _fecha,
      firstDate: entrega ? _fecha : DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      if (entrega) {
        _fechaEntrega = d;
      } else {
        _fecha = d;
        // La entrega no puede ser anterior al pedido.
        if (_fechaEntrega != null && _fechaEntrega!.isBefore(d)) _fechaEntrega = null;
      }
    });
  }

  Future<void> _guardar() async {
    if (_almacenId == null) {
      return showAppSnackbar(context, 'Selecciona el almacén', type: AppSnackbarType.error);
    }

    final validas = _lineas.where((l) => l.presentacionId != null && l.cant > 0).toList();
    if (validas.isEmpty) {
      return showAppSnackbar(context, 'Agrega al menos un producto', type: AppSnackbarType.error);
    }

    // El pedido reserva stock: se avisa antes de que lo rechace el backend.
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

    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    try {
      final cuerpo = <String, dynamic>{
        'cliente_id': _clienteId,
        'almacen_id': _almacenId,
        'vendedor_id': auth.user?.id,
        'fecha_pedido': _iso(_fecha),
        'fecha_entrega': _fechaEntrega == null ? null : _iso(_fechaEntrega!),
        'moneda': 'PEN',
        'subtotal': _total,
        'descuento_total': 0,
        'total': _total,
        'observaciones': _observaciones.text.trim().isEmpty ? null : _observaciones.text.trim(),
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
      };

      if (_editando) {
        await _api.put(ApiEndpoints.pedido(widget.pedidoId!), body: cuerpo);
      } else {
        await _api.post(ApiEndpoints.pedidos, body: cuerpo);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      // Un 422 de stock trae el producto que falta en `message`.
      if (mounted) showAppSnackbar(context, '$e', type: AppSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _editando ? 'Editar Pedido' : 'Nuevo Pedido';
    if (_loading) {
      return AppScaffold(title: titulo, body: const Center(child: CircularProgressIndicator()));
    }

    final clienteNombre = _clientes
        .where((c) => c['id'] == _clienteId)
        .map((c) => c['nombre']?.toString() ?? '')
        .firstOrNull;

    return AppScaffold(
      title: titulo,
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
              title: 'Datos del pedido',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.today_outlined),
                  title: const Text('Fecha del pedido'),
                  subtitle: Text(_iso(_fecha)),
                  onTap: () => _elegirFecha(entrega: false),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: const Text('Fecha de entrega (opcional)'),
                  subtitle: Text(_fechaEntrega == null ? 'Sin definir' : _iso(_fechaEntrega!)),
                  trailing: _fechaEntrega == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Quitar fecha de entrega',
                          onPressed: () => setState(() => _fechaEntrega = null),
                        ),
                  onTap: () => _elegirFecha(entrega: true),
                ),
                AppSearchSelect<int>(
                  label: 'Cliente (opcional)',
                  hint: 'Sin cliente',
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
                AppSelect<int>(
                  label: 'Almacén',
                  icon: Icons.warehouse_outlined,
                  value: _almacenId,
                  options: opcionesAlmacen(_almacenes, _almacenId),
                  // El stock es de otro almacén: las líneas dejan de valer.
                  onChanged: (v) => setState(() {
                    _almacenId = v;
                    _reservaPropia = {};
                    for (final l in _lineas) {
                      l.dispose();
                    }
                    _lineas.clear();
                  }),
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
                    // Solo se aparta lo que hay disponible, al precio de venta.
                    soloConStock: true,
                    mostrarDisponible: true,
                    stockFilter: false,
                    precioDe: (pres) => double.tryParse('${pres['precio_venta'] ?? 0}') ?? 0,
                    onChanged: () => setState(() {}),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            AppFormSection(
              title: 'Resumen',
              children: [
                _resumenFila('Cliente', clienteNombre ?? 'Sin cliente'),
                _resumenFila(
                  'Entrega',
                  _fechaEntrega == null ? 'Sin definir' : _iso(_fechaEntrega!),
                ),
                _resumenFila('Total', _money(_total), destacado: true),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'El pedido reserva la mercadería del almacén sin descontarla: '
                    'el stock baja recién al convertirlo en venta.',
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
                    label: _editando ? 'Guardar cambios' : 'Registrar pedido',
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

  Widget _resumenFila(String label, String valor, {bool destacado = false}) => Padding(
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
            color: destacado ? AppColors.primary : null,
          ),
        ),
      ],
    ),
  );
}
