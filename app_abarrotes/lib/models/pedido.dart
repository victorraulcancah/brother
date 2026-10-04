/// Pedido de cliente: reserva stock sin descontarlo hasta que se convierte en
/// nota de venta (o se cancela y libera la reserva).
class Pedido {
  final int id;
  final String? serie;
  final String? numero;
  final int? clienteId;
  final int? almacenId;
  final int? vendedorId;
  final String? fechaPedido;
  final String? fechaEntrega;
  final String moneda;
  final double subtotal;
  final double descuentoTotal;
  final double total;
  final String estado;
  final int? notaVentaId;
  final String? notaVentaCodigo;
  final String? motivoCancelacion;
  final String? observaciones;
  final String? clienteNombre;
  final String? almacenNombre;
  final String? vendedorNombre;
  final List<PedidoDetalle> detalles;

  const Pedido({
    required this.id,
    this.serie,
    this.numero,
    this.clienteId,
    this.almacenId,
    this.vendedorId,
    this.fechaPedido,
    this.fechaEntrega,
    this.moneda = 'PEN',
    this.subtotal = 0,
    this.descuentoTotal = 0,
    this.total = 0,
    this.estado = 'pendiente',
    this.notaVentaId,
    this.notaVentaCodigo,
    this.motivoCancelacion,
    this.observaciones,
    this.clienteNombre,
    this.almacenNombre,
    this.vendedorNombre,
    this.detalles = const [],
  });

  static double _d(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
  static String? _s(dynamic v) => v?.toString();

  /// Laravel envuelve los Resource en `{"data": {...}}`; acepta ambas formas.
  factory Pedido.fromResponse(dynamic res) {
    final cuerpo = (res is Map && res['data'] is Map) ? res['data'] : res;
    return Pedido.fromJson(Map<String, dynamic>.from(cuerpo as Map));
  }

  factory Pedido.fromJson(Map<String, dynamic> json) {
    final nota = json['nota_venta'] is Map ? json['nota_venta'] as Map : null;
    return Pedido(
      id: json['id'] as int,
      serie: _s(json['serie']),
      numero: _s(json['numero']),
      clienteId: json['cliente_id'] as int?,
      almacenId: json['almacen_id'] as int?,
      vendedorId: json['vendedor_id'] as int?,
      fechaPedido: _s(json['fecha_pedido']),
      fechaEntrega: _s(json['fecha_entrega']),
      moneda: _s(json['moneda']) ?? 'PEN',
      subtotal: _d(json['subtotal']),
      descuentoTotal: _d(json['descuento_total']),
      total: _d(json['total']),
      estado: _s(json['estado']) ?? 'pendiente',
      notaVentaId: json['nota_venta_id'] as int?,
      notaVentaCodigo: nota == null ? null : '${nota['serie']}-${nota['numero']}',
      motivoCancelacion: _s(json['motivo_cancelacion']),
      observaciones: _s(json['observaciones']),
      clienteNombre: (json['cliente'] as Map?)?['nombre']?.toString(),
      almacenNombre: (json['almacen'] as Map?)?['nombre']?.toString(),
      vendedorNombre: (json['vendedor'] as Map?)?['name']?.toString(),
      detalles: [
        for (final d in ((json['detalles'] as List?) ?? []).whereType<Map>())
          PedidoDetalle.fromJson(Map<String, dynamic>.from(d)),
      ],
    );
  }

  /// "PE01-001"
  String get codigo => '${serie ?? 'PE01'}-${numero ?? ''}';

  bool get esPendiente => estado == 'pendiente';
  bool get esConvertido => estado == 'convertido';
  bool get esCancelado => estado == 'cancelado';

  String get estadoLabel => switch (estado) {
    'pendiente' => 'Pendiente',
    'convertido' => 'Convertido',
    'cancelado' => 'Cancelado',
    _ => estado,
  };
}

class PedidoDetalle {
  final int id;
  final int? productoPresentacionId;
  final int? productoId;
  final double cantidad;
  final double precioUnitario;
  final double descuento;
  final double subtotal;
  final String productoNombre;
  final String? presentacionNombre;
  final String? productoCodigo;
  final String? marca;
  final double factorConversion;

  const PedidoDetalle({
    required this.id,
    this.productoPresentacionId,
    this.productoId,
    this.cantidad = 0,
    this.precioUnitario = 0,
    this.descuento = 0,
    this.subtotal = 0,
    this.productoNombre = '-',
    this.presentacionNombre,
    this.productoCodigo,
    this.marca,
    this.factorConversion = 1,
  });

  factory PedidoDetalle.fromJson(Map<String, dynamic> json) {
    final pres = json['presentacion'] as Map?;
    final producto = pres?['producto'] as Map?;
    final factor = Pedido._d(pres?['factor_conversion']);
    return PedidoDetalle(
      id: json['id'] as int? ?? 0,
      productoPresentacionId: json['producto_presentacion_id'] as int?,
      productoId: (pres?['producto_id'] as int?) ?? (producto?['id'] as int?),
      cantidad: Pedido._d(json['cantidad']),
      precioUnitario: Pedido._d(json['precio_unitario']),
      descuento: Pedido._d(json['descuento']),
      subtotal: Pedido._d(json['subtotal']),
      productoNombre:
          producto?['nombre']?.toString() ?? json['producto_nombre']?.toString() ?? '-',
      presentacionNombre: pres?['nombre']?.toString(),
      productoCodigo: producto?['codigo']?.toString(),
      marca: (producto?['marca'] as Map?)?['nombre']?.toString(),
      factorConversion: factor > 0 ? factor : 1,
    );
  }
}
