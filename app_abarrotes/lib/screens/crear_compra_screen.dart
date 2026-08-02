import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/product_lines_editor.dart';

const _metodosPago = [
  AppSelectOption('efectivo', 'Efectivo'),
  AppSelectOption('transferencia', 'Transferencia'),
  AppSelectOption('tarjeta', 'Tarjeta'),
  AppSelectOption('yape', 'Yape'),
  AppSelectOption('plin', 'Plin'),
  AppSelectOption('otro', 'Otro'),
];

class _Pago {
  String metodo = 'efectivo';
  final TextEditingController monto = TextEditingController();
  double get valor => double.tryParse(monto.text.trim()) ?? 0;
  void dispose() => monto.dispose();
}

class CrearCompraScreen extends StatefulWidget {
  const CrearCompraScreen({super.key});

  @override
  State<CrearCompraScreen> createState() => _CrearCompraScreenState();
}

class _CrearCompraScreenState extends State<CrearCompraScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _proveedores = [];
  final List<AppSelectOption<int>> _presOptions = [];

  int? _proveedorId;
  String _tipoDoc = 'factura';
  String _formaPago = 'contado';
  final _serie = TextEditingController();
  final _numero = TextEditingController();

  final List<ProductLine> _lineas = [ProductLine(precio: '0')];
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
        CrudService(_api, ApiEndpoints.productos).getAll(),
      ]);
      _proveedores = results[0];
      for (final p in results[1]) {
        for (final pres in (p['presentaciones'] as List? ?? [])) {
          _presOptions.add(AppSelectOption(pres['id'] as int, '${p['nombre']} — ${pres['nombre']}'));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double get _total => _lineas.fold(0, (a, l) => a + l.subtotal);

  Future<void> _guardar() async {
    final lineasValidas = _lineas.where((l) => l.presentacionId != null && l.cant > 0).toList();
    if (lineasValidas.isEmpty) {
      showAppSnackbar(context, 'Agrega al menos un producto', type: AppSnackbarType.error);
      return;
    }
    final fecha = DateTime.now().toIso8601String().substring(0, 10);
    setState(() => _saving = true);
    try {
      await _api.post(ApiEndpoints.compras, body: {
        'proveedor_id': _proveedorId,
        'tipo_documento': _tipoDoc,
        'serie': _serie.text.trim(),
        'numero': _numero.text.trim(),
        'fecha': fecha,
        'forma_pago': _formaPago,
        'dias_credito': 0,
        'fecha_vencimiento': _formaPago == 'credito' ? fecha : null,
        'flete': 0,
        'detalles': lineasValidas
            .map((l) => {'producto_presentacion_id': l.presentacionId, 'cantidad': l.cant, 'costo_unitario': l.precioVal})
            .toList(),
        'pagos': _pagos.where((p) => p.valor > 0).map((p) => {'metodo': p.metodo, 'monto': p.valor}).toList(),
      });
      if (mounted) {
        showAppSnackbar(context, 'Compra registrada.', type: AppSnackbarType.success);
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
      title: 'Nueva Compra',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppFormSection(
                    title: 'Datos del comprobante',
                    children: [
                      AppSelect<int>(
                        label: 'Proveedor',
                        icon: Icons.local_shipping_outlined,
                        value: _proveedorId,
                        options: [for (final p in _proveedores) AppSelectOption(p['id'] as int, p['nombre'] as String? ?? '')],
                        onChanged: (v) => setState(() => _proveedorId = v),
                      ),
                      AppSelect<String>(
                        label: 'Tipo documento',
                        icon: Icons.description_outlined,
                        value: _tipoDoc,
                        options: const [
                          AppSelectOption('factura', 'Factura'),
                          AppSelectOption('boleta', 'Boleta'),
                          AppSelectOption('guia', 'Guía de remisión'),
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppFormSection(
                    title: 'Productos',
                    children: [
                      ProductLinesEditor(
                        lines: _lineas,
                        options: _presOptions,
                        priceLabel: 'Costo',
                        onAdd: () => setState(() => _lineas.add(ProductLine(precio: '0'))),
                        onRemove: (i) => setState(() => _lineas.removeAt(i).dispose()),
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppFormSection(
                    title: 'Pagos (mixto)',
                    children: [
                      for (int i = 0; i < _pagos.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppSelect<String>(
                                  label: 'Método',
                                  value: _pagos[i].metodo,
                                  options: _metodosPago,
                                  onChanged: (v) => setState(() => _pagos[i].metodo = v ?? 'efectivo'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppTextField(
                                  controller: _pagos[i].monto,
                                  label: 'Monto',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              IconButton(
                                onPressed: _pagos.length == 1 ? null : () => setState(() => _pagos.removeAt(i).dispose()),
                                icon: const Icon(Icons.delete_outline),
                                color: AppColors.danger,
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
                  PrimaryButton(label: 'Registrar compra', loading: _saving, onPressed: _guardar),
                ],
              ),
            ),
    );
  }
}
