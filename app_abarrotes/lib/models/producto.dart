class Producto {
  final int id;
  final String codigo;
  final String nombre;
  final int marcaId;
  final int? subMarcaId;
  final int? categoriaId;
  final int unidadMedidaId;
  final String? descripcion;
  final double precioBase;
  final bool afectoIgv;
  final bool activo;
  final String? marcaNombre;
  final String? categoriaNombre;
  final String? unidadMedidaNombre;

  Producto({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.marcaId,
    this.subMarcaId,
    this.categoriaId,
    required this.unidadMedidaId,
    this.descripcion,
    this.precioBase = 0,
    this.afectoIgv = true,
    this.activo = true,
    this.marcaNombre,
    this.categoriaNombre,
    this.unidadMedidaNombre,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      codigo: json['codigo'],
      nombre: json['nombre'],
      marcaId: json['marca_id'],
      subMarcaId: json['sub_marca_id'],
      categoriaId: json['categoria_id'],
      unidadMedidaId: json['unidad_medida_id'],
      descripcion: json['descripcion'],
      precioBase: (json['precio_base'] ?? 0).toDouble(),
      afectoIgv: json['afecto_igv'] ?? true,
      activo: json['activo'] ?? true,
      marcaNombre: json['marca']?['nombre'],
      categoriaNombre: json['categoria']?['nombre'],
      unidadMedidaNombre: json['unidad_medida']?['nombre'],
    );
  }

  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'nombre': nombre,
    'marca_id': marcaId,
    'sub_marca_id': subMarcaId,
    'categoria_id': categoriaId,
    'unidad_medida_id': unidadMedidaId,
    'descripcion': descripcion,
    'precio_base': precioBase,
    'afecto_igv': afectoIgv,
    'activo': activo,
  };
}
