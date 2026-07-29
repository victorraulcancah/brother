class TomaInventario {
  final int id;
  final int almacenId;
  final String fecha;
  final String estado;
  final String? observaciones;
  final String? almacenNombre;

  TomaInventario({
    required this.id,
    required this.almacenId,
    required this.fecha,
    this.estado = 'en_proceso',
    this.observaciones,
    this.almacenNombre,
  });

  factory TomaInventario.fromJson(Map<String, dynamic> json) {
    return TomaInventario(
      id: json['id'],
      almacenId: json['almacen_id'],
      fecha: json['fecha'],
      estado: json['estado'] ?? 'en_proceso',
      observaciones: json['observaciones'],
      almacenNombre: json['almacen']?['nombre'],
    );
  }

  Map<String, dynamic> toJson() => {
    'almacen_id': almacenId,
    'fecha': fecha,
    'estado': estado,
    'observaciones': observaciones,
  };
}
