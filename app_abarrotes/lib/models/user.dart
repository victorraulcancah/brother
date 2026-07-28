class User {
  final int id;
  final String name;
  final String email;
  final int? empresaId;
  final String? empresaNombre;
  final List<String> roles;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.empresaId,
    this.empresaNombre,
    required this.roles,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      empresaId: json['empresa_id'],
      empresaNombre: json['empresa']?['nombre_comercial'],
      roles: (json['roles'] as List?)?.map((r) => r['name'] as String).toList() ?? [],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'empresa_id': empresaId,
  };
}
