import '../widgets/app_select.dart';

/// Opciones de almacén para formularios de operación (ventas, traslados,
/// ajustes, tomas, préstamos, recepciones).
///
/// Solo se ofrecen los almacenes activos: desactivar uno debe impedir que siga
/// recibiendo movimientos, no ser solo una etiqueta. El almacén ya elegido se
/// conserva aunque esté inactivo — al abrir un documento antiguo el selector no
/// debe vaciarse en silencio — y se marca para que se note.
///
/// En los filtros de listados NO se usa esto: ahí deben verse todos, porque el
/// historial de un almacén desactivado se sigue consultando.
///
/// Equivale a `resources/js/lib/almacenes.js` en la web.
List<AppSelectOption<int>> opcionesAlmacen(
  List<Map<String, dynamic>> almacenes, [
  int? seleccionadoId,
]) {
  return almacenes
      .where((a) => a['activo'] != false || a['id'] == seleccionadoId)
      .map((a) {
        final nombre = a['nombre']?.toString() ?? '';
        return AppSelectOption<int>(
          a['id'] as int,
          a['activo'] == false ? '$nombre (inactivo)' : nombre,
        );
      })
      .toList();
}
