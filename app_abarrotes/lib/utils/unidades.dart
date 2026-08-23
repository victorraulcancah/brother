/// Traduce el modelo mental del comerciante — "compro en sacos de 50 kg y vendo
/// por kilo y por gramo" — a lo que guarda la base de datos: una unidad base en
/// la que se cuenta el stock y un factor de conversión por cada formato de venta.
///
/// Las unidades traen `factor_base`: cuántas unidades mínimas de su familia
/// valen (g=1, kg=1000, ml=1, l=1000, unidad=1, docena=12). Los envases
/// (saco, caja, bolsa) valen 1 porque su contenido lo define el usuario.
///
/// Es el equivalente de `resources/js/lib/unidades.js` en la web: si cambia uno,
/// debe cambiar el otro.
library;

double _factorDe(Map<String, dynamic>? u) {
  final v = double.tryParse('${u?['factor_base'] ?? 1}') ?? 1;
  return v > 0 ? v : 1;
}

Map<String, dynamic>? buscarUnidad(List<Map<String, dynamic>> unidades, int? id) {
  if (id == null) return null;
  for (final u in unidades) {
    if ('${u['id']}' == '$id') return u;
  }
  return null;
}

String nombreUnidad(List<Map<String, dynamic>> unidades, int? id) =>
    buscarUnidad(unidades, id)?['nombre']?.toString() ?? '';

/// Cómo se compra: "un saco que trae 50 kilos, a S/ 140".
class CompraInput {
  final int? unidadCompraId;
  final double cantidad;
  final int? unidadContenidoId;
  final double precio;

  const CompraInput({
    this.unidadCompraId,
    this.cantidad = 0,
    this.unidadContenidoId,
    this.precio = 0,
  });
}

/// Un formato en que se vende. `precioVenta` en null significa "calcúlalo tú
/// con el margen"; si trae valor, manda el precio que escribió el usuario.
class VentaInput {
  final int? unidadId;
  final double? margen;
  final double? precioVenta;

  const VentaInput({this.unidadId, this.margen, this.precioVenta});
}

class FilaCalculada {
  final int unidadId;
  final double factor;
  final double precioCompra;
  final double precioVenta;
  final double margen;

  const FilaCalculada({
    required this.unidadId,
    required this.factor,
    required this.precioCompra,
    required this.precioVenta,
    required this.margen,
  });

  double get ganancia => precioVenta - precioCompra;
}

class CalculoUnidades {
  final int? baseId;
  final double factorCompraBase;
  final double costoBase;
  final List<FilaCalculada> filas;

  const CalculoUnidades({
    this.baseId,
    this.factorCompraBase = 0,
    this.costoBase = 0,
    this.filas = const [],
  });

  FilaCalculada? filaDe(int? unidadId) {
    for (final f in filas) {
      if (f.unidadId == unidadId) return f;
    }
    return null;
  }
}

/// Cuánto vale un formato de venta, en unidades canónicas de su familia.
/// El envase de compra es un caso aparte: vale lo que el usuario dijo que trae
/// (un saco no son "1 gramos", son los 50 kg que le cargamos).
double tamanoVenta(
  List<Map<String, dynamic>> unidades,
  int? unidadId,
  CompraInput compra,
) {
  final esEnvaseDeCompra =
      compra.unidadCompraId != null && unidadId == compra.unidadCompraId;

  if (esEnvaseDeCompra) {
    return compra.cantidad * _factorDe(buscarUnidad(unidades, compra.unidadContenidoId));
  }

  return _factorDe(buscarUnidad(unidades, unidadId));
}

/// Calcula la unidad base (el formato de venta más pequeño), cuántas unidades
/// base trae una compra, el costo unitario y las filas ya valorizadas.
CalculoUnidades calcularPresentaciones({
  required List<Map<String, dynamic>> unidades,
  required CompraInput compra,
  required List<VentaInput> ventas,
}) {
  final conTamano = <MapEntry<VentaInput, double>>[];
  for (final v in ventas) {
    if (v.unidadId == null) continue;
    final t = tamanoVenta(unidades, v.unidadId, compra);
    if (t > 0) conTamano.add(MapEntry(v, t));
  }
  if (conTamano.isEmpty) return const CalculoUnidades();

  // La unidad base es el formato más pequeño: así el stock se puede descontar
  // vendiendo en cualquiera de los formatos sin perder precisión.
  var menor = conTamano.first;
  for (final e in conTamano) {
    if (e.value < menor.value) menor = e;
  }

  final contenido = buscarUnidad(unidades, compra.unidadContenidoId);
  final factorCompraBase = (compra.cantidad * _factorDe(contenido)) / menor.value;
  final costoBase = factorCompraBase > 0 ? compra.precio / factorCompraBase : 0.0;

  final filas = conTamano.map((e) {
    final v = e.key;
    final factor = e.value / menor.value;
    final precioCompra = costoBase * factor;
    final margen = v.margen ?? 0;
    final precioVenta = v.precioVenta ?? (precioCompra * (1 + margen / 100));

    return FilaCalculada(
      unidadId: v.unidadId!,
      factor: factor,
      precioCompra: precioCompra,
      precioVenta: precioVenta,
      margen: margen,
    );
  }).toList();

  return CalculoUnidades(
    baseId: menor.key.unidadId,
    factorCompraBase: factorCompraBase,
    costoBase: costoBase,
    filas: filas,
  );
}

/// Al editar, reconstruye "trae N unidades" en la unidad más grande que quepa
/// exacta, para no mostrar "50000 gramos" cuando el usuario escribió "50 kilos".
/// Se descartan las que darían cantidad 1 (un saco "trae 1 saco" no informa).
({String cantidad, int? unidadContenidoId}) describirContenido(
  List<Map<String, dynamic>> unidades,
  int? baseId,
  dynamic factorCompraBase,
) {
  final total = double.tryParse('$factorCompraBase') ?? 0;
  final base = buscarUnidad(unidades, baseId);
  if (total <= 0 || base == null) {
    return (cantidad: '', unidadContenidoId: baseId);
  }

  final canonico = total * _factorDe(base);
  final candidatas = unidades.where((u) {
    final f = _factorDe(u);
    return canonico % f == 0 && canonico / f > 1;
  }).toList()
    ..sort((a, b) => _factorDe(b).compareTo(_factorDe(a)));

  final elegida = candidatas.isNotEmpty ? candidatas.first : base;
  final cantidad = canonico / _factorDe(elegida);

  return (
    cantidad: sinCerosSobrantes(cantidad),
    unidadContenidoId: int.tryParse('${elegida['id']}'),
  );
}

/// 3.5 y 0.0035 en vez de 3.5000: hasta 4 decimales, sin ceros de relleno.
String sinCerosSobrantes(double n, [int decimales = 4]) {
  var s = n.toStringAsFixed(decimales);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
  }
  return s;
}
