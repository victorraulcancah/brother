import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Selector de pestañas controlado por el padre.
///
/// [AppTabs] maneja su propio TabController y exige dar el contenido de cada
/// pestaña; esto sirve cuando la pantalla solo quiere saber cuál está elegida
/// para filtrar una misma lista.
///
/// Con pocas pestañas se reparten el ancho; con muchas (o con [scrollable])
/// cada una toma su ancho natural y la fila se desplaza en horizontal.
class AppSegmented extends StatelessWidget {
  final List<String> items;
  final int selected;
  final ValueChanged<int> onChanged;

  /// Icono opcional por pestaña, alineado con [items].
  final List<IconData>? icons;

  /// Fuerza el modo desplazable aunque haya pocas pestañas.
  final bool scrollable;

  const AppSegmented({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.icons,
    this.scrollable = false,
  }) : assert(icons == null || icons.length == items.length);

  @override
  Widget build(BuildContext context) {
    // Mas de tres pestañas ya no caben repartidas en un movil.
    final desplazable = scrollable || items.length > 3;

    final chips = [
      for (var i = 0; i < items.length; i++)
        _Chip(
          label: items[i],
          icon: icons?[i],
          selected: selected == i,
          expand: !desplazable,
          onTap: () => onChanged(i),
        ),
    ];

    final barra = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: chips),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: desplazable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: barra,
            )
          : SizedBox(width: double.infinity, child: barra),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool expand;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.expand,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;

    final chip = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );

    return expand ? Expanded(child: chip) : chip;
  }
}
