import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Una fila `etiqueta → valor` dentro de una [DataCard].
class DataCardRow {
  final String label;
  final Widget value;

  const DataCardRow({required this.label, required this.value});

  /// Atajo cuando el valor es texto plano.
  factory DataCardRow.text(String label, String value) => DataCardRow(
    label: label,
    value: Text(value, textAlign: TextAlign.end),
  );
}

/// Una acción (icono) de la fila "Acciones".
class DataCardAction {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  const DataCardAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });
}

/// Tarjeta para listar un registro como "tabla en card":
/// un título, filas de etiqueta→valor y una fila de acciones.
///
/// Se usa dentro de un `ListView` para reemplazar tablas anchas en móvil.
class DataCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<DataCardRow> rows;
  final List<DataCardAction> actions;
  final VoidCallback? onTap;

  const DataCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.rows,
    this.actions = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textStrong,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RowItem(label: row.label, value: row.value),
                ),
              if (actions.isNotEmpty)
                _RowItem(
                  label: 'Acciones',
                  value: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final action in actions)
                        IconButton(
                          onPressed: action.onTap,
                          icon: Icon(
                            action.icon,
                            color: action.color,
                            size: 20,
                          ),
                          tooltip: action.tooltip,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final Widget value;

  const _RowItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        Expanded(
          flex: 6,
          child: Align(
            alignment: Alignment.centerRight,
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: AppColors.textStrong,
                fontWeight: FontWeight.w500,
              ),
              child: value,
            ),
          ),
        ),
      ],
    );
  }
}
