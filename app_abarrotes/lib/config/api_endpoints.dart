class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/login';
  static const String register = '/register';
  static const String me = '/me';
  static const String logout = '/logout';

  static const String empresas = '/empresas';
  static String empresa(int id) => '/empresas/$id';

  static const String productos = '/productos';
  static String producto(int id) => '/productos/$id';

  static const String categorias = '/categorias';
  static const String subCategorias = '/sub-categorias';
  static const String marcas = '/marcas';
  static const String subMarcas = '/sub-marcas';
  static const String atributos = '/atributos';
  static const String atributoValores = '/atributo-valores';

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

  static const String tomas = '/tomas-inventario';
  static String toma(int id) => '/tomas-inventario/$id';

  static const String ajustes = '/ajustes';
  static String ajuste(int id) => '/ajustes/$id';

  static const String costeo = '/costeo';

  static const String usuarios = '/users';
  static String usuario(int id) => '/users/$id';
  static String assignRole(int id) => '/users/$id/assign-role';

  static const String roles = '/roles';
}
