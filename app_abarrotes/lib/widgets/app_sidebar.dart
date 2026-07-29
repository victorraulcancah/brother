import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_routes.dart';
import '../config/menu_items.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';

/// Contenido del menú lateral (sidebar).
///
/// Se usa igual dentro de un `Drawer` (móvil) que como panel fijo
/// (tablet). Toma los ítems de `AppMenu` y el usuario del `AuthProvider`.
class AppSidebar extends StatelessWidget {
  /// Ruta actualmente activa, para resaltarla.
  final String currentRoute;

  /// true cuando es panel fijo (tablet): no cierra un drawer al navegar.
  final bool isPermanent;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    this.isPermanent = false,
  });

  void _onTap(BuildContext context, String route) {
    if (!isPermanent) Navigator.pop(context); // cierra el drawer
    if (route != currentRoute) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  Future<void> _logout(BuildContext context) async {
    if (!isPermanent) Navigator.pop(context);
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const _SidebarHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final item in AppMenu.items)
                  _SidebarTile(
                    item: item,
                    active: item.route == currentRoute,
                    onTap: () => _onTap(context, item.route),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.danger),
            ),
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.name ?? 'BRAVA';
    final email = user?.email ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'B',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (email.isNotEmpty)
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final MenuItem item;
  final bool active;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textStrong;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: active
            ? AppColors.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          leading: Icon(item.icon, color: color),
          title: Text(
            item.label,
            style: TextStyle(
              color: color,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
