import 'package:flutter/material.dart';
import 'app_select.dart';

String cuentaLabel(Map c) =>
    [(c['banco'] as Map?)?['nombre'], c['alias'], c['numero_cuenta']]
        .where((e) => e != null && '$e'.isNotEmpty)
        .join(' · ');

String billeteraLabel(Map b) =>
    [b['nombre'], b['titular'], b['numero_asociado']]
        .where((e) => e != null && '$e'.isNotEmpty)
        .join(' · ');

/// Selector de método por tipo (Efectivo / Transferencia / Billetera) con despliegue.
/// value = (tipo, cuentaId, billeteraId). Notifica cambios por [onChanged].
class MetodoPicker extends StatelessWidget {
  final List<Map<String, dynamic>> cuentas;
  final List<Map<String, dynamic>> billeteras;
  final bool aceptaEfectivo;
  final String? tipo;
  final int? cuentaId;
  final int? billeteraId;
  final void Function(String? tipo, int? cuentaId, int? billeteraId) onChanged;

  const MetodoPicker({
    super.key,
    required this.cuentas,
    required this.billeteras,
    this.aceptaEfectivo = true,
    required this.tipo,
    required this.cuentaId,
    required this.billeteraId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tipos = <AppSelectOption<String>>[
      if (aceptaEfectivo) const AppSelectOption('efectivo', 'Efectivo'),
      if (cuentas.isNotEmpty) const AppSelectOption('transferencia', 'Transferencia'),
      if (billeteras.isNotEmpty) const AppSelectOption('billetera', 'Billetera digital'),
    ];
    return Column(
      children: [
        AppSelect<String>(
          label: 'Tipo de método',
          icon: Icons.payments_outlined,
          value: tipo,
          options: tipos,
          onChanged: (v) => onChanged(v, null, null),
        ),
        if (tipo == 'transferencia')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AppSelect<int>(
              label: 'Cuenta bancaria',
              icon: Icons.account_balance_outlined,
              value: cuentaId,
              options: [for (final c in cuentas) AppSelectOption(c['id'] as int, cuentaLabel(c))],
              onChanged: (v) => onChanged(tipo, v, null),
            ),
          ),
        if (tipo == 'billetera')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AppSelect<int>(
              label: 'Billetera',
              icon: Icons.account_balance_wallet_outlined,
              value: billeteraId,
              options: [for (final b in billeteras) AppSelectOption(b['id'] as int, billeteraLabel(b))],
              onChanged: (v) => onChanged(tipo, null, v),
            ),
          ),
      ],
    );
  }
}
