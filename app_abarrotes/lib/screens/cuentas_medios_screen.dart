import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/crud_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_form_section.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_select.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_tabs.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle.dart';
import '../widgets/data_card.dart';

class CuentasMediosScreen extends StatelessWidget {
  const CuentasMediosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cuentas y Medios de Pago',
      body: const AppTabs(
        tabs: [
          AppTab(icon: Icons.account_balance, label: 'Bancos', content: _BancosTab()),
          AppTab(icon: Icons.credit_card, label: 'Cuentas', content: _CuentasTab()),
          AppTab(icon: Icons.badge_outlined, label: 'Tarjetas', content: _TarjetasTab()),
          AppTab(icon: Icons.smartphone, label: 'Billeteras', content: _BilleterasTab()),
        ],
      ),
    );
  }
}

/// Lista + crear/editar/eliminar genérico para cada pestaña.
class _CrudTab extends StatefulWidget {
  final String endpoint;
  final String singular;
  final String Function(Map<String, dynamic>) titleOf;
  final List<DataCardRow> Function(Map<String, dynamic>) rowsOf;
  final Widget Function(Map<String, dynamic>? initial, void Function(Map<String, dynamic>) submit) formOf;

  const _CrudTab({
    required this.endpoint,
    required this.singular,
    required this.titleOf,
    required this.rowsOf,
    required this.formOf,
  });

  @override
  State<_CrudTab> createState() => _CrudTabState();
}

class _CrudTabState extends State<_CrudTab> {
  final ApiService _api = ApiService();
  late final CrudService _crud;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _crud = CrudService(_api, widget.endpoint);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _crud.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final result = await showAppModal<Map<String, dynamic>>(
      context,
      title: item == null ? 'Nuevo ${widget.singular}' : 'Editar ${widget.singular}',
      child: widget.formOf(item, (data) => Navigator.pop(context, data)),
    );
    if (result == null) return;
    try {
      if (item != null) {
        await _crud.update(item['id'], result);
      } else {
        await _crud.create(result);
      }
      await _load();
      if (mounted) showAppSnackbar(context, 'Guardado', type: AppSnackbarType.success);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await showAppConfirmDialog(context, title: 'Eliminar', message: '¿Eliminar este ${widget.singular}?');
    if (!ok) return;
    try {
      await _crud.delete(item['id']);
      await _load();
      if (mounted) showAppSnackbar(context, 'Eliminado', type: AppSnackbarType.error);
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Error: $e', type: AppSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? Center(child: Text('No hay ${widget.singular}s'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final item = _items[i];
                  return DataCard(
                    title: widget.titleOf(item),
                    rows: widget.rowsOf(item),
                    actions: [
                      DataCardAction(icon: Icons.edit_outlined, color: AppColors.primary, tooltip: 'Editar', onTap: () => _openForm(item: item)),
                      DataCardAction(icon: Icons.delete_outline, color: AppColors.danger, tooltip: 'Eliminar', onTap: () => _delete(item)),
                    ],
                  );
                },
              ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
        ),
      ],
    );
  }
}

// ── Bancos ──
class _BancosTab extends StatelessWidget {
  const _BancosTab();
  @override
  Widget build(BuildContext context) {
    return _CrudTab(
      endpoint: ApiEndpoints.bancos,
      singular: 'banco',
      titleOf: (b) => b['nombre'] as String? ?? '',
      rowsOf: (b) => [
        DataCardRow(
          label: 'Estado',
          value: AppBadge((b['activo'] as bool? ?? true) ? 'Activo' : 'Inactivo',
              type: (b['activo'] as bool? ?? true) ? AppBadgeType.success : AppBadgeType.danger),
        ),
      ],
      formOf: (initial, submit) => _BancoForm(initial: initial, submit: submit),
    );
  }
}

class _BancoForm extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final void Function(Map<String, dynamic>) submit;
  const _BancoForm({this.initial, required this.submit});
  @override
  State<_BancoForm> createState() => _BancoFormState();
}

