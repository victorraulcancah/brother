import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/data_card.dart';

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

class CuentasPorCobrarScreen extends StatefulWidget {
  const CuentasPorCobrarScreen({super.key});

  @override
  State<CuentasPorCobrarScreen> createState() => _CuentasPorCobrarScreenState();
}

class _CuentasPorCobrarScreenState extends State<CuentasPorCobrarScreen> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, ApiEndpoints.cuentasPorCobrar);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cuentas por Cobrar',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No hay cuentas por cobrar'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final cliente = item['cliente'] as Map<String, dynamic>?;
                return DataCard(
                  title: cliente?['nombre'] as String? ?? 'Cliente',
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
                );
              },
            ),
    );
  }
}
