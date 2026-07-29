import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_routes.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/placeholder_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
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
          AppRoutes.productos: (_) => const PlaceholderScreen(
            title: 'Productos',
            icon: Icons.inventory_2_outlined,
          ),
          AppRoutes.ventas: (_) => const PlaceholderScreen(
            title: 'Ventas',
            icon: Icons.point_of_sale_outlined,
          ),
          AppRoutes.inventario: (_) => const PlaceholderScreen(
            title: 'Inventario',
            icon: Icons.warehouse_outlined,
          ),
          AppRoutes.clientes: (_) => const PlaceholderScreen(
            title: 'Clientes',
            icon: Icons.people_outline,
          ),
          AppRoutes.configuracion: (_) => const PlaceholderScreen(
            title: 'Configuración',
            icon: Icons.settings_outlined,
          ),
        },
      ),
    );
  }
}
