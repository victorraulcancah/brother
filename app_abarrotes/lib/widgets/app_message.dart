import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppMessageType { error, success }

/// Banner de mensaje (error/éxito) con estilo unificado.
/// Los colores salen de [AppColors], no se queman en cada pantalla.
class AppMessage extends StatelessWidget {
  final String text;
  final AppMessageType type;

  const AppMessage({
    super.key,
    required this.text,
    this.type = AppMessageType.error,
  });

  @override
  Widget build(BuildContext context) {
    final isError = type == AppMessageType.error;
    final color = isError ? AppColors.danger : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
