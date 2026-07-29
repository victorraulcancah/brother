class OrdenCompra {
  final int id;
  final String codigo;
  final int proveedorId;
  final String? fechaEmision;
  final String? fechaEntregaEstimada;
  final String estado;
  final String moneda;
  final String? observaciones;
  final String? proveedorNombre;

  OrdenCompra({
    required this.id,
    required this.codigo,
    required this.proveedorId,
    this.fechaEmision,
    this.fechaEntregaEstimada,
    this.estado = 'pendiente',
    this.moneda = 'PEN',
    this.observaciones,
    this.proveedorNombre,
  });

  factory OrdenCompra.fromJson(Map<String, dynamic> json) {
    return OrdenCompra(
      id: json['id'],
      codigo: json['codigo'],
      proveedorId: json['proveedor_id'],
      fechaEmision: json['fecha_emision'],
      fechaEntregaEstimada: json['fecha_entrega_estimada'],
      estado: json['estado'] ?? 'pendiente',
      moneda: json['moneda'] ?? 'PEN',
      observaciones: json['observaciones'],
      proveedorNombre: json['proveedor']?['nombre'],
    );
  }

  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'proveedor_id': proveedorId,
    'fecha_emision': fechaEmision,
    'fecha_entrega_estimada': fechaEntregaEstimada,
    'estado': estado,
    'moneda': moneda,
    'observaciones': observaciones,
  };
}
