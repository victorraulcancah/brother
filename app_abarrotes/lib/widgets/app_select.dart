import 'package:flutter/material.dart';

/// Una opción de un [AppSelect].
class AppSelectOption<T> {
  final T value;
  final String label;
  const AppSelectOption(this.value, this.label);
}

/// Desplegable (dropdown) con el mismo estilo que [AppTextField].
/// Hereda la decoración del `inputDecorationTheme` del tema.
class AppSelect<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final IconData? icon;
  final String? Function(T?)? validator;

  const AppSelect({
    super.key,
    required this.label,
    required this.options,
    this.value,
    this.onChanged,
    this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      items: [
        for (final option in options)
          DropdownMenuItem<T>(value: option.value, child: Text(option.label)),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }
}
