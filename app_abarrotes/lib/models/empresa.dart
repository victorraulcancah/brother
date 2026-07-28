class Empresa {
  final int id;
  final String ruc;
  final String razonSocial;
  final String nombreComercial;
  final String? direccion;
  final String? telefono;
  final String? email;
  final bool activa;
  final int? usuariosCount;
  final String? createdAt;

  Empresa({
    required this.id,
    required this.ruc,
    required this.razonSocial,
    required this.nombreComercial,
    this.direccion,
    this.telefono,
    this.email,
    required this.activa,
    this.usuariosCount,
    this.createdAt,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'],
      ruc: json['ruc'],
      razonSocial: json['razon_social'],
      nombreComercial: json['nombre_comercial'],
      direccion: json['direccion'],
      telefono: json['telefono'],
      email: json['email'],
      activa: json['activa'] ?? true,
      usuariosCount: json['users_count'],
      createdAt: json['created_at'],
    );
  }
}
