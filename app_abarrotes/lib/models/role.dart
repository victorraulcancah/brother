class Role {
  final int id;
  final String name;
  final String guardName;

  Role({
    required this.id,
    required this.name,
    this.guardName = 'web',
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      guardName: json['guard_name'] ?? 'web',
    );
  }
}
