import { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, ClipboardList, Package, Plus, Trash2 } from 'lucide-react';
import api, { asList } from '../lib/api';
import { opcionesAlmacen } from '../lib/almacenes';
import { useToast } from '../lib/toast';
import { useAuth } from '../lib/auth';
import Layout from '../components/Layout';
import ProductoPickerModal from '../components/ProductoPickerModal';
import { Alert, Button, Input, SearchSelect, Select, Spinner } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const num = (n) => new Intl.NumberFormat('es-PE', { maximumFractionDigits: 2 }).format(Number(n) || 0);

const hoy = () => new Date().toISOString().slice(0, 10);

const CLIENTE_GENERICO = 'Clientes varios';

const panelVacio = { producto_id: '', producto_presentacion_id: '', cantidad: '1', precio_unitario: '0' };

/**
 * Pedido de cliente. A diferencia de una venta no cobra ni descuenta stock: al
 * guardarlo reserva la mercadería (queda apartada y deja de estar disponible
 * para otras ventas) hasta que se convierta en venta o se cancele.
 */
export default function CrearPedido() {
    const toast = useToast();
    const navigate = useNavigate();
    const { user } = useAuth();
    /** Con id en la URL se edita un pedido pendiente; sin id, se crea uno nuevo. */
    const { id: pedidoId } = useParams();
    const editando = Boolean(pedidoId);

    const [clientes, setClientes] = useState([]);
    const [almacenes, setAlmacenes] = useState([]);
    const [productos, setProductos] = useState([]);
    const [existencias, setExistencias] = useState([]);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);

    const [form, setForm] = useState({
        cliente_id: '',
        almacen_id: '',
        fecha_pedido: hoy(),
        fecha_entrega: '',
        observaciones: '',
    });

    const [panel, setPanel] = useState({ ...panelVacio });
    const [items, setItems] = useState([]);
    const [picker, setPicker] = useState({ open: false, query: '' });
    /** Lo que este mismo pedido ya tiene reservado: al editarlo se libera y se vuelve a reservar. */
    const [reservaPropia, setReservaPropia] = useState({ almacenId: null, porProducto: {} });

    const load = useCallback(async () => {
        setLoading(true);
        try {
            const [cliRes, almRes, prodRes, existRes] = await Promise.all([
                api.get('/clientes'),
                api.get('/almacenes'),
                api.get('/productos', { params: { per_page: 500 } }),
                api.get('/existencias'),
            ]);
            setClientes(asList(cliRes));
            const listaAlmacenes = asList(almRes);
            setAlmacenes(listaAlmacenes);
            setProductos(asList(prodRes));
            setExistencias(asList(existRes));

            if (listaAlmacenes.length === 1) {
                setForm((prev) => ({ ...prev, almacen_id: String(listaAlmacenes[0].id) }));
            }

            if (pedidoId) {
                const res = await api.get(`/pedidos/${pedidoId}`);
                const pedido = res.data?.data ?? res.data;

                if (pedido.estado !== 'pendiente') {
                    toast.error('Solo se pueden editar pedidos pendientes.');
                    navigate('/pedidos');
                    return;
                }

                setForm({
                    cliente_id: pedido.cliente_id ? String(pedido.cliente_id) : '',
                    almacen_id: String(pedido.almacen_id),
                    fecha_pedido: String(pedido.fecha_pedido ?? '').slice(0, 10) || hoy(),
                    fecha_entrega: String(pedido.fecha_entrega ?? '').slice(0, 10),
                    observaciones: pedido.observaciones ?? '',
                });

                const detalles = pedido.detalles ?? [];
                setItems(
                    detalles.map((d) => ({
                        producto_id: String(d.presentacion?.producto?.id ?? ''),
                        producto_presentacion_id: String(d.producto_presentacion_id),
                        cantidad: String(Number(d.cantidad) || 0),
                        precio_unitario: String(Number(d.precio_unitario) || 0),
                    })),
                );

                const porProducto = {};
                detalles.forEach((d) => {
                    const productoId = String(d.presentacion?.producto?.id ?? '');
                    const factor = Number(d.presentacion?.factor_conversion) || 1;
                    porProducto[productoId] = (porProducto[productoId] ?? 0) + (Number(d.cantidad) || 0) * factor;
                });
                setReservaPropia({ almacenId: String(pedido.almacen_id), porProducto });
            }
        } catch {
            toast.error('No se pudieron cargar los datos.');
        } finally {
            setLoading(false);
        }
    }, [toast, pedidoId, navigate]);

    useEffect(() => {
        load();
    }, [load]);

    const productoDe = useCallback(
        (productoId) => productos.find((p) => String(p.id) === String(productoId)) ?? null,
        [productos],
    );

    const presentacionDe = useCallback(
        (productoId, presentacionId) =>
            (productoDe(productoId)?.presentaciones ?? []).find(
                (pres) => String(pres.id) === String(presentacionId),
            ) ?? null,
        [productoDe],
    );

    /** Disponible (físico − reservado, en unidad base) por producto, en el almacén elegido. */
    const stockDelAlmacen = useMemo(() => {
        if (!form.almacen_id) return {};
        const propia =
            reservaPropia.almacenId === String(form.almacen_id) ? reservaPropia.porProducto : {};

        return existencias
            .filter((e) => String(e.almacen_id ?? e.almacen?.id) === String(form.almacen_id))
            .reduce((acc, e) => {
                const productoId = String(e.producto_id);
                const disponible = Number(e.stock_disponible ?? e.stock_actual) || 0;
                acc[productoId] = disponible + (propia[productoId] ?? 0);
                return acc;
            }, {});
    }, [existencias, form.almacen_id, reservaPropia]);

    /** Solo se puede apartar lo que está disponible. */
    const productosDisponibles = useMemo(
        () => productos.filter((p) => (stockDelAlmacen[String(p.id)] ?? 0) > 0),
        [productos, stockDelAlmacen],
    );

    const productosOptions = useMemo(
        () =>
            productosDisponibles.map((p) => ({
                value: String(p.id),
                label: p.nombre,
                keywords: `${p.codigo ?? ''} ${p.codigo_barras ?? ''}`,
            })),
        [productosDisponibles],
    );

    const unidadesDe = useCallback(
        (productoId) => {
            const p = productoDe(productoId);
            if (!p) return [];

            const stockBase = stockDelAlmacen[String(p.id)] ?? 0;

            return (p.presentaciones ?? [])
                .filter((pres) => pres.activo !== false)
                .map((pres) => {
                    const factor = Number(pres.factor_conversion) || 1;
                    return {
                        value: String(pres.id),
                        label: pres.nombre,
                        factor,
                        disponible: Math.floor((stockBase / factor) * 100) / 100,
                    };
                });
        },
        [productoDe, stockDelAlmacen],
    );

    const disponibleDe = (productoId, presentacionId) =>
        unidadesDe(productoId).find((u) => String(u.value) === String(presentacionId)) ?? null;

    /**
     * Total pedido de un producto en unidad base. Dos líneas del mismo producto en
     * distinta unidad (caja y unidad) comparten el mismo stock, así que se suman.
     */
    const pedidoBaseDe = useCallback(
        (productoId) =>
            items
                .filter((it) => String(it.producto_id) === String(productoId))
                .reduce(
                    (acc, it) =>
                        acc +
                        (Number(it.cantidad) || 0) *
                            (Number(presentacionDe(it.producto_id, it.producto_presentacion_id)?.factor_conversion) || 1),
                    0,
                ),
        [items, presentacionDe],
    );

    const productoPanel = productoDe(panel.producto_id);
    const unidadesPanel = unidadesDe(panel.producto_id);
    const disponiblePanel = disponibleDe(panel.producto_id, panel.producto_presentacion_id);

    const setField = (name, value) => setForm((prev) => ({ ...prev, [name]: value }));
    const setPanelCampo = (patch) => setPanel((prev) => ({ ...prev, ...patch }));

    const elegirProducto = (productoId) => {
        const unidades = unidadesDe(productoId);
        const presentacionId = unidades.length === 1 ? unidades[0].value : '';
        setPanel({
            producto_id: productoId,
            producto_presentacion_id: presentacionId,
            cantidad: '1',
            precio_unitario: presentacionId
                ? String(Number(presentacionDe(productoId, presentacionId)?.precio_venta) || 0)
                : '0',
        });
    };

    const elegirUnidad = (presentacionId) =>
        setPanelCampo({
            producto_presentacion_id: presentacionId,
            precio_unitario: String(
                Number(presentacionDe(panel.producto_id, presentacionId)?.precio_venta) || 0,
            ),
        });

    const limpiarPanel = () => setPanel({ ...panelVacio });

    const agregarDesdePicker = (seleccionados) => {
        const utiles = seleccionados.filter((s) => s.presentacion && s.cantidad > 0);
        if (utiles.length === 0) return;

        setItems((prev) => {
            const next = [...prev];

            utiles.forEach(({ producto, presentacion, cantidad }) => {
                const i = next.findIndex(
                    (it) => String(it.producto_presentacion_id) === String(presentacion.id),
                );
                if (i !== -1) {
                    next[i] = {
                        ...next[i],
                        cantidad: String((Number(next[i].cantidad) || 0) + cantidad),
                    };
                } else {
                    next.push({
                        producto_id: String(producto.id),
                        producto_presentacion_id: String(presentacion.id),
                        cantidad: String(cantidad),
                        precio_unitario: String(Number(presentacion.precio_venta) || 0),
                    });
                }
            });

            return next;
        });

        toast.success(
            utiles.length === 1 ? 'Producto agregado.' : `${utiles.length} productos agregados.`,
        );
        limpiarPanel();
    };

    const agregarProducto = () => {
        if (!form.almacen_id) return toast.error('Elige primero el almacén.');
        if (!panel.producto_id) return toast.error('Busca y elige un producto.');
        if (!panel.producto_presentacion_id) return toast.error('Elige la unidad de medida.');
        if (!(Number(panel.cantidad) > 0)) return toast.error('La cantidad debe ser mayor a 0.');

        const nuevo = {
            producto_id: panel.producto_id,
            producto_presentacion_id: panel.producto_presentacion_id,
            cantidad: panel.cantidad,
            precio_unitario: panel.precio_unitario || '0',
        };

        const yaEsta = items.findIndex(
            (it) => String(it.producto_presentacion_id) === String(nuevo.producto_presentacion_id),
        );
        if (yaEsta !== -1) {
            setItems((prev) =>
                prev.map((it, i) =>
                    i === yaEsta
                        ? {
                              ...it,
                              cantidad: String((Number(it.cantidad) || 0) + (Number(nuevo.cantidad) || 0)),
                              precio_unitario: nuevo.precio_unitario,
                          }
                        : it,
                ),
            );
            toast.success('Se sumó la cantidad al producto ya agregado.');
        } else {
            setItems((prev) => [...prev, nuevo]);
        }
        limpiarPanel();
    };

    const setItem = (i, patch) =>
        setItems((prev) => prev.map((it, idx) => (idx === i ? { ...it, ...patch } : it)));

    const cambiarUnidadItem = (i, presentacionId) =>
        setItem(i, {
            producto_presentacion_id: presentacionId,
            precio_unitario: String(
                Number(presentacionDe(items[i].producto_id, presentacionId)?.precio_venta) || 0,
            ),
        });

    const quitarItem = (i) => setItems((prev) => prev.filter((_, idx) => idx !== i));

    const total = items.reduce(
        (acc, it) => acc + (Number(it.cantidad) || 0) * (Number(it.precio_unitario) || 0),
        0,
    );

    /** Línea que pide más de lo disponible (sumando las demás líneas del mismo producto). */
    const excedeDisponible = (it) => {
        const stockBase = stockDelAlmacen[String(it.producto_id)] ?? 0;
        return pedidoBaseDe(it.producto_id) > stockBase + 1e-9;
    };

    const guardar = async () => {
        if (items.length === 0) return toast.error('Agrega al menos un producto.');
        if (!form.almacen_id) return toast.error('Selecciona el almacén.');
        if (form.fecha_entrega && form.fecha_entrega < form.fecha_pedido) {
            return toast.error('La fecha de entrega no puede ser anterior a la del pedido.');
        }

        const sinStock = items.find(excedeDisponible);
        if (sinStock) {
            const nombre = productoDe(sinStock.producto_id)?.nombre ?? 'El producto';
            const u = disponibleDe(sinStock.producto_id, sinStock.producto_presentacion_id);
            return toast.error(`"${nombre}" solo tiene ${num(u?.disponible)} disponibles para reservar.`);
        }

        setSaving(true);

        const detalles = items.map((it) => {
            const cantidad = Number(it.cantidad) || 0;
            const precio = Number(it.precio_unitario) || 0;
            return {
                producto_presentacion_id: it.producto_presentacion_id,
                cantidad,
                precio_unitario: precio,
                descuento: 0,
                subtotal: Math.round(cantidad * precio * 100) / 100,
            };
        });

        try {
            const cuerpo = {
                cliente_id: form.cliente_id || null,
                almacen_id: form.almacen_id,
                vendedor_id: user?.id,
                fecha_pedido: form.fecha_pedido,
                fecha_entrega: form.fecha_entrega || null,
                moneda: 'PEN',
                subtotal: total,
                descuento_total: 0,
                total,
                observaciones: form.observaciones,
                serie: 'PE01',
                detalles,
            };

            if (editando) {
                await api.put(`/pedidos/${pedidoId}`, cuerpo);
            } else {
                await api.post('/pedidos', cuerpo);
            }

            toast.success(
                editando
                    ? 'Pedido actualizado. Reserva recalculada.'
                    : 'Pedido registrado. El stock quedó reservado.',
            );
            navigate('/pedidos');
        } catch (err) {
            const msg = err.response?.data?.message;
            const firstErr = err.response?.data?.errors
                ? Object.values(err.response.data.errors)[0]?.[0]
                : null;
            toast.error(firstErr ?? msg ?? 'No se pudo registrar el pedido.');
        } finally {
            setSaving(false);
        }
    };

    if (loading) {
        return (
            <Layout>
                <div className="flex items-center justify-center py-24">
                    <Spinner size="lg" className="text-primary-600" />
                </div>
            </Layout>
        );
    }

    return (
        <Layout>
            {/* Encabezado */}
            <div className="mb-6 flex items-center gap-3">
                <button
                    onClick={() => navigate('/pedidos')}
                    className="flex h-9 w-9 items-center justify-center rounded-lg border border-edge text-gray-500 transition hover:bg-gray-50 hover:text-gray-800"
                    aria-label="Volver"
                >
                    <ArrowLeft className="h-4 w-4" />
                </button>
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary-50 text-primary-600">
                    <ClipboardList className="h-5 w-5" />
                </div>
                <div>
                    <h1 className="text-xl font-bold tracking-tight text-warm-900">
                        {editando ? 'Editar Pedido' : 'Nuevo Pedido'}
                    </h1>
                    <p className="text-sm text-warm-500">Reserva productos para un cliente sin descontar el stock</p>
                </div>
            </div>

            {/* Datos del pedido */}
            <div className="mb-6 rounded-xl border border-edge bg-white shadow-sm">
                <div className="border-b border-edge px-5 py-3">
                    <h2 className="text-xs font-bold uppercase tracking-wide text-warm-500">Datos del pedido</h2>
                </div>
                <div className="grid grid-cols-2 gap-4 p-5 md:grid-cols-4">
                    <Input
                        label="Fecha del pedido"
                        type="date"
                        value={form.fecha_pedido}
                        onChange={(e) => setField('fecha_pedido', e.target.value)}
                    />
                    <Input
                        label="Entrega (opcional)"
                        type="date"
                        value={form.fecha_entrega}
                        min={form.fecha_pedido}
                        onChange={(e) => setField('fecha_entrega', e.target.value)}
                    />
                    <div className="md:col-span-2">
                        <SearchSelect
                            label="Cliente (opcional)"
                            value={form.cliente_id}
                            onChange={(v) => setField('cliente_id', v)}
                            options={clientes.map((c) => ({
                                value: String(c.id),
                                label: c.nombre ?? c.razon_social ?? `#${c.id}`,
                                keywords: c.numero_documento ?? '',
                            }))}
                            placeholder={CLIENTE_GENERICO}
                            emptyText="Sin coincidencias"
                        />
                    </div>
                    <Select
                        label="Almacén"
                        value={form.almacen_id}
                        // Cambiar de almacén invalida los productos ya elegidos.
                        onChange={(e) => {
                            setField('almacen_id', e.target.value);
                            setItems([]);
                            limpiarPanel();
                        }}
                        options={[
                            { value: '', label: 'Selecciona…' },
                            ...opcionesAlmacen(almacenes, form.almacen_id),
                        ]}
                    />
                </div>
            </div>

            {/* Panel de búsqueda y alta de producto */}
            <div className="mb-6 rounded-xl border border-edge bg-white p-5 shadow-sm">
                <h2 className="mb-3 text-sm font-semibold text-warm-900">Buscar Producto</h2>

                {!form.almacen_id ? (
                    <Alert variant="info">Elige un almacén para ver los productos disponibles.</Alert>
                ) : (
                    <>
                        <SearchSelect
                            value={panel.producto_id}
                            onChange={elegirProducto}
                            options={productosOptions}
                            placeholder="Buscar producto por nombre o código…"
                            emptyText="Sin productos disponibles en este almacén"
                            searchTitle="Buscador avanzado con filtros"
                            onSearch={(q) => setPicker({ open: true, query: q })}
                        />

                        <div className="mt-4">
                            <label className="mb-1 block text-sm font-medium text-gray-700">Descripción</label>
                            <input
                                readOnly
                                value={productoPanel?.descripcion ?? productoPanel?.nombre ?? ''}
                                placeholder="—"
                                className="block w-full rounded-md border-0 bg-white px-3 py-2 text-sm text-warm-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400"
                            />
                        </div>

                        <div className="mt-4 grid grid-cols-2 gap-4 md:grid-cols-4">
                            <div>
                                <label className="mb-1 block text-sm font-medium text-gray-700">Disponible</label>
                                <input
                                    readOnly
                                    value={disponiblePanel ? num(disponiblePanel.disponible) : ''}
                                    placeholder="—"
                                    className="block w-full rounded-md border-0 bg-gray-50 px-3 py-2 text-center text-sm text-gray-500 shadow-sm ring-1 ring-inset ring-gray-300"
                                />
                            </div>
                            <Select
                                label="Unidad"
                                value={panel.producto_presentacion_id}
                                disabled={!panel.producto_id}
                                onChange={(e) => elegirUnidad(e.target.value)}
                                options={[
                                    { value: '', label: panel.producto_id ? 'Unidad…' : '—' },
                                    ...unidadesPanel,
                                ]}
                            />
                            <Input
                                label="Cantidad"
                                type="number"
                                min="0"
                                step="any"
                                value={panel.cantidad}
                                onChange={(e) => setPanelCampo({ cantidad: e.target.value })}
                                className="text-center"
                            />
                            <Input
                                label="Precio"
                                type="number"
                                min="0"
                                step="any"
                                value={panel.precio_unitario}
                                onChange={(e) => setPanelCampo({ precio_unitario: e.target.value })}
                                className="text-center"
                            />
                        </div>

                        <Button
                            type="button"
                            onClick={agregarProducto}
                            className="mt-4 w-full justify-center md:w-auto md:min-w-[280px]"
                        >
                            <Plus className="h-4 w-4" /> Agregar Producto
                        </Button>
                    </>
                )}
            </div>

            {/* Productos agregados */}
            <div className="mb-6 rounded-xl border border-edge bg-white shadow-sm">
                <div className="flex items-center justify-between border-b border-edge px-5 py-3">
                    <h2 className="inline-flex items-center gap-2 text-sm font-semibold text-warm-900">
                        <Package className="h-4 w-4 text-primary-600" /> Productos a reservar
                    </h2>
                    <span className="text-xs text-warm-500">
                        {items.length} {items.length === 1 ? 'ítem agregado' : 'ítems agregados'}
                    </span>
                </div>
                <div className="overflow-x-auto">
                    <table className="w-full min-w-[880px] text-sm">
                        <thead>
                            <tr className="bg-primary-600 text-left text-xs font-semibold uppercase tracking-wide text-white">
                                <th className="w-12 px-3 py-2.5 text-center">#</th>
                                <th className="w-28 px-3 py-2.5">Código</th>
                                <th className="px-3 py-2.5">Producto</th>
                                <th className="w-36 px-3 py-2.5">Unidad</th>
                                <th className="w-24 px-3 py-2.5 text-right">Disp.</th>
                                <th className="w-28 px-3 py-2.5 text-right">Cant</th>
                                <th className="w-28 px-3 py-2.5 text-right">Precio</th>
                                <th className="w-28 px-3 py-2.5 text-right">Subtotal</th>
                                <th className="w-16 px-3 py-2.5 text-center">—</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {items.length === 0 && (
                                <tr>
                                    <td colSpan={9} className="px-3 py-10 text-center text-sm text-warm-500">
                                        Busca un producto arriba para agregarlo al pedido
                                    </td>
                                </tr>
                            )}

                            {items.map((it, i) => {
                                const producto = productoDe(it.producto_id);
                                const u = disponibleDe(it.producto_id, it.producto_presentacion_id);
                                const excede = excedeDisponible(it);
                                const sub = (Number(it.cantidad) || 0) * (Number(it.precio_unitario) || 0);

                                return (
                                    <tr key={i}>
                                        <td className="px-3 py-2 text-center text-warm-500">{i + 1}</td>
                                        <td className="px-3 py-2 font-medium text-warm-900">{producto?.codigo ?? '—'}</td>
                                        <td className="px-3 py-2 font-semibold text-warm-900">{producto?.nombre ?? '—'}</td>
                                        <td className="px-3 py-2">
                                            <Select
                                                value={it.producto_presentacion_id}
                                                onChange={(e) => cambiarUnidadItem(i, e.target.value)}
                                                options={unidadesDe(it.producto_id)}
                                                aria-label="Unidad"
                                            />
                                        </td>
                                        <td className="px-3 py-2 text-right text-warm-500">
                                            {u ? num(u.disponible) : '—'}
                                        </td>
                                        <td className="px-3 py-2">
                                            <Input
                                                type="number"
                                                min="0"
                                                step="any"
                                                value={it.cantidad}
                                                onChange={(e) => setItem(i, { cantidad: e.target.value })}
                                                aria-label="Cantidad"
                                                error={excede ? 'Sin stock' : undefined}
                                                className="text-right"
                                            />
                                        </td>
                                        <td className="px-3 py-2">
                                            <Input
                                                type="number"
                                                min="0"
                                                step="any"
                                                value={it.precio_unitario}
                                                onChange={(e) => setItem(i, { precio_unitario: e.target.value })}
                                                aria-label="Precio unitario"
                                                className="text-right"
                                            />
                                        </td>
                                        <td className="px-3 py-2 text-right font-semibold text-primary-600">{money(sub)}</td>
                                        <td className="px-3 py-2">
                                            <div className="flex items-center justify-center">
                                                <button
                                                    type="button"
                                                    onClick={() => quitarItem(i)}
                                                    aria-label="Quitar"
                                                    className="rounded-md p-1.5 text-red-600 transition hover:bg-red-50"
                                                >
                                                    <Trash2 className="h-4 w-4" />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>
            </div>

            <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1fr_360px]">
                <div className="rounded-xl border border-edge bg-white p-5 shadow-sm">
                    <h2 className="mb-2 text-xs font-bold uppercase tracking-wide text-warm-500">Observaciones</h2>
                    <textarea
                        rows={3}
                        value={form.observaciones}
                        onChange={(e) => setField('observaciones', e.target.value)}
                        placeholder="Notas de este pedido (dirección de entrega, indicaciones…)"
                        className="block w-full resize-none rounded-lg border-0 bg-white p-3 text-sm text-gray-900 ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-primary-600"
                    />
                </div>

                {/* Resumen */}
                <div className="lg:sticky lg:top-6 lg:self-start">
                    <div className="rounded-xl border border-edge bg-white p-5 shadow-sm">
                        <h2 className="mb-3 text-xs font-bold uppercase tracking-wide text-warm-500">Resumen</h2>
                        <div className="flex items-center justify-between border-b border-dashed border-edge pb-2 text-sm">
                            <span className="text-warm-500">Cliente</span>
                            <span className="max-w-[180px] truncate font-medium text-warm-900">
                                {clientes.find((c) => String(c.id) === String(form.cliente_id))?.nombre ??
                                    CLIENTE_GENERICO}
                            </span>
                        </div>
                        <div className="mt-1 flex items-center justify-between border-t border-edge pt-3">
                            <span className="text-sm font-bold uppercase tracking-wide text-primary-700">Total</span>
                            <span className="text-2xl font-extrabold text-warm-900">{money(total)}</span>
                        </div>

                        <div className="mt-5 flex flex-col gap-2">
                            <Button onClick={guardar} loading={saving} className="w-full justify-center">
                                {editando ? 'Guardar cambios' : 'Registrar pedido'}
                            </Button>
                            <Button
                                variant="secondary"
                                onClick={() => navigate('/pedidos')}
                                className="w-full justify-center"
                            >
                                Cancelar
                            </Button>
                        </div>
                        <p className="mt-3 text-xs text-gray-400">
                            El stock se reserva, no se descuenta: sigue en el almacén pero deja de estar disponible
                            para otras ventas hasta que el pedido se convierta en venta o se cancele.
                        </p>
                    </div>
                </div>
            </div>

            <ProductoPickerModal
                open={picker.open}
                onClose={() => setPicker((prev) => ({ ...prev, open: false }))}
                onSelect={agregarDesdePicker}
                initialQuery={picker.query}
                multiple
                productos={productosDisponibles}
                stockPorProducto={stockDelAlmacen}
                title="Buscar productos"
            />
        </Layout>
    );
}
