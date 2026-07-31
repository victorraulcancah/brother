import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Agrupa campos de un formulario bajo un título (como Section de Filament).
/// Inserta el espaciado entre hijos automáticamente.
class AppFormSection extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? trailing;
  final List<Widget> children;
  final double gap;

  const AppFormSection({
    super.key,
    required this.title,
    this.description,
    this.trailing,
    required this.children,
    this.gap = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      ),
    );
  }
}
