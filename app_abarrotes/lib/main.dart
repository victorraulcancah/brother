import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_routes.dart';
import 'providers/auth_provider.dart';
import 'screens/ajustes_screen.dart';
import 'screens/almacenes_screen.dart';
import 'screens/cajas_screen.dart';
import 'screens/categorias_screen.dart';
import 'screens/clientes_screen.dart';
import 'screens/compras_screen.dart';
import 'screens/cuentas_medios_screen.dart';
import 'screens/cuentas_por_cobrar_screen.dart';
import 'screens/cuentas_por_pagar_screen.dart';
import 'screens/empresa_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/marcas_screen.dart';
import 'screens/mi_caja_screen.dart';
import 'screens/motivos_movimiento_screen.dart';
import 'screens/movimientos_screen.dart';
import 'screens/movimientos_caja_screen.dart';
import 'screens/notas_venta_screen.dart';
import 'screens/prestamos_screen.dart';
import 'screens/traslados_screen.dart';
import 'screens/ordenes_compra_screen.dart';
import 'screens/productos_screen.dart';
import 'screens/proveedores_screen.dart';
import 'screens/recepciones_compra_screen.dart';
import 'screens/register_screen.dart';
import 'screens/roles_screen.dart';
import 'screens/solicitudes_compra_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/submarcas_screen.dart';
import 'screens/tomas_inventario_screen.dart';
import 'screens/unidades_screen.dart';
import 'screens/usuarios_screen.dart';
import 'screens/utilidades_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'BRAVA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.home: (_) => const HomeScreen(),
          AppRoutes.roles: (_) => const RolesScreen(),
          AppRoutes.usuarios: (_) => const UsuariosScreen(),
          AppRoutes.empresa: (_) => const EmpresaScreen(),
          AppRoutes.productos: (_) => const ProductosScreen(),
          AppRoutes.categorias: (_) => const CategoriasScreen(),
          AppRoutes.marcas: (_) => const MarcasScreen(),
          AppRoutes.subMarcas: (_) => const SubMarcasScreen(),
          AppRoutes.unidades: (_) => const UnidadesScreen(),
          AppRoutes.proveedores: (_) => const ProveedoresScreen(),
          AppRoutes.ordenesCompra: (_) => const OrdenesCompraScreen(),
          AppRoutes.solicitudesCompra: (_) => const SolicitudesCompraScreen(),
          AppRoutes.recepcionesCompra: (_) => const RecepcionesCompraScreen(),
          AppRoutes.almacenes: (_) => const AlmacenesScreen(),
          AppRoutes.movimientos: (_) => const MovimientosScreen(),
          AppRoutes.tomasInventario: (_) => const TomasInventarioScreen(),
          AppRoutes.traslados: (_) => const TrasladosScreen(),
          AppRoutes.ajustes: (_) => const AjustesScreen(),
          AppRoutes.prestamos: (_) => const PrestamosScreen(),
          AppRoutes.compras: (_) => const ComprasScreen(),
          AppRoutes.clientes: (_) => const ClientesScreen(),
          AppRoutes.notasVenta: (_) => const NotasVentaScreen(),
          AppRoutes.cuentasMedios: (_) => const CuentasMediosScreen(),
          AppRoutes.cajas: (_) => const CajasScreen(),
          AppRoutes.movimientosCaja: (_) => const MovimientosCajaScreen(),
          AppRoutes.motivosMovimiento: (_) => const MotivosMovimientoScreen(),
          AppRoutes.reportesUtilidades: (_) => const UtilidadesScreen(),
          AppRoutes.miCaja: (_) => const MiCajaScreen(),
          AppRoutes.cuentasPorCobrar: (_) => const CuentasPorCobrarScreen(),
          AppRoutes.cuentasPorPagar: (_) => const CuentasPorPagarScreen(),
        },
      ),
    );
  }
}
