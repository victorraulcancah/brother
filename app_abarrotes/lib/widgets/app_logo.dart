import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Logo BRAVA reutilizable. Muestra el logo horizontal desde assets y,
/// si falla la carga, cae a una insignia con la inicial de la marca.
class AppLogo extends StatelessWidget {
  final double height;

  const AppLogo({super.key, this.height = 88});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/brava-horizontal.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _Fallback(size: height),
    );
  }
}

class _Fallback extends StatelessWidget {
  final double size;
  const _Fallback({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        'B',
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
