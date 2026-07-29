class SolicitudCompra {
  final int id;
  final String codigo;
  final String fechaSolicitud;
  final String estado;
  final String? observaciones;

  SolicitudCompra({
    required this.id,
    required this.codigo,
    required this.fechaSolicitud,
    this.estado = 'pendiente',
    this.observaciones,
  });

  factory SolicitudCompra.fromJson(Map<String, dynamic> json) {
    return SolicitudCompra(
      id: json['id'],
      codigo: json['codigo'],
      fechaSolicitud: json['fecha_solicitud'],
      estado: json['estado'] ?? 'pendiente',
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'fecha_solicitud': fechaSolicitud,
    'estado': estado,
    'observaciones': observaciones,
  };
}
