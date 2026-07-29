import 'package:flutter/material.dart';
import 'app_routes.dart';

sealed class MenuEntry {
  const MenuEntry();
}

class MenuLink extends MenuEntry {
  final IconData icon;
  final String label;
  final String route;

  const MenuLink({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class MenuGroup extends MenuEntry {
  final IconData icon;
  final String label;
  final List<MenuLink> children;

  const MenuGroup({
    required this.icon,
    required this.label,
    required this.children,
  });
}

class AppMenu {
  AppMenu._();

  static const List<MenuEntry> entries = [
    MenuLink(icon: Icons.home_outlined, label: 'Inicio', route: AppRoutes.home),
    MenuGroup(
      icon: Icons.tune,
      label: 'Gestión',
      children: [
        MenuLink(icon: Icons.shield_outlined, label: 'Roles', route: AppRoutes.roles),
        MenuLink(icon: Icons.people_alt_outlined, label: 'Usuarios', route: AppRoutes.usuarios),
        MenuLink(icon: Icons.business_outlined, label: 'Empresa', route: AppRoutes.empresa),
      ],
    ),
    MenuGroup(
      icon: Icons.book_outlined,
      label: 'Catálogo',
      children: [
        MenuLink(icon: Icons.inventory_2_outlined, label: 'Productos', route: AppRoutes.productos),
        MenuLink(icon: Icons.category_outlined, label: 'Categorías', route: AppRoutes.categorias),
        MenuLink(icon: Icons.sell_outlined, label: 'Marcas', route: AppRoutes.marcas),
        MenuLink(icon: Icons.style_outlined, label: 'Sub-marcas', route: AppRoutes.subMarcas),
        MenuLink(icon: Icons.straighten, label: 'Unidades de medida', route: AppRoutes.unidades),
      ],
    ),
    MenuGroup(
      icon: Icons.shopping_cart_outlined,
      label: 'Compras',
      children: [
        MenuLink(icon: Icons.local_shipping_outlined, label: 'Proveedores', route: AppRoutes.proveedores),
        MenuLink(icon: Icons.receipt_long_outlined, label: 'Órdenes de compra', route: AppRoutes.ordenesCompra),
        MenuLink(icon: Icons.request_quote_outlined, label: 'Solicitudes de compra', route: AppRoutes.solicitudesCompra),
        MenuLink(icon: Icons.inventory_outlined, label: 'Recepciones de compra', route: AppRoutes.recepcionesCompra),
      ],
    ),
    MenuGroup(
      icon: Icons.warehouse_outlined,
      label: 'Inventario',
      children: [
        MenuLink(icon: Icons.warehouse_outlined, label: 'Existencias', route: AppRoutes.almacenes),
        MenuLink(icon: Icons.swap_vert, label: 'Movimientos', route: AppRoutes.movimientos),
        MenuLink(icon: Icons.fact_check_outlined, label: 'Tomas de inventario', route: AppRoutes.tomasInventario),
      ],
    ),
  ];
}
