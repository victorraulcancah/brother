import { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Package, Plus, ReceiptText, Trash2, Wallet } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import { useAuth } from '../lib/auth';
import Layout from '../components/Layout';
import { Button, Input, Select, Spinner } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const hoy = () => new Date().toISOString().slice(0, 10);

const FORMAS_PAGO = [
    { value: 'efectivo', label: 'Efectivo' },
    { value: 'transferencia', label: 'Transferencia' },
    { value: 'tarjeta', label: 'Tarjeta' },
    { value: 'yape', label: 'Yape' },
    { value: 'plin', label: 'Plin' },
    { value: 'otro', label: 'Otro' },
];

const emptyLinea = { producto_presentacion_id: '', cantidad: '1', precio_unitario: '0' };

export default function CrearVenta() {
    const toast = useToast();
    const navigate = useNavigate();
    const { user } = useAuth();

    const [clientes, setClientes] = useState([]);
    const [almacenes, setAlmacenes] = useState([]);
    const [productos, setProductos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);

    const [form, setForm] = useState({
        cliente_id: '',
        almacen_id: '',
        fecha_emision: hoy(),
        tipo_pago: 'contado',
        observaciones: '',
    });
    const [lineas, setLineas] = useState([{ ...emptyLinea }]);
    const [pagos, setPagos] = useState([{ forma_pago: 'efectivo', monto: '' }]);

    const load = useCallback(async () => {
        setLoading(true);
        try {
            const [cliRes, almRes, prodRes] = await Promise.all([
                api.get('/clientes'),
                api.get('/almacenes'),
                api.get('/productos'),
            ]);
            setClientes(asList(cliRes));
            setAlmacenes(asList(almRes));
            setProductos(asList(prodRes));
        } catch {
            toast.error('No se pudieron cargar los datos.');
        } finally {
            setLoading(false);
        }
    }, [toast]);

    useEffect(() => {
        load();
    }, [load]);

    // Opciones de presentación + precio de venta por presentación
    const { presentacionesOptions, precioMap } = useMemo(() => {
        const options = [];
        const map = {};
        productos.forEach((p) => {
            (Array.isArray(p.presentaciones) ? p.presentaciones : []).forEach((pres) => {
                options.push({ value: String(pres.id), label: `${p.nombre} — ${pres.nombre}` });
                map[String(pres.id)] = Number(pres.precio_venta) || 0;
            });
        });
        return { presentacionesOptions: options, precioMap: map };
    }, [productos]);

    const setField = (name, value) => setForm((prev) => ({ ...prev, [name]: value }));

    const setLinea = (i, patch) => setLineas((prev) => prev.map((l, idx) => (idx === i ? { ...l, ...patch } : l)));
    const addLinea = () => setLineas((prev) => [...prev, { ...emptyLinea }]);
    const removeLinea = (i) => setLineas((prev) => (prev.length === 1 ? prev : prev.filter((_, idx) => idx !== i)));

    const onPickProducto = (i, presId) => {
        // Al elegir producto, autocompleta el precio de venta.
        setLinea(i, { producto_presentacion_id: presId, precio_unitario: String(precioMap[presId] ?? 0) });
    };

    const setPago = (i, patch) => setPagos((prev) => prev.map((p, idx) => (idx === i ? { ...p, ...patch } : p)));
    const addPago = () => setPagos((prev) => [...prev, { forma_pago: 'efectivo', monto: '' }]);
    const removePago = (i) => setPagos((prev) => prev.filter((_, idx) => idx !== i));

    const total = lineas.reduce((acc, l) => acc + (Number(l.cantidad) || 0) * (Number(l.precio_unitario) || 0), 0);
    const pagado = pagos.reduce((acc, p) => acc + (Number(p.monto) || 0), 0);
    const saldo = total - pagado;

    const guardar = async () => {
        setSaving(true);

        const lineasValidas = lineas.filter((l) => l.producto_presentacion_id && Number(l.cantidad) > 0);
        if (lineasValidas.length === 0) {
            toast.error('Agrega al menos un producto.');
            setSaving(false);
            return;
        }
        if (!form.almacen_id) {
            toast.error('Selecciona el almacén.');
            setSaving(false);
            return;
        }
        if (form.tipo_pago === 'credito' && !form.cliente_id) {
            toast.error('Para una venta al crédito debes seleccionar un cliente.');
            setSaving(false);
            return;
        }

        const detalles = lineasValidas.map((l) => {
            const cantidad = Number(l.cantidad) || 0;
            const precio = Number(l.precio_unitario) || 0;
            return {
                producto_presentacion_id: l.producto_presentacion_id,
                cantidad,
                precio_unitario: precio,
                descuento: 0,
                subtotal: Math.round(cantidad * precio * 100) / 100,
            };
        });

        const pagosPayload =
            form.tipo_pago === 'contado'
                ? pagos
                      .filter((p) => Number(p.monto) > 0)
                      .map((p) => ({ metodo_pago_id: null, forma_pago: p.forma_pago, monto: Number(p.monto), fecha: form.fecha_emision, referencia: null }))
                : [{ metodo_pago_id: null, forma_pago: 'credito', monto: total, fecha: form.fecha_emision, referencia: null }];

        if (pagosPayload.length === 0) {
            toast.error('Agrega al menos un pago.');
            setSaving(false);
            return;
        }

        try {
            await api.post('/notas-venta', {
                cliente_id: form.cliente_id || null,
                almacen_id: form.almacen_id,
                vendedor_id: user?.id,
                fecha_emision: form.fecha_emision,
                moneda: 'PEN',
                tipo_pago: form.tipo_pago,
                subtotal: total,
                descuento_total: 0,
                total,
                observaciones: form.observaciones,
                serie: 'NV01',
                detalles,
                pagos: pagosPayload,
            });
            toast.success('Venta registrada. Stock descontado del almacén.');
            navigate('/notas-venta');
        } catch (err) {
            const msg = err.response?.data?.message;
            const firstErr = err.response?.data?.errors ? Object.values(err.response.data.errors)[0]?.[0] : null;
            toast.error(firstErr ?? msg ?? 'No se pudo registrar la venta.');
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
            <div className="mb-6 flex items-center gap-3">
                <button
                    onClick={() => navigate('/notas-venta')}
                    className="flex h-9 w-9 items-center justify-center rounded-lg border border-edge text-gray-500 transition hover:bg-gray-50 hover:text-gray-800"
                    aria-label="Volver"
                >
                    <ArrowLeft className="h-4 w-4" />
                </button>
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary-50 text-primary-600">
                    <ReceiptText className="h-5 w-5" />
                </div>
                <div>
                    <h1 className="text-xl font-bold tracking-tight text-warm-900">Nueva Venta</h1>
                    <p className="text-sm text-warm-500">Registra una venta y descuenta el stock</p>
                </div>
            </div>

            {/* Datos */}
            <div className="mb-6 rounded-xl border border-edge bg-white shadow-sm">
                <div className="border-b border-edge px-5 py-3">
                    <h2 className="text-xs font-bold uppercase tracking-wide text-warm-500">Datos de la venta</h2>
                </div>
                <div className="grid grid-cols-2 gap-4 p-5 md:grid-cols-4">
                    <Select
                        label="Cliente"
                        value={form.cliente_id}
                        onChange={(e) => setField('cliente_id', e.target.value)}
                        options={[{ value: '', label: 'Público general' }, ...clientes.map((c) => ({ value: String(c.id), label: c.nombre }))]}
                        className="md:col-span-2"
                    />
                    <Select
                        label="Almacén"
                        value={form.almacen_id}
                        onChange={(e) => setField('almacen_id', e.target.value)}
                        options={[{ value: '', label: 'Selecciona…' }, ...almacenes.map((a) => ({ value: String(a.id), label: a.nombre }))]}
                    />
                    <Input label="Fecha" type="date" value={form.fecha_emision} onChange={(e) => setField('fecha_emision', e.target.value)} />
                    <Select
                        label="Tipo de pago"
                        value={form.tipo_pago}
                        onChange={(e) => setField('tipo_pago', e.target.value)}
                        options={[
                            { value: 'contado', label: 'Contado' },
                            { value: 'credito', label: 'Crédito' },
                        ]}
                    />
                </div>
            </div>

            {/* Productos */}
            <div className="mb-6 rounded-xl border border-edge bg-white shadow-sm">
                <div className="flex items-center justify-between border-b border-edge px-5 py-3">
                    <h2 className="inline-flex items-center gap-2 text-xs font-bold uppercase tracking-wide text-warm-500">
                        <Package className="h-4 w-4" /> Productos
                    </h2>
                    <Button type="button" variant="ghost" size="sm" onClick={addLinea}>
                        <Plus className="h-4 w-4" /> Agregar línea
                    </Button>
                </div>
                <div className="overflow-x-auto">
                    <table className="w-full min-w-[680px] text-sm">
                        <thead>
                            <tr className="bg-primary-600 text-left text-xs font-semibold uppercase tracking-wide text-white">
                                <th className="px-3 py-2.5">Producto / Presentación</th>
                                <th className="px-3 py-2.5 text-right">Cantidad</th>
                                <th className="px-3 py-2.5 text-right">Precio (S/)</th>
                                <th className="px-3 py-2.5 text-right">Subtotal</th>
                                <th className="px-3 py-2.5 text-center">—</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {lineas.map((l, i) => (
                                <tr key={i}>
                                    <td className="px-3 py-2">
                                        <Select
                                            value={l.producto_presentacion_id}
                                            onChange={(e) => onPickProducto(i, e.target.value)}
                                            options={[{ value: '', label: 'Selecciona producto…' }, ...presentacionesOptions]}
                                        />
                                    </td>
                                    <td className="px-3 py-2">
                                        <Input type="number" min="0" step="any" value={l.cantidad} onChange={(e) => setLinea(i, { cantidad: e.target.value })} className="text-right" />
                                    </td>
                                    <td className="px-3 py-2">
                                        <Input type="number" min="0" step="any" value={l.precio_unitario} onChange={(e) => setLinea(i, { precio_unitario: e.target.value })} className="text-right" />
                                    </td>
                                    <td className="px-3 py-2 text-right font-medium text-warm-900">
                                        {money((Number(l.cantidad) || 0) * (Number(l.precio_unitario) || 0))}
                                    </td>
                                    <td className="px-3 py-2 text-center">
                                        <button type="button" onClick={() => removeLinea(i)} disabled={lineas.length === 1}
                                            className="rounded-md p-1.5 text-red-600 transition hover:bg-red-50 disabled:opacity-40" aria-label="Quitar">
                                            <Trash2 className="h-4 w-4" />
                                        </button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Pagos + Total */}
            <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1fr_360px]">
                <div className="space-y-6">
                    {form.tipo_pago === 'contado' ? (
                        <div className="rounded-xl border border-edge bg-white p-5 shadow-sm">
                            <div className="mb-3 flex items-center justify-between">
                                <h2 className="inline-flex items-center gap-2 text-xs font-bold uppercase tracking-wide text-warm-500">
                                    <Wallet className="h-4 w-4" /> Pagos (mixto)
                                </h2>
                                <Button type="button" variant="ghost" size="sm" onClick={addPago}>
                                    <Plus className="h-4 w-4" /> Agregar pago
                                </Button>
                            </div>
                            <div className="space-y-2">
                                {pagos.map((p, i) => (
                                    <div key={i} className="flex items-center gap-2">
                                        <Select value={p.forma_pago} onChange={(e) => setPago(i, { forma_pago: e.target.value })} options={FORMAS_PAGO} className="flex-1" />
                                        <Input type="number" min="0" step="any" placeholder="Monto" value={p.monto} onChange={(e) => setPago(i, { monto: e.target.value })} className="w-32 text-right" />
                                        <button type="button" onClick={() => removePago(i)} className="rounded-md p-2 text-red-600 transition hover:bg-red-50" aria-label="Quitar">
                                            <Trash2 className="h-4 w-4" />
                                        </button>
                                    </div>
                                ))}
                            </div>
                            <div className="mt-3 flex justify-between border-t border-dashed border-edge pt-2 text-sm">
                                <span className="text-warm-500">Pagado</span>
                                <span className="font-semibold text-green-600">{money(pagado)}</span>
                            </div>
                            {Math.abs(saldo) > 0.001 && (
                                <div className="flex justify-between text-sm">
                                    <span className="text-warm-500">{saldo > 0 ? 'Falta' : 'Vuelto'}</span>
                                    <span className={saldo > 0 ? 'font-semibold text-amber-600' : 'font-semibold text-blue-600'}>{money(Math.abs(saldo))}</span>
                                </div>
                            )}
                        </div>
                    ) : (
                        <Alert variant="info">
                            Venta al <strong>crédito</strong>: se generará una <strong>Cuenta por Cobrar</strong> por el total. El cliente es obligatorio para el crédito.
                        </Alert>
                    )}

                    <div className="rounded-xl border border-edge bg-white p-5 shadow-sm">
                        <h2 className="mb-2 text-xs font-bold uppercase tracking-wide text-warm-500">Observaciones</h2>
                        <textarea
                            rows={3}
                            value={form.observaciones}
                            onChange={(e) => setField('observaciones', e.target.value)}
                            placeholder="Notas de la venta…"
                            className="block w-full resize-none rounded-lg border-0 bg-white p-3 text-sm text-gray-900 ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-primary-600"
                        />
                    </div>
                </div>

                <div className="lg:sticky lg:top-6 lg:self-start">
                    <div className="rounded-xl border border-edge bg-white p-5 shadow-sm">
                        <h2 className="mb-3 text-xs font-bold uppercase tracking-wide text-warm-500">Resumen</h2>
                        <div className="flex justify-between border-b border-dashed border-edge py-2 text-sm">
                            <span className="text-warm-500">Subtotal</span>
                            <span className="font-medium text-warm-900">{money(total)}</span>
                        </div>
                        <div className="mt-3 flex items-center justify-between border-t border-edge pt-3">
                            <span className="text-sm font-bold uppercase tracking-wide text-primary-700">Total</span>
                            <span className="text-2xl font-extrabold text-warm-900">{money(total)}</span>
                        </div>
                        <div className="mt-5 flex flex-col gap-2">
                            <Button onClick={guardar} loading={saving} className="w-full justify-center">
                                Registrar venta
                            </Button>
                            <Button variant="secondary" onClick={() => navigate('/notas-venta')} className="w-full justify-center">
                                Cancelar
                            </Button>
                        </div>
                        <p className="mt-3 text-xs text-gray-400">
                            Al registrar, el stock sale del almacén y se refleja en el Kardex.
                        </p>
                    </div>
                </div>
            </div>
        </Layout>
    );
}
