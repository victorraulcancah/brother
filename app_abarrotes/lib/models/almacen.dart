class Almacen {
  final int id;
  final String nombre;
  final String codigo;
  final String tipo;
  final String? direccion;
  final bool activo;

  Almacen({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.tipo = 'principal',
    this.direccion,
    required this.activo,
  });

  factory Almacen.fromJson(Map<String, dynamic> json) {
    return Almacen(
      id: json['id'],
      nombre: json['nombre'],
      codigo: json['codigo'],
      tipo: json['tipo'] ?? 'principal',
      direccion: json['direccion'],
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'codigo': codigo,
    'tipo': tipo,
    'direccion': direccion,
    'activo': activo,
  };
}
