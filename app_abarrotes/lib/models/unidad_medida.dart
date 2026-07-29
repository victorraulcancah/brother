class UnidadMedida {
  final int id;
  final String nombre;
  final String abreviatura;

  UnidadMedida({
    required this.id,
    required this.nombre,
    required this.abreviatura,
  });

  factory UnidadMedida.fromJson(Map<String, dynamic> json) {
    return UnidadMedida(
      id: json['id'],
      nombre: json['nombre'],
      abreviatura: json['abreviatura'],
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'abreviatura': abreviatura,
  };
}
