import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../models/pedido.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_list_header.dart';
import '../widgets/app_message.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/data_card.dart';
import '../widgets/motivo_sheet.dart';
import 'crear_pedido_screen.dart';
import 'crear_venta_screen.dart';

String _money(num v) => 'S/ ${v.toStringAsFixed(2)}';

String _num(num n) => n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);

String _fecha(String? v) {
  final d = DateTime.tryParse(v ?? '');
  if (d == null) return '—';
  return '${d.day}/${d.month}/${d.year}';
}

AppBadgeType _tipoEstado(Pedido p) => switch (p.estado) {
  'pendiente' => AppBadgeType.warning,
  'convertido' => AppBadgeType.success,
  'cancelado' => AppBadgeType.danger,
  _ => AppBadgeType.neutral,
};

AppBadge _badgeEstado(Pedido p) => AppBadge(p.estadoLabel, type: _tipoEstado(p));

/// Acción elegida en el detalle de un pedido.
enum _Accion { editar, convertir, cancelar }

/// Pedidos de cliente: reservan stock sin descontarlo hasta que se convierten
/// en nota de venta o se cancelan.
class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final ApiService _api = ApiService();
  List<Pedido> _items = [];
  bool _loading = true;
  bool _cargandoMas = false;
  String? _error;
  String _busqueda = '';
  String? _filtroEstado;
  int _pagina = 1;
  int _ultimaPagina = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Carga una página del listado (15 por página); el estado se filtra en el
  /// servidor para que las páginas sean coherentes con el filtro.
  Future<List<Pedido>> _pedirPagina(int pagina) async {
    final query = [
      'page=$pagina',
      if (_filtroEstado != null) 'estado=$_filtroEstado',
    ].join('&');
    final res = await _api.get('${ApiEndpoints.pedidos}?$query');
    final data = res is Map ? res['data'] : res;
    final meta = res is Map ? res['meta'] : null;
    _pagina = (meta is Map ? meta['current_page'] as int? : null) ?? pagina;
    _ultimaPagina = (meta is Map ? meta['last_page'] as int? : null) ?? _pagina;
    return [
      for (final p in (data as List? ?? []).whereType<Map>())
        Pedido.fromJson(Map<String, dynamic>.from(p)),
    ];
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await _pedirPagina(1);
    } catch (_) {
      _items = [];
      _error = 'No se pudieron cargar los pedidos.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cargarMas() async {
    setState(() => _cargandoMas = true);
    try {
      _items = [..._items, ...await _pedirPagina(_pagina + 1)];
    } catch (_) {
      if (mounted) showAppSnackbar(context, 'No se pudo cargar más pedidos.', type: AppSnackbarType.error);
    }
    if (mounted) setState(() => _cargandoMas = false);
  }

  List<Pedido> get _visibles {
    final q = _busqueda.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((p) => '${p.codigo} ${p.clienteNombre ?? ''}'.toLowerCase().contains(q)).toList();
  }

  Future<void> _nuevo() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CrearPedidoScreen()),
    );
    if (ok == true) _load();
  }

  Future<void> _editar(Pedido p) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CrearPedidoScreen(pedidoId: p.id)),
    );
    if (ok == true) _load();
  }

  Future<void> _convertir(Pedido p) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CrearVentaScreen(pedidoId: p.id)),
    );
    if (ok == true) {
      await _load();
      if (mounted) showAppSnackbar(context, 'Pedido convertido en venta.', type: AppSnackbarType.success);
    }
  }

  Future<void> _cancelar(Pedido p) async {
    final motivo = await showAppModal<String>(
      context,
      title: 'Cancelar pedido ${p.codigo}',
      child: const MotivoSheet(label: 'Motivo de cancelación', confirmLabel: 'Cancelar pedido'),
    );
    if (motivo == null || !mounted) return;
    if (motivo.trim().isEmpty) {
      showAppSnackbar(context, 'Indica el motivo de la cancelación.', type: AppSnackbarType.error);
      return;
    }
    try {
      await _api.post(ApiEndpoints.pedidoCancelar(p.id), body: {'motivo_cancelacion': motivo.trim()});
      await _load();
      if (mounted) showAppSnackbar(context, 'Pedido cancelado. Reserva liberada.', type: AppSnackbarType.success);
    } catch (e) {
      if (mounted) showAppSnackbar(context, '$e', type: AppSnackbarType.error);
    }
  }

  /// El listado trae lo básico; el detalle se pide completo al abrirlo.
  Future<void> _verDetalle(Pedido item) async {
    Pedido? pedido;
    try {
      pedido = Pedido.fromResponse(await _api.get(ApiEndpoints.pedido(item.id)));
    } catch (_) {}
    if (!mounted) return;

    final accion = await showAppModal<_Accion>(
      context,
      title: 'Pedido ${(pedido ?? item).codigo}',
      child: pedido == null
          ? const AppMessage(text: 'No se pudo cargar el detalle.')
          : _DetallePedido(pedido: pedido),
    );
    if (accion == null || pedido == null || !mounted) return;
    switch (accion) {
      case _Accion.editar:
        await _editar(pedido);
      case _Accion.convertir:
        await _convertir(pedido);
      case _Accion.cancelar:
        await _cancelar(pedido);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles;
    final hayMas = _pagina < _ultimaPagina;

    return AppScaffold(
      title: 'Pedidos',
      floatingActionButton: FloatingActionButton(onPressed: _nuevo, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AppMessage(text: _error!),
                  ),
                AppListHeader(
                  hintText: 'Buscar pedidos...',
                  searchValue: _busqueda,
                  onSearch: (v) => setState(() => _busqueda = v),
                  filters: [
                    AppListFilter(
                      label: 'Estado',
                      value: _filtroEstado,
                      options: const [
                        AppListFilterOption(null, 'Todos'),
                        AppListFilterOption('pendiente', 'Pendiente'),
                        AppListFilterOption('convertido', 'Convertido'),
                        AppListFilterOption('cancelado', 'Cancelado'),
                      ],
                      onChanged: (v) {
                        _filtroEstado = v;
                        _load();
                      },
                    ),
                  ],
                  activeFilters: _filtroEstado != null ? 1 : 0,
                  onClearFilters: () {
                    _filtroEstado = null;
                    _load();
                  },
                  resultCount: visibles.length,
                ),
                Expanded(
                  child: visibles.isEmpty
                      ? Center(
                          child: Text(
                            _items.isEmpty ? 'No hay pedidos' : 'Ningún pedido coincide con la búsqueda',
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: visibles.length + (hayMas ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == visibles.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: SecondaryButton(
                                    label: 'Cargar más',
                                    onPressed: _cargandoMas ? null : _cargarMas,
                                  ),
                                );
                              }
                              final p = visibles[index];
                              return DataCard(
                                title: p.codigo,
                                // Tocar la tarjeta abre el detalle con sus acciones.
                                onTap: () => _verDetalle(p),
                                rows: [
                                  DataCardRow.text('Cliente', p.clienteNombre ?? 'Sin cliente'),
                                  DataCardRow.text('Fecha', _fecha(p.fechaPedido)),
                                  DataCardRow.text('Entrega', _fecha(p.fechaEntrega)),
                                  DataCardRow.text('Total', _money(p.total)),
                                  DataCardRow(label: 'Estado', value: _badgeEstado(p)),
                                ],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

/// Contenido del detalle: cabecera, productos, totales y, si el pedido sigue
/// pendiente, las acciones Editar / Convertir en venta / Cancelar.
class _DetallePedido extends StatelessWidget {
  final Pedido pedido;

  const _DetallePedido({required this.pedido});

  Widget _dato(String etiqueta, String valor) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(etiqueta, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ),
        Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    ),
  );

  Widget _colDato(String label, String valor, {Color? color}) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        Text(valor, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      ],
    ),
  );

  Widget _linea(PedidoDetalle d) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.productoNombre, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            '${d.productoCodigo ?? '-'} · ${d.presentacionNombre ?? '-'}'
            '${d.marca != null ? ' · ${d.marca}' : ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _colDato('Cant.', _num(d.cantidad)),
              _colDato('Precio', _money(d.precioUnitario)),
              _colDato('Subtotal', _money(d.subtotal)),
            ],
          ),
          if (d.descuento > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                _colDato('Descuento', _money(d.descuento), color: AppColors.warning),
                const Spacer(),
                const Spacer(),
              ],
            ),
          ],
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = pedido;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dato('Cliente', p.clienteNombre ?? 'Sin cliente'),
              _dato('Almacén', p.almacenNombre ?? '—'),
              _dato('Fecha', _fecha(p.fechaPedido)),
              _dato('Entrega', _fecha(p.fechaEntrega)),
              _dato('Vendedor', p.vendedorNombre ?? '—'),
              const SizedBox(height: 8),
              _badgeEstado(p),
              if (p.observaciones != null && p.observaciones!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Obs.: ${p.observaciones}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'PRODUCTOS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        for (final d in p.detalles) _linea(d),
        const Divider(height: 20),
        if (p.descuentoTotal > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(color: AppColors.textMuted)),
              Text(_money(p.subtotal)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Descuento', style: TextStyle(color: AppColors.textMuted)),
              Text('− ${_money(p.descuentoTotal)}'),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _money(p.total),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
        if (p.esConvertido) ...[
          const SizedBox(height: 12),
          AppMessage(
            text: 'Convertido en la venta ${p.notaVentaCodigo ?? '#${p.notaVentaId ?? ''}'}.',
            type: AppMessageType.success,
          ),
        ],
        if (p.esCancelado) ...[
          const SizedBox(height: 12),
          AppMessage(text: 'Cancelado: ${p.motivoCancelacion ?? 'sin motivo'}'),
        ],
        // Solo un pedido pendiente conserva reserva y admite cambios.
        if (p.esPendiente) ...[
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Convertir en venta',
            icon: Icons.point_of_sale_outlined,
            onPressed: () => Navigator.pop(context, _Accion.convertir),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Editar',
                  onPressed: () => Navigator.pop(context, _Accion.editar),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => Navigator.pop(context, _Accion.cancelar),
                  child: const Text('Cancelar pedido'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
