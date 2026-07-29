import 'package:flutter/material.dart';
import 'app_routes.dart';

/// Un ítem del menú lateral.
class MenuItem {
  final IconData icon;
  final String label;
  final String route;

  const MenuItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

/// Menú de navegación de la app, definido UNA sola vez.
///
/// El sidebar (`AppSidebar`) se construye a partir de esta lista, así
/// que agregar/quitar una sección es cambiar solo este archivo.
class AppMenu {
  AppMenu._();

  static const List<MenuItem> items = [
    MenuItem(icon: Icons.home_outlined, label: 'Inicio', route: AppRoutes.home),
    MenuItem(
      icon: Icons.people_alt_outlined,
      label: 'Usuarios',
      route: AppRoutes.usuarios,
    ),
    MenuItem(
      icon: Icons.inventory_2_outlined,
      label: 'Productos',
      route: AppRoutes.productos,
    ),
    MenuItem(
      icon: Icons.point_of_sale_outlined,
      label: 'Ventas',
      route: AppRoutes.ventas,
    ),
    MenuItem(
      icon: Icons.warehouse_outlined,
      label: 'Inventario',
      route: AppRoutes.inventario,
    ),
    MenuItem(
      icon: Icons.people_outline,
      label: 'Clientes',
      route: AppRoutes.clientes,
    ),
    MenuItem(
      icon: Icons.settings_outlined,
      label: 'Configuración',
      route: AppRoutes.configuracion,
    ),
  ];
}
