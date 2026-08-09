import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Un filtro desplegable de la cabecera de una lista.
class AppListFilter {
  final String label;
  final String? value;
  final List<AppListFilterOption> options;
  final ValueChanged<String?> onChanged;

  const AppListFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
}

class AppListFilterOption {
  final String? value;
  final String label;
  const AppListFilterOption(this.value, this.label);
}

/// Cabecera de lista con buscador y filtros, equivalente a la barra de
/// herramientas del DataTable de la web.
///
/// El buscador filtra en vivo; los filtros se aplican al elegirlos.
class AppListHeader extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onSearch;
  final String searchValue;
  final List<AppListFilter> filters;
  final VoidCallback? onClearFilters;
  final int activeFilters;
  final int? resultCount;

  const AppListHeader({
    super.key,
    required this.hintText,
    required this.onSearch,
    required this.searchValue,
    this.filters = const [],
    this.onClearFilters,
    this.activeFilters = 0,
    this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: onSearch,
            controller: TextEditingController(text: searchValue)
              ..selection = TextSelection.collapsed(offset: searchValue.length),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchValue.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () => onSearch(''),
                    ),
              isDense: true,
            ),
          ),

          if (filters.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filtro in filters) ...[
                    _FilterChip(filtro: filtro),
                    const SizedBox(width: 8),
                  ],
                  if (activeFilters > 0 && onClearFilters != null)
                    TextButton.icon(
                      onPressed: onClearFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                      label: const Text('Limpiar'),
                    ),
                ],
              ),
            ),
          ],

          if (resultCount != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$resultCount ${resultCount == 1 ? 'resultado' : 'resultados'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Filtro como chip desplegable: ocupa poco y cabe en pantallas chicas.
class _FilterChip extends StatelessWidget {
  final AppListFilter filtro;

  const _FilterChip({required this.filtro});

  @override
  Widget build(BuildContext context) {
    final activo = filtro.value != null && filtro.value!.isNotEmpty;
    final seleccionada = filtro.options.firstWhere(
      (o) => o.value == filtro.value,
      orElse: () => AppListFilterOption(null, filtro.label),
    );

    return PopupMenuButton<String?>(
      initialValue: filtro.value,
      onSelected: filtro.onChanged,
      itemBuilder: (_) => [
        for (final opcion in filtro.options)
          PopupMenuItem<String?>(value: opcion.value, child: Text(opcion.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? AppColors.primary.withValues(alpha: 0.1) : null,
          border: Border.all(
            color: activo ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activo ? seleccionada.label : filtro.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                color: activo ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: activo ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
