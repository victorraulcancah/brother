import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';

String _money(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return 'S/ ${n.toStringAsFixed(2)}';
}

double _n(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;

const _meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

String _fechaIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _fechaCorta(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _etiquetaGrupo(String g, String agrupar) {
  if (agrupar != 'mes') return g;
  final p = g.split('-');
  if (p.length < 2) return g;
  final m = int.tryParse(p[1]) ?? 1;
  return '${_meses[(m - 1).clamp(0, 11)]} ${p[0].substring(2)}';
}

class UtilidadesScreen extends StatefulWidget {
  const UtilidadesScreen({super.key});

  @override
  State<UtilidadesScreen> createState() => _UtilidadesScreenState();
}

class _UtilidadesScreenState extends State<UtilidadesScreen> {
  final ApiService _api = ApiService();
  late DateTime _desde;
  late DateTime _hasta;
  String _agrupar = 'mes';
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _hasta = hoy;
    _desde = DateTime(hoy.year, hoy.month - 11, 1);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get(
        '${ApiEndpoints.reportesUtilidades}?desde=${_fechaIso(_desde)}&hasta=${_fechaIso(_hasta)}&agrupar=$_agrupar',
      );
      if (res is Map<String, dynamic>) _data = res;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filas =>
      ((_data?['filas']) as List? ?? []).cast<Map<String, dynamic>>();
  Map<String, dynamic> get _tot => (_data?['totales'] as Map?)?.cast<String, dynamic>() ?? {};

  Future<void> _pickFecha(bool esDesde) async {
    final sel = await showDatePicker(
      context: context,
      initialDate: esDesde ? _desde : _hasta,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (sel != null) {
      setState(() => esDesde ? _desde = sel : _hasta = sel);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Utilidades',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _filtros(),
                  const SizedBox(height: 16),
                  _totales(),
                  const SizedBox(height: 16),
                  _grafico(),
                  const SizedBox(height: 16),
                  _tabla(),
                ],
              ),
            ),
    );
  }

  Widget _filtros() {
    Widget fechaBtn(String label, DateTime d, bool esDesde) => Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickFecha(esDesde),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                Text(_fechaCorta(d), style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        );
    return Column(
      children: [
        Row(children: [
          fechaBtn('Desde', _desde, true),
          const SizedBox(width: 8),
          fechaBtn('Hasta', _hasta, false),
        ]),
        const SizedBox(height: 8),
        AppSelect<String>(
          label: 'Agrupar por',
          value: _agrupar,
          options: const [
            AppSelectOption('mes', 'Mes'),
            AppSelectOption('producto', 'Producto'),
            AppSelectOption('categoria', 'Categoría'),
          ],
          onChanged: (v) {
            setState(() => _agrupar = v ?? 'mes');
            _load();
          },
        ),
      ],
    );
  }

  Widget _totales() {
    final items = [
      ('Ventas', _money(_tot['ventas']), AppColors.textStrong),
      ('Costo', _money(_tot['costo']), AppColors.warning),
      ('Util. bruta', _money(_tot['utilidad_bruta']), _n(_tot['utilidad_bruta']) < 0 ? AppColors.danger : AppColors.info),
      ('Gastos', _money(_tot['gastos']), AppColors.danger),
      ('Utilidad neta', _money(_tot['utilidad_neta']), _n(_tot['utilidad_neta']) < 0 ? AppColors.danger : AppColors.success),
      ('Margen', '${_tot['margen'] ?? 0}%', _n(_tot['margen']) < 0 ? AppColors.danger : AppColors.primary),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        for (final it in items)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(it.$1, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(it.$2,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: it.$3)),
              ],
            ),
          ),
      ],
    );
  }

  /// Etiqueta corta del eje Y (12.5k, -3k, 250).
  static String _compacto(double v) {
    final a = v.abs();
    final t = a >= 1000000
        ? '${(a / 1000000).toStringAsFixed(1)}M'
        : a >= 1000
        ? '${(a / 1000).toStringAsFixed(a >= 10000 ? 0 : 1)}k'
        : a.toStringAsFixed(0);
    return v < 0 ? '-$t' : t;
  }

  Widget _grafico() {
    final filas = _filas.take(12).toList();
    if (filas.isEmpty) {
      return const _Card('Utilidad neta', SizedBox(height: 60, child: Center(child: Text('Sin datos'))));
    }
    // Igual que la web: ventas, costo y utilidad neta (que puede ser negativa).
    double maxV = 0, minV = 0;
    for (final f in filas) {
      for (final v in [_n(f['ventas']), _n(f['costo']), _n(f['utilidad_neta'])]) {
        if (v > maxV) maxV = v;
        if (v < minV) minV = v;
      }
    }
    if (maxV == 0 && minV == 0) maxV = 1;
    final maxY = maxV * 1.15;
    final minY = minV < 0 ? minV * 1.15 : 0.0;
    final ancho = filas.length > 8 ? 4.0 : filas.length > 4 ? 6.0 : 9.0;

    BarChartRodData rod(double v, Color c) => BarChartRodData(
      fromY: 0,
      toY: v,
      color: c,
      width: ancho,
      borderRadius: v >= 0
          ? const BorderRadius.vertical(top: Radius.circular(3))
          : const BorderRadius.vertical(bottom: Radius.circular(3)),
    );

    Widget leyenda(Color c, String t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(t, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );

    return _Card(
      _agrupar == 'mes' ? 'Ventas, costo y utilidad por mes' : 'Ventas, costo y utilidad',
      Column(
        children: [
          SizedBox(
            height: 220,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: minY,
              groupsSpace: 8,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY - minY) / 4,
                getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
              ),
              // Línea del cero para leer los negativos.
              extraLinesData: ExtraLinesData(
                horizontalLines: [HorizontalLine(y: 0, color: AppColors.textMuted, strokeWidth: 1)],
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gi, rodData, ri) => BarTooltipItem(
                    '${['Ventas', 'Costo', 'Utilidad'][ri]}: ${_money(rodData.toY)}',
                    const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: (maxY - minY) / 4,
                    getTitlesWidget: (value, meta) => Text(
                      _compacto(value),
                      style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= filas.length) return const SizedBox.shrink();
                      final lbl = _etiquetaGrupo('${filas[i]['grupo']}', _agrupar);
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _agrupar == 'mes' ? lbl.split(' ').first : '${i + 1}',
                          style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < filas.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 2,
                    barRods: [
                      rod(_n(filas[i]['ventas']), AppColors.primary),
                      rod(_n(filas[i]['costo']), const Color(0xFFF0B27A)),
                      rod(_n(filas[i]['utilidad_neta']), _n(filas[i]['utilidad_neta']) < 0 ? AppColors.danger : AppColors.success),
                    ],
                  ),
              ],
            )),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              leyenda(AppColors.primary, 'Ventas'),
              leyenda(const Color(0xFFF0B27A), 'Costo'),
              leyenda(AppColors.success, 'Utilidad neta'),
              leyenda(AppColors.danger, 'Pérdida'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabla() {
    final filas = _filas;
    if (filas.isEmpty) return const SizedBox.shrink();
    return _Card('Detalle', Column(
      children: [
        for (final f in filas) ...[
          Row(
            children: [
              Expanded(
                child: Text(_etiquetaGrupo('${f['grupo']}', _agrupar),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text(_money(f['utilidad_neta']),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _n(f['utilidad_neta']) < 0 ? AppColors.danger : AppColors.success,
                  )),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ventas ${_money(f['ventas'])} · Costo ${_money(f['costo'])}'
                    '${_agrupar == 'mes' ? ' · Gastos ${_money(f['gastos'])}' : ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
                Text('${f['margen'] ?? 0}%', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ],
    ));
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card(this.title, this.child);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textStrong)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
