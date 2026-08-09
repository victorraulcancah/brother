class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/login';
  static const String register = '/register';
  static const String me = '/me';
  static const String logout = '/logout';

  static const String dashboard = '/dashboard';
  static const String alertas = '/alertas';
  static const String reportesUtilidades = '/reportes/utilidades';

  static const String empresas = '/empresas';
  static String empresa(int id) => '/empresas/$id';

  static const String productos = '/productos';
  static String producto(int id) => '/productos/$id';
  static String presentaciones(int productoId) => '/productos/$productoId/presentaciones';
  static const String presentacionesBase = '/presentaciones';
  static String presentacion(int id) => '/presentaciones/$id';

  static const String categorias = '/categorias';
  static const String marcas = '/marcas';
  static const String subMarcas = '/sub-marcas';

  static const String unidades = '/unidades-medida';
  static String unidad(int id) => '/unidades-medida/$id';

  static const String proveedores = '/proveedores';
  static String proveedor(int id) => '/proveedores/$id';

  static const String almacenes = '/almacenes';
  static String almacen(int id) => '/almacenes/$id';
  static const String existencias = '/existencias';

  static const String movimientos = '/movimientos';
  static String movimiento(int id) => '/movimientos/$id';

  static const String transferencias = '/transferencias';
  static String transferencia(int id) => '/transferencias/$id';

  static const String solicitudes = '/solicitudes-compra';
  static String solicitud(int id) => '/solicitudes-compra/$id';

  static const String ordenes = '/ordenes-compra';
  static String orden(int id) => '/ordenes-compra/$id';

  static const String recepciones = '/recepciones-compra';
  static String recepcion(int id) => '/recepciones-compra/$id';
  /// Revierte el stock que ingreso la recepcion y la deja inactiva.
  static String recepcionDeshacer(int id) => '/recepciones-compra/$id/deshacer';

  static const String tomas = '/tomas-inventario';
  static String toma(int id) => '/tomas-inventario/$id';

  static const String ajustes = '/ajustes';
  static String ajuste(int id) => '/ajustes/$id';

  static const String prestamos = '/prestamos';
  static String prestamo(int id) => '/prestamos/$id';

  // Ventas
  static const String clientes = '/clientes';
  static String cliente(int id) => '/clientes/$id';
  static const String notasVenta = '/notas-venta';
  static String notaVenta(int id) => '/notas-venta/$id';

  // Compras
  static const String compras = '/compras';
  static String compra(int id) => '/compras/$id';
  static String compraAnular(int id) => '/compras/$id/anular';
  /// Cierra lo que ya no va a llegar del proveedor.
  static String compraFinalizar(int id) => '/compras/$id/finalizar';
  /// Lineas de la compra con lo pedido, lo recibido y lo pendiente.
  static String compraPendientes(int id) => '/compras/$id/pendientes-recepcion';

  // Tesorería
  static const String bancos = '/bancos';
  static const String cuentasBancarias = '/cuentas-bancarias';
  static const String tarjetasBancarias = '/tarjetas-bancarias';
  static const String billeterasDigitales = '/billeteras-digitales';
  static const String cierresCaja = '/cierres-caja';
  static String cierreCaja(int id) => '/cierres-caja/$id';

  static const String cajas = '/cajas';
  static String caja(int id) => '/cajas/$id';
  static const String miCaja = '/mi-caja';
  static const String miCajaAbrir = '/mi-caja/abrir';
  static const String miCajaCerrar = '/mi-caja/cerrar';
  static const String movimientosCaja = '/movimientos-caja';
  static const String metodosPago = '/metodos-pago';
  static const String motivosMovimiento = '/motivos-movimiento';
  static const String cuentasPorCobrar = '/cuentas-por-cobrar';
  static const String cuentasPorPagar = '/cuentas-por-pagar';

  static const String usuarios = '/users';
  static String usuario(int id) => '/users/$id';
  static String assignRole(int id) => '/users/$id/assign-role';

  static const String roles = '/roles';
}
