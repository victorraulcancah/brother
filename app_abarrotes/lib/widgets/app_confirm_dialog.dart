import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Diálogo de confirmación (Sí/No). Devuelve `true` si el usuario confirma.
/// Uso: `if (await showAppConfirmDialog(context, ...)) { ... }`
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Eliminar',
  String cancelText = 'Cancelar',
  bool danger = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: danger ? AppColors.danger : AppColors.primary,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}
