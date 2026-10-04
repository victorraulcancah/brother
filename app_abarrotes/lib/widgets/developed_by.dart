import 'package:flutter/material.dart';

/// Firma del software: "Desarrollado por" + logo de BRINTECH. Si el logo no
/// carga, no muestra nada (es un detalle, no debe romper la pantalla).
class DevelopedBy extends StatelessWidget {
  final double height;

  const DevelopedBy({super.key, this.height = 56});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'DESARROLLADO POR',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).hintColor,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Image.asset(
          'assets/images/brintech.png',
          height: height,
          fit: BoxFit.contain,
          semanticLabel: 'BRINTECH Technology Consulting',
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
