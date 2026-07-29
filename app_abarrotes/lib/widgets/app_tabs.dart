import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Una pestaña con icono, etiqueta y su contenido.
class AppTab {
  final IconData icon;
  final String label;
  final Widget content;

  const AppTab({
    required this.icon,
    required this.label,
    required this.content,
  });
}

/// Pestañas con iconos (como Tabs de Filament), estilo BRAVA.
/// Se coloca dentro de un cuerpo con altura definida (ej. body de Scaffold).
class AppTabs extends StatelessWidget {
  final List<AppTab> tabs;

  const AppTabs({super.key, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              tabs: [
                for (final tab in tabs)
                  Tab(icon: Icon(tab.icon, size: 20), text: tab.label),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(children: [for (final tab in tabs) tab.content]),
          ),
        ],
      ),
    );
  }
}
