class Producto {
  final int id;
  final String codigo;
  final String nombre;
  final int marcaId;
  final int? subMarcaId;
  final int? categoriaId;
  final int unidadMedidaId;
  final int? unidadCompraId;
  final int? unidadBaseId;
  final double factorCompraBase;
  final String? descripcion;
  final String? imagen;
  final double precioBase;
  final bool afectoIgv;
  final bool activo;
  final String? marcaNombre;
  final String? categoriaNombre;
  final String? unidadMedidaNombre;
  final String? unidadCompraNombre;
  final String? unidadBaseNombre;
  final List<dynamic>? presentaciones;

  Producto({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.marcaId,
    this.subMarcaId,
    this.categoriaId,
    required this.unidadMedidaId,
    this.unidadCompraId,
    this.unidadBaseId,
    this.factorCompraBase = 1,
    this.descripcion,
    this.imagen,
    this.precioBase = 0,
    this.afectoIgv = true,
    this.activo = true,
    this.marcaNombre,
    this.categoriaNombre,
    this.unidadMedidaNombre,
    this.unidadCompraNombre,
    this.unidadBaseNombre,
    this.presentaciones,
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
      unidadCompraId: json['unidad_compra']?['id'],
      unidadBaseId: json['unidad_base']?['id'],
      factorCompraBase: (json['factor_compra_base'] ?? 1).toDouble(),
      descripcion: json['descripcion'],
      imagen: json['imagen'],
      precioBase: (json['precio_base'] ?? 0).toDouble(),
      afectoIgv: json['afecto_igv'] ?? true,
      activo: json['activo'] ?? true,
      marcaNombre: json['marca']?['nombre'],
      categoriaNombre: json['categoria']?['nombre'],
      unidadMedidaNombre: json['unidad_medida']?['nombre'],
      unidadCompraNombre: json['unidad_compra']?['nombre'],
      unidadBaseNombre: json['unidad_base']?['nombre'],
      presentaciones: json['presentaciones'],
    );
  }

  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'nombre': nombre,
    'marca_id': marcaId,
    'sub_marca_id': subMarcaId,
    'categoria_id': categoriaId,
    'unidad_medida_id': unidadMedidaId,
    'unidad_compra_id': unidadCompraId,
    'unidad_base_id': unidadBaseId,
    'factor_compra_base': factorCompraBase,
    'descripcion': descripcion,
    'imagen': imagen,
    'precio_base': precioBase,
    'afecto_igv': afectoIgv,
    'activo': activo,
  };
}
