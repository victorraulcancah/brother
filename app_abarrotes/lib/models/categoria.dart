class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activo;
  final String? createdAt;

  Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.activo,
    this.createdAt,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      activo: json['activo'] ?? true,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'activo': activo,
  };
}
