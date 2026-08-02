import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

String _money(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return 'S/ ${n.toStringAsFixed(2)}';
}

String _num(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);
}

const List<Color> _catColors = [
  Color(0xFFef6c00), Color(0xFFfb8c00), Color(0xFFffa726),
  Color(0xFF8d6e63), Color(0xFF5d2e00), Color(0xFFa9866a),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  int _dias = 30;
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('${ApiEndpoints.dashboard}?dias=$_dias');
      if (res is Map<String, dynamic>) _data = res;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _list(String key) =>
      ((_data?[key]) as List? ?? []).cast<Map<String, dynamic>>();

  Map<String, dynamic> get _kpis => (_data?['kpis'] as Map?)?.cast<String, dynamic>() ?? {};
  Map<String, dynamic> get _insights => (_data?['insights'] as Map?)?.cast<String, dynamic>() ?? {};

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _periodo(),
                  const SizedBox(height: 16),
                  _kpisGrid(),
                  const SizedBox(height: 16),
                  _estrella(),
                  _tendencia(),
                  _topBars('Top más vendidos', 'top_vendidos', 'unidades', AppColors.primary, esMoneda: false),
                  _topBars('Top por ganancia', 'top_ganancia', 'ganancia', AppColors.success, esMoneda: true),
                  _categorias(),
                  _caja(),
                  _insightList('🔴 Reposición urgente', 'reposicion_urgente',
                      (r) => '${r['producto']} · quedan ${_num(r['stock'])}'),
                  _insightList('⚠️ Vende mucho, margen bajo', 'margen_bajo',
                      (r) => '${r['producto']} · ${_money(r['margen_unitario'])}/u'),
                  _insightList('🐌 Sin rotación', 'sin_rotacion',
                      (r) => '${r['producto']} · ${_num(r['stock'])} en stock'),
                  _bajoStock(),
                ],
              ),
            ),
    );
  }

  // ---- Periodo ----
  Widget _periodo() {
    const opciones = [(7, '7 días'), (30, '30 días'), (90, '90 días'), (365, '1 año')];
    return Wrap(
      spacing: 8,
      children: [
        for (final o in opciones)
          ChoiceChip(
            label: Text(o.$2),
            selected: _dias == o.$1,
            onSelected: (_) {
              setState(() => _dias = o.$1);
              _load();
            },
          ),
      ],
    );
  }

  // ---- KPIs ----
  Widget _kpisGrid() {
    final items = [
      ('Ventas', _money(_kpis['ventas_total']), Icons.payments_outlined, AppColors.primary),
      ('Margen', _money(_kpis['margen_estimado']), Icons.trending_up, AppColors.success),
      ('Por cobrar', _money(_kpis['por_cobrar']), Icons.call_received, AppColors.warning),
      ('Por pagar', _money(_kpis['por_pagar']), Icons.call_made, AppColors.danger),
      ('Capital en stock', _money(_kpis['capital_inmovilizado']), Icons.inventory_2_outlined, AppColors.info),
      ('Alertas stock', _num(_kpis['productos_alerta']), Icons.warning_amber_outlined, AppColors.danger),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
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
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: it.$4.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(it.$3, color: it.$4, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(it.$1, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      Text(it.$2,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textStrong)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ---- Producto estrella ----
  Widget _estrella() {
    final e = _insights['producto_estrella'] as Map<String, dynamic>?;
    if (e == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFef6c00), Color(0xFFfb8c00)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PRODUCTO ESTRELLA',
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text('${e['producto']}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                Text('${_num(e['unidades'])} u · ${_money(e['ganancia'])} de ganancia',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Card contenedor ----
  Widget _card(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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

  // ---- Tendencia de ventas (línea) ----
  Widget _tendencia() {
    final serie = _list('ventas_por_dia');
    if (serie.isEmpty) return _card('Tendencia de ventas', const _Vacio());
    final spots = <FlSpot>[
      for (var i = 0; i < serie.length; i++)
        FlSpot(i.toDouble(), double.tryParse('${serie[i]['total'] ?? 0}') ?? 0),
    ];
    return _card('Tendencia de ventas', SizedBox(
      height: 180,
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.15)),
          ),
        ],
      )),
    ));
  }

  // ---- Barras horizontales (tops) ----
  Widget _topBars(String title, String key, String valueKey, Color color, {required bool esMoneda}) {
    final items = _list(key).take(6).toList();
    if (items.isEmpty) return _card(title, const _Vacio());
    final maxV = items.map((e) => double.tryParse('${e[valueKey] ?? 0}') ?? 0).fold<double>(0, (a, b) => b > a ? b : a);
    return _card(title, Column(
      children: [
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text('${it['producto']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(height: 16, color: AppColors.border.withValues(alpha: 0.4)),
                        FractionallySizedBox(
                          widthFactor: maxV > 0 ? ((double.tryParse('${it[valueKey] ?? 0}') ?? 0) / maxV).clamp(0.02, 1) : 0.02,
                          child: Container(height: 16, color: color),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 62,
                  child: Text(
                    esMoneda ? _money(it[valueKey]) : _num(it[valueKey]),
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    ));
  }

  // ---- Categorías (dona + leyenda) ----
  Widget _categorias() {
    final cats = _list('ventas_por_categoria');
    if (cats.isEmpty) return _card('Ventas por categoría', const _Vacio());
    final total = cats.fold<double>(0, (a, c) => a + (double.tryParse('${c['total'] ?? 0}') ?? 0));
    return _card('Ventas por categoría', Row(
      children: [
        SizedBox(
          width: 120, height: 120,
          child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 32,
            sections: [
              for (var i = 0; i < cats.length; i++)
                PieChartSectionData(
                  value: double.tryParse('${cats[i]['total'] ?? 0}') ?? 0,
                  color: _catColors[i % _catColors.length],
                  radius: 26,
                  showTitle: false,
                ),
            ],
          )),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cats.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: _catColors[i % _catColors.length], shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(child: Text('${cats[i]['categoria']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                      Text(total > 0 ? '${((double.tryParse('${cats[i]['total']}') ?? 0) / total * 100).round()}%' : '0%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ));
  }

  // ---- Caja ingresos/egresos ----
  Widget _caja() {
    final caja = _list('caja');
    if (caja.isEmpty) return const SizedBox.shrink();
    double v(String tipo) =>
        caja.where((c) => c['tipo'] == tipo).fold<double>(0, (a, c) => a + (double.tryParse('${c['total'] ?? 0}') ?? 0));
    Widget tile(String label, double val, Color color, IconData icon) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                Text(_money(val), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        );
    return _card('Caja del periodo', Row(children: [
      tile('Ingresos', v('ingreso'), AppColors.success, Icons.south_west),
      const SizedBox(width: 10),
      tile('Egresos', v('egreso'), AppColors.danger, Icons.north_east),
    ]));
  }

  // ---- Insights genéricos ----
  Widget _insightList(String title, String key, String Function(Map<String, dynamic>) line) {
    final items = ((_insights[key]) as List? ?? []).cast<Map<String, dynamic>>();
    if (items.isEmpty) return const SizedBox.shrink();
    return _card(title, Column(
      children: [
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Text('•  ', style: TextStyle(color: AppColors.textMuted)),
                Expanded(child: Text(line(it), style: const TextStyle(fontSize: 13))),
              ],
            ),
          ),
      ],
    ));
  }

  Widget _bajoStock() {
    final items = _list('bajo_stock');
    if (items.isEmpty) return const SizedBox.shrink();
    return _card('📦 Bajo stock / quiebre', Column(
      children: [
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(child: Text('${it['producto']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                Text('${_num(it['stock'])} / mín ${_num(it['minimo'])}',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: (double.tryParse('${it['stock']}') ?? 0) <= 0 ? AppColors.danger : AppColors.warning,
                    )),
              ],
            ),
          ),
      ],
    ));
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Sin datos en este periodo', style: TextStyle(color: AppColors.textMuted))),
      );
}
