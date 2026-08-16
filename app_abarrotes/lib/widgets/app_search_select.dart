import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Opción de [AppSearchSelect]. `keywords` amplía la búsqueda (código, barras…).
class AppSearchOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final String keywords;
  const AppSearchOption(this.value, this.label, {this.subtitle, this.keywords = ''});
}

/// Equivalente móvil del `SearchSelect` de la web: un campo que al tocarlo
/// abre una hoja con buscador y lista filtrable. Con [onSearch] muestra
/// una lupa que delega en un buscador avanzado (p. ej. el de productos).
class AppSearchSelect<T> extends StatelessWidget {
  final String? label;
  final String hint;
  final IconData? icon;
  final T? value;
  final List<AppSearchOption<T>> options;
  final ValueChanged<T?>? onChanged;
  /// Al pulsar la lupa se llama con el texto que el usuario haya escrito.
  final ValueChanged<String>? onSearch;
  final String? searchTooltip;
  final String emptyText;
  final String? errorText;

  const AppSearchSelect({
    super.key,
    this.label,
    this.hint = 'Buscar…',
    this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
    this.onSearch,
    this.searchTooltip,
    this.emptyText = 'Sin coincidencias',
    this.errorText,
  });

  AppSearchOption<T>? get _seleccionada {
    for (final o in options) {
      if (o.value == value) return o;
    }
    return null;
  }

  Future<void> _abrir(BuildContext context) async {
    final r = await showModalBottomSheet<_Resultado<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SearchSheet<T>(
        title: label ?? hint,
        options: options,
        selected: value,
        emptyText: emptyText,
        onSearch: onSearch,
        searchTooltip: searchTooltip,
      ),
    );
    if (r == null) return;
    if (r.abrirBuscador) {
      onSearch?.call(r.query);
    } else {
      onChanged?.call(r.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sel = _seleccionada;
    final habilitado = onChanged != null;
    return InkWell(
      onTap: habilitado ? () => _abrir(context) : null,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        isEmpty: sel == null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          enabled: habilitado,
          prefixIcon: icon == null ? null : Icon(icon),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sel != null && habilitado)
                IconButton(
                  tooltip: 'Limpiar',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => onChanged?.call(null),
                ),
              if (onSearch != null)
                IconButton(
                  tooltip: searchTooltip ?? 'Búsqueda avanzada',
                  icon: const Icon(Icons.manage_search, color: AppColors.primary),
                  onPressed: habilitado ? () => onSearch!('') : null,
                ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        child: sel == null
            ? null
            : Text(sel.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _Resultado<T> {
  final T? value;
  final bool abrirBuscador;
  final String query;
  const _Resultado({this.value, this.abrirBuscador = false, this.query = ''});
}

class _SearchSheet<T> extends StatefulWidget {
  final String title;
  final List<AppSearchOption<T>> options;
  final T? selected;
  final String emptyText;
  final ValueChanged<String>? onSearch;
  final String? searchTooltip;
  const _SearchSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.emptyText,
    this.onSearch,
    this.searchTooltip,
  });

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[áàä]'), 'a')
      .replaceAll(RegExp('[éèë]'), 'e')
      .replaceAll(RegExp('[íìï]'), 'i')
      .replaceAll(RegExp('[óòö]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u');

  List<AppSearchOption<T>> get _filtradas {
    final q = _norm(_ctrl.text.trim());
    if (q.isEmpty) return widget.options;
    final partes = q.split(RegExp(r'\s+'));
    return widget.options.where((o) {
      final heno = _norm('${o.label} ${o.subtitle ?? ''} ${o.keywords}');
      return partes.every(heno.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtradas;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textStrong),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Escribe para filtrar…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: widget.onSearch == null
                        ? null
                        : IconButton(
                            tooltip: widget.searchTooltip ?? 'Búsqueda avanzada',
                            icon: const Icon(Icons.manage_search, color: AppColors.primary),
                            onPressed: () => Navigator.pop(context, _Resultado<T>(abrirBuscador: true, query: _ctrl.text)),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${lista.length} resultado${lista.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
              ),
              const Divider(height: 12),
              Expanded(
                child: lista.isEmpty
                    ? Center(child: Text(widget.emptyText, style: const TextStyle(color: AppColors.textMuted)))
                    : ListView.separated(
                        itemCount: lista.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final o = lista[i];
                          final sel = o.value == widget.selected;
                          return ListTile(
                            dense: true,
                            selected: sel,
                            selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                            title: Text(o.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: o.subtitle == null ? null : Text(o.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: sel ? const Icon(Icons.check, color: AppColors.primary) : null,
                            onTap: () => Navigator.pop(context, _Resultado<T>(value: o.value)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
