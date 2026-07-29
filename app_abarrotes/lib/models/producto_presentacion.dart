class ProductoPresentacion {
  final int id;
  final int productoId;
  final String nombre;
  final String? codigoBarras;
  final double precioVenta;
  final double factorConversion;
  final int? unidadBaseId;
  final String? unidadBaseNombre;
  final bool activo;

  ProductoPresentacion({
    required this.id,
    required this.productoId,
    required this.nombre,
    this.codigoBarras,
    this.precioVenta = 0,
    this.factorConversion = 1,
    this.unidadBaseId,
    this.unidadBaseNombre,
    this.activo = true,
  });

  factory ProductoPresentacion.fromJson(Map<String, dynamic> json) {
    return ProductoPresentacion(
      id: json['id'],
      productoId: json['producto_id'],
      nombre: json['nombre'],
      codigoBarras: json['codigo_barras'],
      precioVenta: (json['precio_venta'] ?? 0).toDouble(),
      factorConversion: (json['factor_conversion'] ?? 1).toDouble(),
      unidadBaseId: json['unidad_base']?['id'],
      unidadBaseNombre: json['unidad_base']?['nombre'],
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'codigo_barras': codigoBarras,
    'precio_venta': precioVenta,
    'factor_conversion': factorConversion,
    'unidad_base_id': unidadBaseId,
    'activo': activo,
  };
}
