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
    MenuLink(icon: Icons.home_outlined, label: 'Dashboard', route: AppRoutes.home),
    MenuGroup(
      icon: Icons.shopping_bag_outlined,
      label: 'Ventas',
      children: [
        MenuLink(icon: Icons.people_outline, label: 'Clientes', route: AppRoutes.clientes),
        MenuLink(icon: Icons.receipt_long_outlined, label: 'Notas de Venta', route: AppRoutes.notasVenta),
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
        MenuLink(icon: Icons.shopping_bag_outlined, label: 'Compras', route: AppRoutes.compras),
        MenuLink(icon: Icons.inventory_outlined, label: 'Recepciones de compra', route: AppRoutes.recepcionesCompra),
      ],
    ),
    MenuGroup(
      icon: Icons.warehouse_outlined,
      label: 'Inventario',
      children: [
        MenuLink(icon: Icons.store_outlined, label: 'Almacenes', route: AppRoutes.almacenes),
        MenuLink(icon: Icons.warehouse_outlined, label: 'Existencias', route: AppRoutes.existencias),
        MenuLink(icon: Icons.swap_vert, label: 'Kardex', route: AppRoutes.movimientos),
        MenuLink(icon: Icons.repeat, label: 'Traslados', route: AppRoutes.traslados),
        MenuLink(icon: Icons.tune, label: 'Ajustes', route: AppRoutes.ajustes),
        MenuLink(icon: Icons.fact_check_outlined, label: 'Tomas de inventario', route: AppRoutes.tomasInventario),
        MenuLink(icon: Icons.handshake_outlined, label: 'Préstamos', route: AppRoutes.prestamos),
      ],
    ),
    MenuGroup(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Tesorería',
      children: [
        MenuLink(icon: Icons.account_balance_wallet, label: 'Mi Caja', route: AppRoutes.miCaja),
        MenuLink(icon: Icons.credit_card, label: 'Cuentas y Medios de Pago', route: AppRoutes.cuentasMedios),
        MenuLink(icon: Icons.point_of_sale_outlined, label: 'Cajas', route: AppRoutes.cajas),
        MenuLink(icon: Icons.swap_horiz, label: 'Movimientos de Caja', route: AppRoutes.movimientosCaja),
        MenuLink(icon: Icons.lock_outline, label: 'Cierres de Caja', route: AppRoutes.cierresCaja),
        MenuLink(icon: Icons.label_outline, label: 'Motivos de Movimiento', route: AppRoutes.motivosMovimiento),
        MenuLink(icon: Icons.call_received, label: 'Cuentas por Cobrar', route: AppRoutes.cuentasPorCobrar),
        MenuLink(icon: Icons.call_made, label: 'Cuentas por Pagar', route: AppRoutes.cuentasPorPagar),
      ],
    ),
    MenuGroup(
      icon: Icons.bar_chart_outlined,
      label: 'Reportes',
      children: [
        MenuLink(icon: Icons.show_chart, label: 'Utilidades', route: AppRoutes.reportesUtilidades),
      ],
    ),
    MenuGroup(
      icon: Icons.tune,
      label: 'Gestión',
      children: [
        MenuLink(icon: Icons.shield_outlined, label: 'Roles', route: AppRoutes.roles),
        MenuLink(icon: Icons.people_alt_outlined, label: 'Usuarios', route: AppRoutes.usuarios),
        MenuLink(icon: Icons.business_outlined, label: 'Empresa', route: AppRoutes.empresa),
      ],
    ),
  ];
}
