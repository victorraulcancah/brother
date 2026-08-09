import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';
import 'app_form_section.dart';
import 'app_message.dart';
import 'app_select.dart';
import 'app_text_field.dart';

/// Registra una recepción contra una compra. Admite recepción parcial:
/// cada línea trae su pendiente y se recibe lo que realmente llegó.
///
/// Devuelve `true` por Navigator.pop si se registró algo.
class RecepcionarCompraSheet extends StatefulWidget {
  final int compraId;

  const RecepcionarCompraSheet({super.key, required this.compraId});

  @override
  State<RecepcionarCompraSheet> createState() => _RecepcionarCompraSheetState();
}

class _RecepcionarCompraSheetState extends State<RecepcionarCompraSheet> {
  final ApiService _api = ApiService();

  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  Map<String, dynamic>? _compra;
  List<Map<String, dynamic>> _lineas = [];
  List<Map<String, dynamic>> _almacenes = [];

  int? _almacenId;
  final _observaciones = TextEditingController();
  /// Cantidad a recibir por línea: { compra_detalle_id: controller }
  final Map<int, TextEditingController> _cantidades = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _observaciones.dispose();
    for (final c in _cantidades.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await _api.get(ApiEndpoints.compraPendientes(widget.compraId));
      final almacenes = await CrudService(_api, ApiEndpoints.almacenes).getAll();

      _compra = (data['compra'] as Map?)?.cast<String, dynamic>();
      _lineas = ((data['lineas'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .where((l) => (double.tryParse('${l['pendiente']}') ?? 0) > 0)
          .toList();

      _almacenes = almacenes;
      if (almacenes.length == 1) _almacenId = almacenes.first['id'] as int?;

      // Por defecto se recibe todo lo pendiente; se ajusta lo que no llegó.
      for (final l in _lineas) {
        _cantidades[l['compra_detalle_id'] as int] = TextEditingController(
          text: '${l['pendiente']}',
        );
      }
    } catch (_) {
      _error = 'No se pudo cargar el pendiente de la compra.';
    }
    if (mounted) setState(() => _cargando = false);
  }

  double _pendienteDe(Map<String, dynamic> l) =>
      double.tryParse('${l['pendiente']}') ?? 0;

  Future<void> _registrar() async {
    if (_almacenId == null) {
      setState(() => _error = 'Elige el almacén receptor.');
      return;
    }

    final detalles = <Map<String, dynamic>>[];
    for (final l in _lineas) {
      final id = l['compra_detalle_id'] as int;
      final cantidad = double.tryParse(_cantidades[id]!.text.trim()) ?? 0;
      if (cantidad <= 0) continue;

      if (cantidad > _pendienteDe(l) + 0.001) {
        setState(() {
          _error =
              '"${l['producto']}" supera lo pendiente (${l['pendiente']}).';
        });
        return;
      }
      detalles.add({'compra_detalle_id': id, 'cantidad_recibida': cantidad});
    }

    if (detalles.isEmpty) {
      setState(() => _error = 'Indica al menos una cantidad recibida.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final serie = _compra?['serie'];
      final numero = _compra?['numero'];
      await _api.post(
        ApiEndpoints.recepciones,
        body: {
          'compra_id': widget.compraId,
          'almacen_id': _almacenId,
          'fecha_recepcion': DateTime.now().toIso8601String().substring(0, 10),
          'tipo_documento': _compra?['tipo_documento'],
          'numero_documento': [
            serie,
            numero,
          ].where((e) => e != null && '$e'.isNotEmpty).join('-'),
          'observaciones': _observaciones.text.trim().isEmpty
              ? null
              : _observaciones.text.trim(),
          'detalles': detalles,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _guardando = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppMessage(text: _error!),
          ),

        if (_lineas.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: AppMessage(
              text: 'Esta compra ya no tiene nada pendiente de recepcionar.',
              type: AppMessageType.success,
            ),
          )
        else ...[
          AppFormSection(
            title: 'Datos de la recepción',
            children: [
              AppSelect<int>(
                label: 'Almacén receptor',
                icon: Icons.warehouse_outlined,
                value: _almacenId,
                options: [
                  for (final a in _almacenes)
                    AppSelectOption<int>(
                      a['id'] as int,
                      a['nombre']?.toString() ?? '',
                    ),
                ],
                onChanged: (v) => setState(() => _almacenId = v),
              ),
              AppTextField(
                controller: _observaciones,
                label: 'Observaciones (opcional)',
                icon: Icons.notes_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),

          AppFormSection(
            title: 'Productos a recibir',
            children: [
              for (final l in _lineas) _lineaCard(l),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Si el proveedor ya no enviará lo que falta, registra lo que '
                  'llegó y luego usa Finalizar en la compra.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Cancelar',
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (_lineas.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Registrar',
                  loading: _guardando,
                  onPressed: _registrar,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _lineaCard(Map<String, dynamic> l) {
    final id = l['compra_detalle_id'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l['producto']?.toString() ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${l['codigo'] ?? '-'} · ${l['unidad'] ?? '-'}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _dato('Pedida', '${l['cantidad_pedida']}'),
                _dato('Recibida', '${l['cantidad_recibida']}'),
                _dato('Pendiente', '${l['pendiente']}', destacado: true),
              ],
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _cantidades[id]!,
              label: 'Recibe ahora',
              icon: Icons.download_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato(String label, String valor, {bool destacado = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: destacado ? AppColors.warning : null,
            ),
          ),
        ],
      ),
    );
  }
}
