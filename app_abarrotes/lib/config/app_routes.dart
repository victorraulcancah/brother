class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  static const String home = '/home';

  // Gestión
  static const String roles = '/roles';
  static const String usuarios = '/usuarios';
  static const String empresa = '/empresa';

  // Catálogo
  static const String productos = '/productos';
  static const String categorias = '/categorias';
  static const String marcas = '/marcas';
  static const String subMarcas = '/sub-marcas';
  static const String unidades = '/unidades';

  // Compras
  static const String proveedores = '/proveedores';
  static const String ordenesCompra = '/ordenes-compra';
  static const String solicitudesCompra = '/solicitudes-compra';
  static const String recepcionesCompra = '/recepciones-compra';

  // Inventario
  static const String almacenes = '/almacenes';
  static const String movimientos = '/movimientos';
  static const String tomasInventario = '/tomas-inventario';

  static const String traslados = '/transferencias';
  static const String ajustes = '/ajustes';
  static const String prestamos = '/prestamos';

  // Compras
  static const String compras = '/compras';

  // Ventas
  static const String clientes = '/clientes';
  static const String notasVenta = '/notas-venta';

  // Tesorería
  static const String cuentasMedios = '/cuentas-medios';
  static const String cajas = '/cajas';
  static const String movimientosCaja = '/movimientos-caja';
  static const String motivosMovimiento = '/motivos-movimiento';
  static const String cuentasPorCobrar = '/cuentas-por-cobrar';
  static const String reportesUtilidades = '/reportes/utilidades';
  static const String cuentasPorPagar = '/cuentas-por-pagar';
}
