import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppSnackbarType { success, error, info, warning }

/// Aviso tipo toast, con color e icono según el tipo.
/// Uso: `showAppSnackbar(context, 'Guardado', type: AppSnackbarType.success);`
void showAppSnackbar(
  BuildContext context,
  String message, {
  AppSnackbarType type = AppSnackbarType.info,
}) {
  final color = switch (type) {
    AppSnackbarType.success => AppColors.success,
    AppSnackbarType.error => AppColors.danger,
    AppSnackbarType.info => AppColors.info,
    AppSnackbarType.warning => AppColors.warning,
  };
  final icon = switch (type) {
    AppSnackbarType.success => Icons.check_circle_outline,
    AppSnackbarType.error => Icons.error_outline,
    AppSnackbarType.info => Icons.info_outline,
    AppSnackbarType.warning => Icons.warning_amber_rounded,
  };

  // El SnackBar solo sabe salir abajo, donde tapa los botones flotantes y el
  // teclado. Se lo empuja arriba reservando como margen inferior casi todo el
  // alto de la pantalla; el margen se acota para que nunca quede negativo.
  final media = MediaQuery.of(context);
  final alturaAviso = 72.0;
  final desdeArriba = media.padding.top + 12;
  final margenInferior = (media.size.height - alturaAviso - desdeArriba).clamp(
    0.0,
    double.infinity,
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(left: 16, right: 16, bottom: margenInferior),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
}
