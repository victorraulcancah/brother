class Proveedor {
  final int id;
  final String nombre;
  final String codigo;
  final String? ruc;
  final String? direccion;
  final String? telefono;
  final String? email;
  final String? contactoNombre;
  final bool activo;

  Proveedor({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.ruc,
    this.direccion,
    this.telefono,
    this.email,
    this.contactoNombre,
    required this.activo,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'],
      nombre: json['nombre'],
      codigo: json['codigo'],
      ruc: json['ruc'],
      direccion: json['direccion'],
      telefono: json['telefono'],
      email: json['email'],
      contactoNombre: json['contacto_nombre'],
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'codigo': codigo,
    'ruc': ruc,
    'direccion': direccion,
    'telefono': telefono,
    'email': email,
    'contacto_nombre': contactoNombre,
    'activo': activo,
  };
}
