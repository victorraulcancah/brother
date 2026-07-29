class RecepcionCompra {
  final int id;
  final int? ordenCompraId;
  final int? proveedorId;
  final int almacenId;
  final String? numeroDocumento;
  final String? tipoDocumento;
  final String fechaRecepcion;
  final String estado;
  final String? observaciones;
  final String? ordenCompraCodigo;
  final String? proveedorNombre;
  final String? almacenNombre;

  RecepcionCompra({
    required this.id,
    this.ordenCompraId,
    this.proveedorId,
    required this.almacenId,
    this.numeroDocumento,
    this.tipoDocumento,
    required this.fechaRecepcion,
    this.estado = 'parcial',
    this.observaciones,
    this.ordenCompraCodigo,
    this.proveedorNombre,
    this.almacenNombre,
  });

  factory RecepcionCompra.fromJson(Map<String, dynamic> json) {
    return RecepcionCompra(
      id: json['id'],
      ordenCompraId: json['orden_compra_id'],
      proveedorId: json['proveedor_id'],
      almacenId: json['almacen_id'],
      numeroDocumento: json['numero_documento'],
      tipoDocumento: json['tipo_documento'],
      fechaRecepcion: json['fecha_recepcion'],
      estado: json['estado'] ?? 'parcial',
      observaciones: json['observaciones'],
      ordenCompraCodigo: json['orden_compra']?['codigo'],
      proveedorNombre: json['proveedor']?['nombre'],
      almacenNombre: json['almacen']?['nombre'],
    );
  }

  Map<String, dynamic> toJson() => {
    'orden_compra_id': ordenCompraId,
    'proveedor_id': proveedorId,
    'almacen_id': almacenId,
    'numero_documento': numeroDocumento,
    'tipo_documento': tipoDocumento,
    'fecha_recepcion': fechaRecepcion,
    'estado': estado,
    'observaciones': observaciones,
  };
}
