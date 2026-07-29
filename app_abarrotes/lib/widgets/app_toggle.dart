import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Interruptor on/off con etiqueta (como el Toggle de Filament).
class AppToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  const AppToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      title: Text(label),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      activeThumbColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}
