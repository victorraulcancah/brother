import '../models/pedido.dart';

double _n(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;

/// Stock realmente vendible (unidad base) de cada producto en un almacén:
/// `stock_disponible` = físico − reservado por pedidos pendientes.
///
/// [reservaPropia] suma de vuelta lo que el propio documento en edición ya
/// tiene apartado (un pedido que se edita o se convierte en venta), porque esa
/// reserva se libera al guardar.
Map<int, double> stockVendiblePorProducto(
  List<Map<String, dynamic>> existencias,
  int? almacenId, {
  Map<int, double> reservaPropia = const {},
}) {
  if (almacenId == null) return {};
  return {
    for (final e in existencias)
      if (e['almacen_id'] == almacenId)
        e['producto_id'] as int:
            (e['stock_disponible'] != null
                ? _n(e['stock_disponible'])
                : _n(e['stock_actual']) - _n(e['stock_reservado'])) +
            (reservaPropia[e['producto_id']] ?? 0),
  };
}

/// Lo que un pedido tiene reservado por producto, en unidad base
/// (cantidad × factor de conversión de la presentación pedida).
Map<int, double> reservaDePedido(Pedido pedido) {
  final r = <int, double>{};
  for (final d in pedido.detalles) {
    final id = d.productoId;
    if (id == null) continue;
    r[id] = (r[id] ?? 0) + d.cantidad * d.factorConversion;
  }
  return r;
}
