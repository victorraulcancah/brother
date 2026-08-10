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
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('${ApiEndpoints.dashboard}?dias=$_dias');
      if (res is Map<String, dynamic>) _data = res;
    } catch (_) {
      _error = 'No se pudo cargar el dashboard.';
    }
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
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: const Text('No se pudo cargar el dashboard.',
                          style: TextStyle(color: AppColors.danger, fontSize: 13)),
                    ),
                  const SizedBox(height: 16),
                  _kpisGrid(),
                  const SizedBox(height: 16),
                  _estrella(),
                  _tendencia(),
                  _topBars('Top más vendidos', 'top_vendidos', 'unidades', AppColors.primary, esMoneda: false),
                  _topBars('Top por ganancia', 'top_ganancia', 'ganancia', AppColors.success, esMoneda: true),
                  _categorias(),
                  _pagoTipo(),
                  _caja(),
                  _insightList('🔴 Reposición urgente', 'reposicion_urgente',
                      (r) => '${r['producto']} · quedan ${_num(r['stock'])} · vendió ${_num(r['unidades'])}'),
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
    final n = _kpis;
    final items = [
      ('Ventas', _money(n['ventas_total']), Icons.payments_outlined, AppColors.primary, '${_num(n['num_ventas'])} ventas'),
      ('Ticket promedio', _money(n['ticket_promedio']), Icons.receipt_long_outlined, AppColors.info, ''),
      ('Margen', _money(n['margen_estimado']), Icons.trending_up, AppColors.success, ''),
      ('Por cobrar', _money(n['por_cobrar']), Icons.call_received, AppColors.warning, ''),
      ('Por pagar', _money(n['por_pagar']), Icons.call_made, AppColors.danger, ''),
      ('Capital en stock', _money(n['capital_inmovilizado']), Icons.inventory_2_outlined, AppColors.info, 'dinero inmovilizado'),
      ('Alertas stock', _num(n['productos_alerta']), Icons.warning_amber_outlined, AppColors.danger, 'por reponer'),
      ('N° de ventas', _num(n['num_ventas']), Icons.receipt_outlined, AppColors.primary, ''),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.0,
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
                      if (it.$5.isNotEmpty)
                        Text(it.$5, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
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
                Text('${_num(e['unidades'])} u · ${_money(e['total'])} vendidos · ${_money(e['ganancia'])} de ganancia',
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
    final items = _list(key).take(10).toList();
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

  // ---- Contado vs Crédito (dona + leyenda) ----
  Widget _pagoTipo() {
    final items = _list('pago_tipo');
    if (items.isEmpty) return _card('Contado vs Crédito', const _Vacio());
    final total = items.fold<double>(0, (a, c) => a + (double.tryParse('${c['total'] ?? 0}') ?? 0));
    Color colorOf(String tipo) => tipo == 'contado' ? AppColors.success : AppColors.warning;
    String labelOf(String tipo) => tipo == 'contado' ? 'Contado' : 'Crédito';
    return _card('Contado vs Crédito', Row(
      children: [
        SizedBox(
          width: 120, height: 120,
          child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 32,
            sections: [
              for (final it in items)
                PieChartSectionData(
                  value: double.tryParse('${it['total'] ?? 0}') ?? 0,
                  color: colorOf('${it['tipo']}'),
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
              for (final it in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: colorOf('${it['tipo']}'), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(labelOf('${it['tipo']}'),
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                      ),
                      Text(total > 0 ? '${((double.tryParse('${it['total']}') ?? 0) / total * 100).round()}%' : '0%',
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

  // ---- Caja ingresos/egresos (barras) ----
  Widget _caja() {
    final caja = _list('caja');
    if (caja.isEmpty) return _card('Ingresos vs Egresos de caja', const _Vacio());
    double v(String tipo) =>
        caja.where((c) => c['tipo'] == tipo).fold<double>(0, (a, c) => a + (double.tryParse('${c['total'] ?? 0}') ?? 0));
    final rows = <(String, double, Color)>[
      ('Ingresos', v('ingreso'), AppColors.success),
      ('Egresos', v('egreso'), AppColors.danger),
    ];
    return _card('Ingresos vs Egresos de caja', SizedBox(
      height: 170,
      child: BarChart(BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= rows.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(rows[i].$1, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < rows.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: rows[i].$2,
                width: 44,
                borderRadius: BorderRadius.circular(6),
                color: rows[i].$3,
              ),
            ]),
        ],
      )),
    ));
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
