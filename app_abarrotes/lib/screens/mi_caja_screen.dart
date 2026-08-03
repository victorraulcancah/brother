import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';

String _money(dynamic v) => 'S/ ${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';
double _n(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;

class MiCajaScreen extends StatefulWidget {
  const MiCajaScreen({super.key});

  @override
  State<MiCajaScreen> createState() => _MiCajaScreenState();
}

class _MiCajaScreenState extends State<MiCajaScreen> {
  final ApiService _api = ApiService();
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
      final res = await _api.get(ApiEndpoints.miCaja);
      if (res is Map<String, dynamic>) _data = res;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Map<String, dynamic>? get _caja => _data?['caja'] as Map<String, dynamic>?;
  Map<String, dynamic>? get _apertura => _data?['apertura'] as Map<String, dynamic>?;
  Map<String, dynamic>? get _resumen => _data?['resumen'] as Map<String, dynamic>?;

  Future<void> _abrir() async {
    final ctrl = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abrir caja'),
        content: AppTextField(
          controller: ctrl,
          label: 'Monto inicial (S/)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Abrir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await _api.post(ApiEndpoints.miCajaAbrir, body: {'monto_inicial': _n(ctrl.text)});
      if (mounted) {
        setState(() => _data = res);
        showAppSnackbar(context, 'Caja abierta', type: AppSnackbarType.success);
      }
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  Future<void> _cerrar() async {
    final esperado = _n(_resumen?['esperado']);
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final dif = _n(ctrl.text) - esperado;
          return AlertDialog(
            title: const Text('Cerrar caja (arqueo)'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Esperado en caja'),
                      Text(_money(esperado), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: ctrl,
                  label: 'Monto contado (S/)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setD(() {}),
                ),
                if (ctrl.text.isNotEmpty && dif.abs() > 0.001)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${dif < 0 ? 'Faltante' : 'Sobrante'}: ${_money(dif.abs())}',
                      style: TextStyle(color: dif < 0 ? AppColors.danger : AppColors.warning, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cerrar caja')),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    try {
      final res = await _api.post(ApiEndpoints.miCajaCerrar, body: {'monto_contado': _n(ctrl.text)});
      if (mounted) {
        setState(() => _data = res);
        showAppSnackbar(context, 'Caja cerrada. Arqueo registrado.', type: AppSnackbarType.success);
      }
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mi Caja',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [_body()],
              ),
            ),
    );
  }

  Widget _body() {
    if (_caja == null) {
      return const AppBadge(
        'No tienes una caja asignada. Pide a un administrador que te asigne una.',
        type: AppBadgeType.warning,
      );
    }
    final abierta = _apertura != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.point_of_sale_outlined, color: AppColors.primary, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_caja?['nombre'] ?? ''}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              AppBadge(abierta ? 'Abierta' : 'Cerrada',
                  type: abierta ? AppBadgeType.success : AppBadgeType.neutral),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (abierta) ...[
          _stat('Monto inicial', _money(_resumen?['monto_inicial']), AppColors.textStrong),
          _stat('Ingresos', _money(_resumen?['ingresos']), AppColors.success),
          _stat('Egresos', _money(_resumen?['egresos']), AppColors.danger),
          _stat('Esperado en caja', _money(_resumen?['esperado']), AppColors.primary),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _cerrar,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Cerrar caja (arqueo)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ] else ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Tu caja está cerrada. Ábrela para registrar movimientos.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
          ),
          PrimaryButton(label: 'Abrir caja', onPressed: _abrir),
        ],
      ],
    );
  }

  Widget _stat(String label, String value, Color color) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted)),
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      );
}
