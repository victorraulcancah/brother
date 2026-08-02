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
      ('Util. bruta', _money(_tot['utilidad_bruta']), AppColors.info),
      ('Gastos', _money(_tot['gastos']), AppColors.danger),
      ('Utilidad neta', _money(_tot['utilidad_neta']), AppColors.success),
      ('Margen', '${_tot['margen'] ?? 0}%', AppColors.primary),
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

  Widget _grafico() {
    final filas = _filas.take(12).toList();
    if (filas.isEmpty) {
      return const _Card('Utilidad neta', SizedBox(height: 60, child: Center(child: Text('Sin datos'))));
    }
    final maxV = filas.map((f) => _n(f['utilidad_neta'])).fold<double>(0, (a, b) => b > a ? b : a);
    return _Card(
      _agrupar == 'mes' ? 'Utilidad neta por mes' : 'Utilidad neta',
      SizedBox(
        height: 200,
        child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxV <= 0 ? 1 : maxV * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: _n(filas[i]['utilidad_neta']).clamp(0, double.infinity),
                  color: AppColors.success,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ]),
          ],
        )),
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
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success)),
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
