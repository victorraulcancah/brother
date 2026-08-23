import 'package:flutter_test/flutter_test.dart';
import 'package:app_abarrotes/utils/unidades.dart';

/// Mismas unidades que siembra el backend (CatalogSeeder).
final unidades = <Map<String, dynamic>>[
  {'id': 1, 'nombre': 'Unidad', 'abreviatura': 'u', 'factor_base': 1},
  {'id': 2, 'nombre': 'Kilogramo', 'abreviatura': 'kg', 'factor_base': 1000},
  {'id': 3, 'nombre': 'Gramo', 'abreviatura': 'g', 'factor_base': 1},
  {'id': 4, 'nombre': 'Litro', 'abreviatura': 'l', 'factor_base': 1000},
  {'id': 5, 'nombre': 'Mililitro', 'abreviatura': 'ml', 'factor_base': 1},
  {'id': 6, 'nombre': 'Bolsa', 'abreviatura': 'bolsa', 'factor_base': 1},
  {'id': 7, 'nombre': 'Caja', 'abreviatura': 'caja', 'factor_base': 1},
  {'id': 8, 'nombre': 'Paquete', 'abreviatura': 'pqte', 'factor_base': 1},
  {'id': 9, 'nombre': 'Galón', 'abreviatura': 'gal', 'factor_base': 3785},
  {'id': 10, 'nombre': 'Saco', 'abreviatura': 'saco', 'factor_base': 1},
  {'id': 11, 'nombre': 'Docena', 'abreviatura': 'doc', 'factor_base': 12},
];

void main() {
  group('compro / vendo', () {
    test('arroz: saco de 50 kg a S/140, vendo por kilo y por gramo', () {
      final r = calcularPresentaciones(
        unidades: unidades,
        compra: const CompraInput(
          unidadCompraId: 10,
          cantidad: 50,
          unidadContenidoId: 2,
          precio: 140,
        ),
        ventas: const [
          VentaInput(unidadId: 2, margen: 25),
          VentaInput(unidadId: 3, margen: 25),
        ],
      );

      expect(r.baseId, 3, reason: 'la base debe ser el gramo');
      expect(r.factorCompraBase, 50000);
      expect(r.costoBase, closeTo(0.0028, 1e-9));

      final kilo = r.filaDe(2)!;
      expect(kilo.factor, 1000);
      expect(kilo.precioCompra, closeTo(2.80, 1e-9));
      expect(kilo.precioVenta, closeTo(3.50, 1e-9));
      expect(kilo.ganancia, closeTo(0.70, 1e-9));

      final gramo = r.filaDe(3)!;
      expect(gramo.factor, 1);
      expect(gramo.precioCompra, closeTo(0.0028, 1e-9));
      expect(gramo.precioVenta, closeTo(0.0035, 1e-9));
    });

    test('aceite: caja de 12 a S/96, vendo por unidad', () {
      final r = calcularPresentaciones(
        unidades: unidades,
        compra: const CompraInput(
          unidadCompraId: 7,
          cantidad: 12,
          unidadContenidoId: 1,
          precio: 96,
        ),
        ventas: const [VentaInput(unidadId: 1, margen: 25)],
      );

      expect(r.baseId, 1);
      expect(r.factorCompraBase, 12);
      expect(r.costoBase, closeTo(8, 1e-9));

      final unidad = r.filaDe(1)!;
      expect(unidad.factor, 1);
      expect(unidad.precioCompra, closeTo(8, 1e-9));
      expect(unidad.precioVenta, closeTo(10, 1e-9));
    });

    test('vender también el saco entero no cambia la unidad base', () {
      final r = calcularPresentaciones(
        unidades: unidades,
        compra: const CompraInput(
          unidadCompraId: 10,
          cantidad: 50,
          unidadContenidoId: 2,
          precio: 140,
        ),
        ventas: const [
          VentaInput(unidadId: 2, margen: 25),
          VentaInput(unidadId: 3, margen: 25),
          VentaInput(unidadId: 10, margen: 10),
        ],
      );

      expect(r.baseId, 3);
      final saco = r.filaDe(10)!;
      expect(saco.factor, 50000);
      expect(saco.precioCompra, closeTo(140, 1e-9));
      expect(saco.precioVenta, closeTo(154, 1e-9));
    });

    test('el precio escrito a mano manda sobre el margen', () {
      final r = calcularPresentaciones(
        unidades: unidades,
        compra: const CompraInput(
          unidadCompraId: 7,
          cantidad: 12,
          unidadContenidoId: 1,
          precio: 96,
        ),
        ventas: const [VentaInput(unidadId: 1, margen: 25, precioVenta: 12)],
      );

      expect(r.filaDe(1)!.precioVenta, 12);
    });

    test('sin formatos de venta no revienta', () {
      final r = calcularPresentaciones(
        unidades: unidades,
        compra: const CompraInput(unidadCompraId: 10, cantidad: 50, unidadContenidoId: 2, precio: 140),
        ventas: const [VentaInput()],
      );

      expect(r.baseId, isNull);
      expect(r.filas, isEmpty);
    });

    test('precio de compra en cero no divide por cero', () {
      final r = calcularPresentaciones(
        unidades: unidades,
        compra: const CompraInput(unidadCompraId: 10, cantidad: 50, unidadContenidoId: 2, precio: 0),
        ventas: const [VentaInput(unidadId: 2, margen: 25)],
      );

      expect(r.costoBase, 0);
      expect(r.filaDe(2)!.precioVenta, 0);
    });

    test('cantidad en cero deja el cálculo neutro', () {
      final r = calcularPresentaciones(
        unidades: unidades,
        compra: const CompraInput(unidadCompraId: 10, cantidad: 0, unidadContenidoId: 2, precio: 140),
        ventas: const [VentaInput(unidadId: 2, margen: 25)],
      );

      expect(r.factorCompraBase, 0);
      expect(r.costoBase, 0);
    });
  });

  group('al editar', () {
    test('50000 gramos se describen como 50 kilogramos', () {
      final d = describirContenido(unidades, 3, 50000);
      expect(d.cantidad, '50');
      expect(d.unidadContenidoId, 2);
    });

    test('12 unidades se describen como 12 unidades, no 1 docena', () {
      final d = describirContenido(unidades, 1, 12);
      expect(d.cantidad, '12');
      expect(d.unidadContenidoId, 1);
    });
  });

  test('sinCerosSobrantes recorta el relleno', () {
    expect(sinCerosSobrantes(3.5), '3.5');
    expect(sinCerosSobrantes(0.0035), '0.0035');
    expect(sinCerosSobrantes(10), '10');
  });
}
