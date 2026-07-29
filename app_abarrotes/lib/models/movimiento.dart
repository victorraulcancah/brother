class Movimiento {
  final int id;
  final String tipoMovimiento;
  final String origen;
  final double cantidad;
  final double costoUnitario;
  final double saldoStock;
  final String? productoNombre;
  final String? almacenNombre;

  Movimiento({
    required this.id,
    required this.tipoMovimiento,
    required this.origen,
    required this.cantidad,
    this.costoUnitario = 0,
    this.saldoStock = 0,
    this.productoNombre,
    this.almacenNombre,
  });

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      id: json['id'],
      tipoMovimiento: json['tipo_movimiento'],
      origen: json['origen'] ?? '',
      cantidad: (json['cantidad'] ?? 0).toDouble(),
      costoUnitario: (json['costo_unitario'] ?? 0).toDouble(),
      saldoStock: (json['saldo_stock'] ?? 0).toDouble(),
      productoNombre: json['producto']?['nombre'],
      almacenNombre: json['almacen']?['nombre'],
    );
  }
}
