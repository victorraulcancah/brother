import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
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

class _Pago {
  String tipo = 'efectivo';
  int? cuentaId;
  int? billeteraId;
  final TextEditingController monto = TextEditingController();
  double get valor => double.tryParse(monto.text.trim()) ?? 0;
  void dispose() => monto.dispose();
}

class CrearCompraScreen extends StatefulWidget {
  /// Con compraId la pantalla edita; con ordenId nace de una orden de compra.
  final int? compraId;
  final int? ordenId;

  const CrearCompraScreen({super.key, this.compraId, this.ordenId});

  @override
  State<CrearCompraScreen> createState() => _CrearCompraScreenState();
}

class _CrearCompraScreenState extends State<CrearCompraScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _ordenCodigo;
  String? _numeroCompra;

  bool get _editando => widget.compraId != null;

  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _productos = [];
  Map<int, double> _stockPorProducto = {};
  List<Map<String, dynamic>> _cuentas = [];
  List<Map<String, dynamic>> _billeteras = [];

  int? _proveedorId;
  String _tipoDoc = 'factura';
  String _formaPago = 'contado';
  final _serie = TextEditingController();
  final _numero = TextEditingController();
  final _flete = TextEditingController(text: '0');
  final _diasCredito = TextEditingController(text: '0');
  final _observaciones = TextEditingController();
  DateTime _fecha = DateTime.now();
  DateTime _vencimiento = DateTime.now();  // ignore: prefer_final_fields

  final List<LineaProducto> _lineas = [];
  final List<_Pago> _pagos = [_Pago()];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _serie.dispose();
    _numero.dispose();
    _flete.dispose();
    _diasCredito.dispose();
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
    try {
      final results = await Future.wait([
        CrudService(_api, ApiEndpoints.proveedores).getAll(),
        // Sin per_page el backend pagina a 15 y el resto del catalogo
        // no se puede comprar desde la app.
        CrudService(_api, '${ApiEndpoints.productos}?per_page=500').getAll(),
        CrudService(_api, ApiEndpoints.cuentasBancarias).getAll(),
        CrudService(_api, ApiEndpoints.billeterasDigitales).getAll(),
        CrudService(_api, ApiEndpoints.existencias).getAll(),
      ]);
      _proveedores = results[0];
      _productos = results[1];
      _cuentas = results[2];
      _billeteras = results[3];
      // El stock vive por almacén: se acumula por producto (unidad base).
      final st = <int, double>{};
      for (final e in results[4]) {
        final pid = e['producto_id'] as int;
        st[pid] = (st[pid] ?? 0) + (double.tryParse('${e['stock_actual']}') ?? 0);
      }
      _stockPorProducto = st;

      if (widget.ordenId != null) await _cargarDesdeOrden();
      if (widget.compraId != null) await _cargarCompra();
    } catch (_) {
      _error = 'No se pudieron cargar los datos.';
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Producto dueño de una presentación (las líneas guardadas solo traen la presentación).
  int? _productoDePresentacion(dynamic presId, [Map? presentacion]) {
    final directo = int.tryParse('${presentacion?['producto_id'] ?? (presentacion?['producto'] as Map?)?['id']}');
    if (directo != null) return directo;
    for (final p in _productos) {
      for (final pres in (p['presentaciones'] as List? ?? [])) {
        if ('${pres['id']}' == '$presId') return p['id'] as int;
      }
    }
    return null;
  }

  /// Transformar orden -> compra: se copian proveedor y lineas.
  Future<void> _cargarDesdeOrden() async {
    final orden = await _api.get(ApiEndpoints.orden(widget.ordenId!));
    _ordenCodigo = orden['codigo']?.toString();
    _proveedorId = orden['proveedor_id'] as int?;

    for (final l in _lineas) {
      l.dispose();
    }
    _lineas.clear();
    for (final d in (orden['detalles'] as List? ?? [])) {
      final productoId = _productoDePresentacion(d['producto_presentacion_id'], d['presentacion'] as Map?);
      if (productoId == null) continue;
      _lineas.add(
        LineaProducto(
          productoId: productoId,
          presentacionId: d['producto_presentacion_id'] as int?,
          cantidad: '${double.tryParse('${d['cantidad']}') ?? 0}',
          precio: '${double.tryParse('${d['precio_unitario']}') ?? 0}',
        ),
      );
    }
  }

  Future<void> _cargarCompra() async {
    final compra = await _api.get(ApiEndpoints.compra(widget.compraId!));
    _numeroCompra = compra['numero_compra']?.toString();
    _proveedorId = compra['proveedor_id'] as int?;
    _tipoDoc = compra['tipo_documento']?.toString() ?? 'factura';
    _formaPago = compra['forma_pago']?.toString() ?? 'contado';
    _serie.text = compra['serie']?.toString() ?? '';
    _numero.text = compra['numero']?.toString() ?? '';
    _flete.text = '${compra['flete'] ?? 0}';
    _diasCredito.text = '${compra['dias_credito'] ?? 0}';
    _observaciones.text = compra['observaciones']?.toString() ?? '';
    _fecha = DateTime.tryParse('${compra['fecha']}') ?? DateTime.now();

    for (final l in _lineas) {
      l.dispose();
    }
    _lineas.clear();
    for (final d in (compra['detalles'] as List? ?? [])) {
      final productoId = _productoDePresentacion(d['producto_presentacion_id'], d['presentacion'] as Map?);
      if (productoId == null) continue;
      _lineas.add(
        LineaProducto(
          productoId: productoId,
          presentacionId: d['producto_presentacion_id'] as int?,
          cantidad: '${double.tryParse('${d['cantidad']}') ?? 0}',
          precio: '${double.tryParse('${d['costo_unitario']}') ?? 0}',
        ),
      );
    }

    final pagos = (compra['pagos'] as List? ?? []);
    if (pagos.isNotEmpty) {
      for (final p in _pagos) {
        p.dispose();
      }
      _pagos.clear();
      for (final pg in pagos) {
        final nuevo = _Pago()
          ..tipo = pg['metodo']?.toString() ?? 'efectivo'
          ..cuentaId = pg['cuenta_bancaria_id'] as int?
          ..billeteraId = pg['billetera_id'] as int?;
        nuevo.monto.text = '${pg['monto']}';
        _pagos.add(nuevo);
      }
    }
  }

  double get _total => _lineas.fold(0, (a, l) => a + l.subtotal);

  Future<void> _guardar() async {
    final lineasValidas = _lineas.where((l) => l.presentacionId != null && l.cant > 0).toList();
    if (lineasValidas.isEmpty) {
      showAppSnackbar(context, 'Agrega al menos un producto', type: AppSnackbarType.error);
      return;
    }
    final fecha = _fecha.toIso8601String().substring(0, 10);
    setState(() => _saving = true);
    try {
      final payload = {
        'proveedor_id': _proveedorId,
        if (widget.ordenId != null) 'orden_compra_id': widget.ordenId,
        'tipo_documento': _tipoDoc,
        'serie': _serie.text.trim(),
        'numero': _numero.text.trim(),
        'fecha': fecha,
        'forma_pago': _formaPago,
        'dias_credito': _formaPago == 'credito'
            ? (int.tryParse(_diasCredito.text.trim()) ?? 0)
            : 0,
        'fecha_vencimiento': _formaPago == 'credito'
            ? _vencimiento.toIso8601String().substring(0, 10)
            : null,
        'observaciones': _observaciones.text.trim().isEmpty
            ? null
            : _observaciones.text.trim(),
        'flete': double.tryParse(_flete.text.trim()) ?? 0,
        'detalles': lineasValidas
            .map((l) => {'producto_presentacion_id': l.presentacionId, 'cantidad': l.cant, 'costo_unitario': l.precioVal})
            .toList(),
        'pagos': _pagos.where((p) => p.valor > 0).map((p) => {
              'metodo': p.tipo,
              'cuenta_bancaria_id': p.tipo == 'transferencia' ? p.cuentaId : null,
              'billetera_id': p.tipo == 'billetera' ? p.billeteraId : null,
              'monto': p.valor,
            }).toList(),
      };

      if (_editando) {
        await _api.put(ApiEndpoints.compra(widget.compraId!), body: payload);
      } else {
        await _api.post(ApiEndpoints.compras, body: payload);
      }
      if (mounted) {
        showAppSnackbar(
          context,
          _editando ? 'Compra actualizada.' : 'Compra registrada.',
          type: AppSnackbarType.success,
        );
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
      title: _editando
          ? 'Editar Compra ${_numeroCompra ?? ''}'
          : _ordenCodigo != null
          ? 'Compra desde ${_ordenCodigo!}'
          : 'Nueva Compra',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    AppMessage(text: _error!),
                    const SizedBox(height: 12),
                  ],
                  AppFormSection(
                    title: 'Datos del comprobante',
                    children: [
                      AppSearchSelect<int>(
                        label: 'Proveedor',
                        hint: 'Buscar proveedor…',
                        icon: Icons.local_shipping_outlined,
                        value: _proveedorId,
                        options: [
                          for (final p in _proveedores)
                            AppSearchOption<int>(p['id'] as int, p['nombre']?.toString() ?? '', keywords: '${p['ruc'] ?? ''}'),
                        ],
                        onChanged: (v) => setState(() => _proveedorId = v),
                      ),
                      AppSelect<String>(
                        label: 'Tipo documento',
                        icon: Icons.description_outlined,
                        value: _tipoDoc,
                        options: const [
                          AppSelectOption('factura', 'Factura'),
                          AppSelectOption('boleta', 'Boleta'),
                        ],
                        onChanged: (v) => setState(() => _tipoDoc = v ?? 'factura'),
                      ),
                      Row(
                        children: [
                          Expanded(child: AppTextField(controller: _serie, label: 'Serie', icon: Icons.tag)),
                          const SizedBox(width: 8),
                          Expanded(child: AppTextField(controller: _numero, label: 'Número')),
                        ],
                      ),
                      AppSelect<String>(
                        label: 'Forma de pago',
                        icon: Icons.payments_outlined,
                        value: _formaPago,
                        options: const [AppSelectOption('contado', 'Contado'), AppSelectOption('credito', 'Crédito')],
                        onChanged: (v) => setState(() => _formaPago = v ?? 'contado'),
                      ),
                      if (_formaPago == 'credito') ...[
                        AppTextField(
                          controller: _diasCredito,
                          label: 'N° días de crédito',
                          icon: Icons.event_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today_outlined),
                          title: const Text('Vencimiento'),
                          subtitle: Text(
                            _vencimiento.toIso8601String().substring(0, 10),
                          ),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _vencimiento,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) setState(() => _vencimiento = d);
                          },
                        ),
                      ],
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
                      AppTextField(
                        controller: _flete,
                        label: 'Flete (S/)',
                        icon: Icons.local_shipping_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      AppTextField(
                        controller: _observaciones,
                        label: 'Observaciones',
                        icon: Icons.notes_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppFormSection(
                    title: 'Buscar producto',
                    children: [
                      ProductoLineasPanel(
                        productos: _productos,
                        stockPorProducto: _stockPorProducto,
                        lineas: _lineas,
                        priceLabel: 'Costo',
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                        Text('S/ ${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(label: _editando ? 'Guardar cambios' : 'Registrar compra', loading: _saving, onPressed: _guardar),
                ],
              ),
            ),
    );
  }
}
