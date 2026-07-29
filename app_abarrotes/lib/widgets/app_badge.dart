import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppBadgeType { success, danger, warning, info, neutral }

/// Etiqueta/pill de estado ("Activo", "Pendiente"...).
/// El color sale de [AppColors] según el tipo; nada quemado.
class AppBadge extends StatelessWidget {
  final String text;
  final AppBadgeType type;

  const AppBadge(this.text, {super.key, this.type = AppBadgeType.neutral});

  Color get _color => switch (type) {
    AppBadgeType.success => AppColors.success,
    AppBadgeType.danger => AppColors.danger,
    AppBadgeType.warning => AppColors.warning,
    AppBadgeType.info => AppColors.info,
    AppBadgeType.neutral => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
