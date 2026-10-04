import 'package:flutter/material.dart';
import 'app_button.dart';
import 'app_text_field.dart';

/// Contenido de un modal que pide un motivo (anular una venta, cancelar un
/// pedido...). Devuelve el texto escrito con `Navigator.pop`; el que lo abre
/// decide qué hacer si viene vacío.
///
/// Uso: `showAppModal<String>(context, title: ..., child: const MotivoSheet(...))`.
class MotivoSheet extends StatefulWidget {
  final String label;
  final String confirmLabel;

  const MotivoSheet({
    super.key,
    required this.label,
    required this.confirmLabel,
  });

  @override
  State<MotivoSheet> createState() => _MotivoSheetState();
}

class _MotivoSheetState extends State<MotivoSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(controller: _ctrl, label: widget.label, icon: Icons.edit_note),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SecondaryButton(label: 'Cancelar', onPressed: () => Navigator.pop(context))),
            const SizedBox(width: 12),
            Expanded(child: PrimaryButton(label: widget.confirmLabel, onPressed: () => Navigator.pop(context, _ctrl.text))),
          ],
        ),
      ],
    );
  }
}
