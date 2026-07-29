import 'package:flutter/material.dart';

/// Campo de texto multilínea (como el Textarea de Filament).
/// Hereda la decoración del `inputDecorationTheme` del tema.
class AppTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int minLines;
  final int maxLines;
  final String? Function(String?)? validator;

  const AppTextArea({
    super.key,
    required this.controller,
    required this.label,
    this.minLines = 3,
    this.maxLines = 5,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      validator: validator,
      decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
    );
  }
}
