class Marca {
  final int id;
  final String nombre;
  final String? logo;
  final bool activo;
  final String? createdAt;

  Marca({
    required this.id,
    required this.nombre,
    this.logo,
    required this.activo,
    this.createdAt,
  });

  factory Marca.fromJson(Map<String, dynamic> json) {
    return Marca(
      id: json['id'],
      nombre: json['nombre'],
      logo: json['logo'],
      activo: json['activo'] ?? true,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'logo': logo,
    'activo': activo,
  };
}
