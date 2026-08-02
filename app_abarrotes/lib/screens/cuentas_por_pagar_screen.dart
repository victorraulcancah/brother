import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/data_card.dart';
import 'pagos_cuenta_screen.dart';

String _money(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return 'S/ ${n.toStringAsFixed(2)}';
}

AppBadgeType _estadoBadge(String? estado) {
  switch (estado) {
    case 'pagado':
      return AppBadgeType.success;
    case 'parcial':
      return AppBadgeType.warning;
    case 'anulado':
      return AppBadgeType.neutral;
    default:
      return AppBadgeType.danger;
  }
}

class CuentasPorPagarScreen extends StatefulWidget {
  const CuentasPorPagarScreen({super.key});

  @override
  State<CuentasPorPagarScreen> createState() => _CuentasPorPagarScreenState();
}

class _CuentasPorPagarScreenState extends State<CuentasPorPagarScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.cuentasPorPagar);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _abrirPagos(Map<String, dynamic> item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PagosCuentaScreen(
          cuenta: Map<String, dynamic>.from(item),
          apiPath: ApiEndpoints.cuentasPorPagar,
          esCobrar: false,
        ),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cuentas por Pagar',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay cuentas por pagar'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final proveedor = item['proveedor'] as Map<String, dynamic>?;
                return DataCard(
                  title: proveedor?['nombre'] as String? ?? 'Proveedor',
                  rows: [
                    DataCardRow.text('Vence', '${item['fecha_vencimiento'] ?? '—'}'),
                    DataCardRow.text('Total', _money(item['monto_total'])),
                    DataCardRow.text('Pagado', _money(item['monto_pagado'])),
                    DataCardRow.text('Saldo', _money(item['saldo'])),
                    DataCardRow(
                      label: 'Estado',
                      value: AppBadge(
                        '${item['estado'] ?? '—'}',
                        type: _estadoBadge(item['estado'] as String?),
                      ),
                    ),
                  ],
                  actions: [
                    DataCardAction(
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                      tooltip: 'Pagos',
                      onTap: () => _abrirPagos(item),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