class _BancoFormState extends State<_BancoForm> {
  late final TextEditingController _nombre = TextEditingController(text: widget.initial?['nombre'] ?? '');
  late bool _activo = widget.initial?['activo'] as bool? ?? true;
  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormWrapper(
      children: [
        AppTextField(controller: _nombre, label: 'Nombre', icon: Icons.account_balance),
        AppToggle(label: 'Activo', value: _activo, onChanged: (v) => setState(() => _activo = v)),
      ],
      onSave: () => widget.submit({'nombre': _nombre.text.trim(), 'activo': _activo}),
    );
  }
}

// ── Cuentas bancarias ──
class _CuentasTab extends StatefulWidget {
  const _CuentasTab();
  @override
  State<_CuentasTab> createState() => _CuentasTabState();
}

class _CuentasTabState extends State<_CuentasTab> {
  List<Map<String, dynamic>> _bancos = [];
  @override
  void initState() {
    super.initState();
    CrudService(ApiService(), ApiEndpoints.bancos).getAll().then((v) {
      if (mounted) setState(() => _bancos = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _CrudTab(
      endpoint: ApiEndpoints.cuentasBancarias,
      singular: 'cuenta',
      titleOf: (c) => '${c['banco']?['nombre'] ?? 'Banco'} · ${c['numero_cuenta'] ?? ''}',
      rowsOf: (c) => [
        DataCardRow.text('Alias', c['alias'] as String? ?? ''),
        DataCardRow.text('Moneda', c['moneda'] as String? ?? ''),
        DataCardRow.text('Titular', c['titular'] as String? ?? ''),
      ],
      formOf: (initial, submit) => _CuentaForm(initial: initial, submit: submit, bancos: _bancos),
    );
  }
}

class _CuentaForm extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final void Function(Map<String, dynamic>) submit;
  final List<Map<String, dynamic>> bancos;
  const _CuentaForm({this.initial, required this.submit, required this.bancos});
  @override
  State<_CuentaForm> createState() => _CuentaFormState();
}

class _CuentaFormState extends State<_CuentaForm> {
  late int? _bancoId = widget.initial?['banco_id'] as int?;
  late final TextEditingController _alias = TextEditingController(text: widget.initial?['alias'] ?? '');
  late final TextEditingController _numero = TextEditingController(text: widget.initial?['numero_cuenta'] ?? '');
  late final TextEditingController _cci = TextEditingController(text: widget.initial?['cci'] ?? '');
  late final TextEditingController _titular = TextEditingController(text: widget.initial?['titular'] ?? '');
  late String _moneda = widget.initial?['moneda'] as String? ?? 'PEN';
  late String _tipo = widget.initial?['tipo_cuenta'] as String? ?? 'corriente';
  late bool _activo = widget.initial?['activo'] as bool? ?? true;

  @override
  void dispose() {
    _alias.dispose();
    _numero.dispose();
    _cci.dispose();
    _titular.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormWrapper(
      children: [
        AppSelect<int>(
          label: 'Banco',
          icon: Icons.account_balance,
          value: _bancoId,
          options: [for (final b in widget.bancos) AppSelectOption(b['id'] as int, b['nombre'] as String? ?? '')],
          onChanged: (v) => setState(() => _bancoId = v),
        ),
        AppTextField(controller: _alias, label: 'Alias'),
        AppTextField(controller: _numero, label: 'N° Cuenta', icon: Icons.numbers),
        AppTextField(controller: _cci, label: 'CCI'),
        AppTextField(controller: _titular, label: 'Titular'),
        AppSelect<String>(
          label: 'Moneda',
          value: _moneda,
          options: const [AppSelectOption('PEN', 'Soles (PEN)'), AppSelectOption('USD', 'Dólares (USD)')],
          onChanged: (v) => setState(() => _moneda = v ?? 'PEN'),
        ),
        AppSelect<String>(
          label: 'Tipo',
          value: _tipo,
          options: const [AppSelectOption('corriente', 'Corriente'), AppSelectOption('ahorros', 'Ahorros')],
          onChanged: (v) => setState(() => _tipo = v ?? 'corriente'),
        ),
        AppToggle(label: 'Activo', value: _activo, onChanged: (v) => setState(() => _activo = v)),
      ],
      onSave: () => widget.submit({
        'banco_id': _bancoId,
        'alias': _alias.text.trim(),
        'numero_cuenta': _numero.text.trim(),
        'cci': _cci.text.trim(),
        'titular': _titular.text.trim(),
        'moneda': _moneda,
        'tipo_cuenta': _tipo,
        'activo': _activo,
      }),
    );
  }
}

// ── Tarjetas ──
class _TarjetasTab extends StatefulWidget {
  const _TarjetasTab();
  @override
  State<_TarjetasTab> createState() => _TarjetasTabState();
}

class _TarjetasTabState extends State<_TarjetasTab> {
  List<Map<String, dynamic>> _cuentas = [];
  @override
  void initState() {
    super.initState();
    CrudService(ApiService(), ApiEndpoints.cuentasBancarias).getAll().then((v) {
      if (mounted) setState(() => _cuentas = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _CrudTab(
      endpoint: ApiEndpoints.tarjetasBancarias,
      singular: 'tarjeta',
      titleOf: (t) => t['nombre_referencial'] as String? ?? '',
      rowsOf: (t) => [
        DataCardRow.text('Marca', t['marca'] as String? ?? ''),
        DataCardRow.text('N°', '**** ${t['numero_enmascarado'] ?? ''}'),
        DataCardRow.text('Estado', t['estado'] as String? ?? ''),
      ],
      formOf: (initial, submit) => _TarjetaForm(initial: initial, submit: submit, cuentas: _cuentas),
    );
  }
}

class _TarjetaForm extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final void Function(Map<String, dynamic>) submit;
  final List<Map<String, dynamic>> cuentas;
  const _TarjetaForm({this.initial, required this.submit, required this.cuentas});
  @override
  State<_TarjetaForm> createState() => _TarjetaFormState();
}

class _TarjetaFormState extends State<_TarjetaForm> {
  late int? _cuentaId = widget.initial?['cuenta_bancaria_id'] as int?;
  late String _tipoTarjeta = widget.initial?['tipo_tarjeta'] as String? ?? 'debito';
  late String _marca = widget.initial?['marca'] as String? ?? 'Visa';
  late String _estado = widget.initial?['estado'] as String? ?? 'activa';
  late final TextEditingController _nombre = TextEditingController(text: widget.initial?['nombre_referencial'] ?? '');
  late final TextEditingController _numero = TextEditingController(text: widget.initial?['numero_enmascarado'] ?? '');
  late final TextEditingController _titular = TextEditingController(text: widget.initial?['titular'] ?? '');

  @override
  void dispose() {
    _nombre.dispose();
    _numero.dispose();
    _titular.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormWrapper(
      children: [
        AppSelect<int>(
          label: 'Cuenta vinculada',
          icon: Icons.credit_card,
          value: _cuentaId,
          options: [
            for (final c in widget.cuentas)
              AppSelectOption(c['id'] as int, '${c['banco']?['nombre'] ?? ''} ${c['numero_cuenta'] ?? ''}'),
          ],
          onChanged: (v) => setState(() => _cuentaId = v),
        ),
        AppTextField(controller: _nombre, label: 'Nombre referencial'),
        AppTextField(controller: _numero, label: 'Últimos 4 dígitos'),
        AppSelect<String>(
          label: 'Tipo',
          value: _tipoTarjeta,
          options: const [AppSelectOption('debito', 'Débito'), AppSelectOption('credito', 'Crédito')],
          onChanged: (v) => setState(() => _tipoTarjeta = v ?? 'debito'),
        ),
        AppSelect<String>(
          label: 'Marca',
          value: _marca,
          options: const [
            AppSelectOption('Visa', 'Visa'),
            AppSelectOption('Mastercard', 'Mastercard'),
            AppSelectOption('Amex', 'American Express'),
            AppSelectOption('Diners', 'Diners'),
          ],
          onChanged: (v) => setState(() => _marca = v ?? 'Visa'),
        ),
        AppTextField(controller: _titular, label: 'Titular'),
        AppSelect<String>(
          label: 'Estado',
          value: _estado,
          options: const [
            AppSelectOption('activa', 'Activa'),
            AppSelectOption('bloqueada', 'Bloqueada'),
            AppSelectOption('vencida', 'Vencida'),
          ],
          onChanged: (v) => setState(() => _estado = v ?? 'activa'),
        ),
      ],
      onSave: () => widget.submit({
        'cuenta_bancaria_id': _cuentaId,
        'tipo_tarjeta': _tipoTarjeta,
        'nombre_referencial': _nombre.text.trim(),
        'numero_enmascarado': _numero.text.trim(),
        'marca': _marca,
        'titular': _titular.text.trim(),
        'estado': _estado,
      }),
    );
  }
}

// ── Billeteras ──
class _BilleterasTab extends StatefulWidget {
  const _BilleterasTab();
  @override
  State<_BilleterasTab> createState() => _BilleterasTabState();
}

class _BilleterasTabState extends State<_BilleterasTab> {
  List<Map<String, dynamic>> _cuentas = [];
  @override
  void initState() {
    super.initState();
    CrudService(ApiService(), ApiEndpoints.cuentasBancarias).getAll().then((v) {
      if (mounted) setState(() => _cuentas = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _CrudTab(
      endpoint: ApiEndpoints.billeterasDigitales,
      singular: 'billetera',
      titleOf: (b) => b['nombre'] as String? ?? '',
      rowsOf: (b) => [
        DataCardRow.text('Teléfono', b['numero_asociado'] as String? ?? ''),
        DataCardRow.text('Titular', b['titular'] as String? ?? ''),
      ],
      formOf: (initial, submit) => _BilleteraForm(initial: initial, submit: submit, cuentas: _cuentas),
    );
  }
}

class _BilleteraForm extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final void Function(Map<String, dynamic>) submit;
  final List<Map<String, dynamic>> cuentas;
  const _BilleteraForm({this.initial, required this.submit, required this.cuentas});
  @override
  State<_BilleteraForm> createState() => _BilleteraFormState();
}

class _BilleteraFormState extends State<_BilleteraForm> {
  late String _nombre = widget.initial?['nombre'] as String? ?? 'Yape';
  late int? _cuentaId = widget.initial?['cuenta_bancaria_id'] as int?;
  late final TextEditingController _telefono = TextEditingController(text: widget.initial?['numero_asociado'] ?? '');
  late final TextEditingController _titular = TextEditingController(text: widget.initial?['titular'] ?? '');
  late bool _activo = widget.initial?['activo'] as bool? ?? true;

  @override
  void dispose() {
    _telefono.dispose();
    _titular.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormWrapper(
      children: [
        AppSelect<String>(
          label: 'Tipo',
          icon: Icons.smartphone,
          value: _nombre,
          options: const [
            AppSelectOption('Yape', 'Yape'),
            AppSelectOption('Plin', 'Plin'),
            AppSelectOption('Tunki', 'Tunki'),
            AppSelectOption('Otro', 'Otro'),
          ],
          onChanged: (v) => setState(() => _nombre = v ?? 'Yape'),
        ),
        AppTextField(controller: _telefono, label: 'Teléfono', icon: Icons.phone_outlined),
        AppSelect<int>(
          label: 'Cuenta vinculada (opcional)',
          value: _cuentaId,
          options: [
            for (final c in widget.cuentas)
              AppSelectOption(c['id'] as int, '${c['banco']?['nombre'] ?? ''} ${c['numero_cuenta'] ?? ''}'),
          ],
          onChanged: (v) => setState(() => _cuentaId = v),
        ),
        AppTextField(controller: _titular, label: 'Titular'),
        AppToggle(label: 'Activo', value: _activo, onChanged: (v) => setState(() => _activo = v)),
      ],
      onSave: () => widget.submit({
        'nombre': _nombre,
        'numero_asociado': _telefono.text.trim(),
        'cuenta_bancaria_id': _cuentaId,
        'titular': _titular.text.trim(),
        'activo': _activo,
      }),
    );
  }
}

/// Envoltura común para los formularios de las pestañas.
class _FormWrapper extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback onSave;
  const _FormWrapper({required this.children, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFormSection(title: 'Datos', children: children),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SecondaryButton(label: 'Cancelar', onPressed: () => Navigator.pop(context))),
            const SizedBox(width: 12),
            Expanded(child: PrimaryButton(label: 'Guardar', onPressed: onSave)),
          ],
        ),
      ],
    );
  }
}
