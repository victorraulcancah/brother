import { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Package, Plus, ShoppingBag, Trash2, Wallet } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import { Alert, Button, Input, Select, Spinner } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const hoy = () => new Date().toISOString().slice(0, 10);

const METODOS_PAGO = [
    { value: 'efectivo', label: 'Efectivo' },
    { value: 'transferencia', label: 'Transferencia' },
    { value: 'tarjeta', label: 'Tarjeta' },
    { value: 'yape', label: 'Yape' },
    { value: 'plin', label: 'Plin' },
    { value: 'otro', label: 'Otro' },
];

const emptyLinea = { producto_presentacion_id: '', cantidad: '1', costo_unitario: '0' };

export default function CrearCompra() {
    const toast = useToast();
    const navigate = useNavigate();

    const [proveedores, setProveedores] = useState([]);
    const [productos, setProductos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [formErrors, setFormErrors] = useState({});

    const [form, setForm] = useState({
        proveedor_id: '',
        tipo_documento: 'factura',
        serie: '',
        numero: '',
        guia: '',
        fecha: hoy(),
        forma_pago: 'contado',
        dias_credito: 0,
        fecha_vencimiento: hoy(),
        flete: '0',
        observaciones: '',
    });
    const [lineas, setLineas] = useState([{ ...emptyLinea }]);
    const [pagos, setPagos] = useState([{ metodo: 'efectivo', monto: '' }]);

    const load = useCallback(async () => {
        setLoading(true);
        try {
            const [provRes, prodRes] = await Promise.all([
                api.get('/proveedores'),
                api.get('/productos'),
            ]);
            setProveedores(asList(provRes));
            setProductos(asList(prodRes));
        } catch {
            toast.error('No se pudieron cargar proveedores/productos.');
        } finally {
            setLoading(false);
        }
    }, [toast]);

    useEffect(() => {
        load();
    }, [load]);

    const presentacionesOptions = useMemo(
        () =>
            productos.flatMap((p) =>
                (Array.isArray(p.presentaciones) ? p.presentaciones : []).map((pres) => ({
                    value: String(pres.id),
                    label: `${p.nombre} — ${pres.nombre}`,
                })),
            ),
        [productos],
    );

    const setField = (name, value) => setForm((prev) => ({ ...prev, [name]: value }));

    const setLinea = (i, patch) => setLineas((prev) => prev.map((l, idx) => (idx === i ? { ...l, ...patch } : l)));
    const addLinea = () => setLineas((prev) => [...prev, { ...emptyLinea }]);
    const removeLinea = (i) => setLineas((prev) => (prev.length === 1 ? prev : prev.filter((_, idx) => idx !== i)));

    const setPago = (i, patch) => setPagos((prev) => prev.map((p, idx) => (idx === i ? { ...p, ...patch } : p)));
    const addPago = () => setPagos((prev) => [...prev, { metodo: 'efectivo', monto: '' }]);
    const removePago = (i) => setPagos((prev) => prev.filter((_, idx) => idx !== i));

    const subtotal = lineas.reduce((acc, l) => acc + (Number(l.cantidad) || 0) * (Number(l.costo_unitario) || 0), 0);
    const flete = Number(form.flete) || 0;
    const total = subtotal + flete;
    const pagado = pagos.reduce((acc, p) => acc + (Number(p.monto) || 0), 0);
    const saldo = total - pagado;

    const guardar = async () => {
        setSaving(true);
        setFormErrors({});

        const lineasValidas = lineas.filter((l) => l.producto_presentacion_id && Number(l.cantidad) > 0);
        if (lineasValidas.length === 0) {
            toast.error('Agrega al menos un producto.');
            setSaving(false);
            return;
        }

        try {
            await api.post('/compras', {
                proveedor_id: form.proveedor_id || null,
                tipo_documento: form.tipo_documento,
                serie: form.serie,
                numero: form.numero,
                guia: form.guia,
                fecha: form.fecha,
                forma_pago: form.forma_pago,
                dias_credito: form.forma_pago === 'credito' ? Number(form.dias_credito) || 0 : 0,
                fecha_vencimiento: form.forma_pago === 'credito' ? form.fecha_vencimiento : null,
                flete,
                observaciones: form.observaciones,
                detalles: lineasValidas.map((l) => ({
                    producto_presentacion_id: l.producto_presentacion_id,
                    cantidad: l.cantidad,
                    costo_unitario: l.costo_unitario,
                })),
                pagos: pagos.filter((p) => Number(p.monto) > 0).map((p) => ({ metodo: p.metodo, monto: p.monto })),
            });
            toast.success('Compra registrada correctamente.');
            navigate('/compras');
        } catch (err) {
            if (err.response?.status === 422) {
                setFormErrors(Object.fromEntries(Object.entries(err.response.data?.errors ?? {}).map(([k, v]) => [k, v[0]])));
                toast.error('Revisa los datos del formulario.');
            } else {
                toast.error('No se pudo registrar la compra.');
            }
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
            <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                    <button
                        onClick={() => navigate('/compras')}
                        className="flex h-9 w-9 items-center justify-center rounded-lg border border-edge text-gray-500 transition hover:bg-gray-50 hover:text-gray-800"
                        aria-label="Volver"
                    >
                        <ArrowLeft className="h-4 w-4" />
                    </button>
                    <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary-50 text-primary-600">
                        <ShoppingBag className="h-5 w-5" />
                    </div>
                    <div>
                        <h1 className="text-xl font-bold tracking-tight text-warm-900">Crear Compra</h1>
                        <p className="text-sm text-warm-500">Comprobante del proveedor y registro de pago</p>
                    </div>
                </div>
            </div>

            {/* Datos del comprobante */}
            <div className="mb-6 rounded-xl border border-edge bg-white shadow-sm">
                <div className="border-b border-edge px-5 py-3">
                    <h2 className="text-xs font-bold uppercase tracking-wide text-warm-500">Datos del comprobante</h2>
                </div>
                <div className="grid grid-cols-2 gap-4 p-5 md:grid-cols-4">
                    <Input label="Fecha" type="date" value={form.fecha} onChange={(e) => setField('fecha', e.target.value)} error={formErrors.fecha} />
                    <Select
                        label="Proveedor"
                        value={form.proveedor_id}
                        onChange={(e) => setField('proveedor_id', e.target.value)}
                        options={[{ value: '', label: 'Sin proveedor' }, ...proveedores.map((p) => ({ value: String(p.id), label: p.nombre }))]}
                        className="col-span-2"
                    />
                    <Select
                        label="Tipo documento"
                        value={form.tipo_documento}
                        onChange={(e) => setField('tipo_documento', e.target.value)}
                        options={[
                            { value: 'factura', label: 'Factura' },
                            { value: 'boleta', label: 'Boleta' },
                            { value: 'guia', label: 'Guía de Remisión' },
                        ]}
                    />
                    <Input label="Serie" placeholder="F001" value={form.serie} onChange={(e) => setField('serie', e.target.value)} />
                    <Input label="Número" placeholder="00000000" value={form.numero} onChange={(e) => setField('numero', e.target.value)} />
                    <Input label="Guía" placeholder="T001-00001" value={form.guia} onChange={(e) => setField('guia', e.target.value)} />
                    <Select
                        label="Forma de pago"
                        value={form.forma_pago}
                        onChange={(e) => setField('forma_pago', e.target.value)}
                        options={[
                            { value: 'contado', label: 'Contado' },
                            { value: 'credito', label: 'Crédito' },
                        ]}
                    />
                    {form.forma_pago === 'credito' && (
                        <>
                            <Input label="N° días" type="number" min="0" value={form.dias_credito} onChange={(e) => setField('dias_credito', e.target.value)} />
                            <Input label="Vencimiento" type="date" value={form.fecha_vencimiento} onChange={(e) => setField('fecha_vencimiento', e.target.value)} />
                        </>
                    )}
                </div>
            </div>

            {/* Productos */}
            <div className="mb-6 rounded-xl border border-edge bg-white shadow-sm">
                <div className="flex items-center justify-between border-b border-edge px-5 py-3">
                    <h2 className="inline-flex items-center gap-2 text-xs font-bold uppercase tracking-wide text-warm-500">
                        <Package className="h-4 w-4" /> Productos de la compra
                    </h2>
                    <Button type="button" variant="ghost" size="sm" onClick={addLinea}>
                        <Plus className="h-4 w-4" /> Agregar línea
                    </Button>
                </div>
                <div className="overflow-x-auto">
                    <table className="w-full min-w-[720px] text-sm">
                        <thead>
                            <tr className="bg-primary-600 text-left text-xs font-semibold uppercase tracking-wide text-white">
                                <th className="px-3 py-2.5">Producto / Presentación</th>
                                <th className="px-3 py-2.5 text-right">Cantidad</th>
                                <th className="px-3 py-2.5 text-right">Costo (S/)</th>
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
                                            onChange={(e) => setLinea(i, { producto_presentacion_id: e.target.value })}
                                            options={[{ value: '', label: 'Selecciona producto…' }, ...presentacionesOptions]}
                                        />
                                    </td>
                                    <td className="px-3 py-2">
                                        <Input type="number" min="0" step="any" value={l.cantidad} onChange={(e) => setLinea(i, { cantidad: e.target.value })} className="text-right" />
                                    </td>
                                    <td className="px-3 py-2">
                                        <Input type="number" min="0" step="any" value={l.costo_unitario} onChange={(e) => setLinea(i, { costo_unitario: e.target.value })} className="text-right" />
                                    </td>
                                    <td className="px-3 py-2 text-right font-medium text-warm-900">
                                        {money((Number(l.cantidad) || 0) * (Number(l.costo_unitario) || 0))}
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

            {/* Pagos mixtos + Totales */}
            <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1fr_360px]">
                <div className="space-y-6">
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
                                    <Select
                                        value={p.metodo}
                                        onChange={(e) => setPago(i, { metodo: e.target.value })}
                                        options={METODOS_PAGO}
                                        className="flex-1"
                                    />
                                    <Input type="number" min="0" step="any" placeholder="Monto" value={p.monto} onChange={(e) => setPago(i, { monto: e.target.value })} className="w-32 text-right" />
                                    <button type="button" onClick={() => removePago(i)}
                                        className="rounded-md p-2 text-red-600 transition hover:bg-red-50" aria-label="Quitar">
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
                                <span className="text-warm-500">{saldo > 0 ? 'Saldo por pagar' : 'Exceso'}</span>
                                <span className={saldo > 0 ? 'font-semibold text-amber-600' : 'font-semibold text-red-600'}>{money(Math.abs(saldo))}</span>
                            </div>
                        )}
                    </div>

                    <div className="rounded-xl border border-edge bg-white p-5 shadow-sm">
                        <h2 className="mb-2 text-xs font-bold uppercase tracking-wide text-warm-500">Observaciones</h2>
                        <textarea
                            rows={3}
                            value={form.observaciones}
                            onChange={(e) => setField('observaciones', e.target.value)}
                            placeholder="Notas internas de esta compra…"
                            className="block w-full resize-none rounded-lg border-0 bg-white p-3 text-sm text-gray-900 ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-primary-600"
                        />
                    </div>
                </div>

                {/* Panel de totales */}
                <div className="lg:sticky lg:top-6 lg:self-start">
                    <div className="rounded-xl border border-edge bg-white p-5 shadow-sm">
                        <h2 className="mb-3 text-xs font-bold uppercase tracking-wide text-warm-500">Resumen</h2>
                        <div className="flex justify-between border-b border-dashed border-edge py-2 text-sm">
                            <span className="text-warm-500">Subtotal</span>
                            <span className="font-medium text-warm-900">{money(subtotal)}</span>
                        </div>
                        <div className="flex items-center justify-between border-b border-dashed border-edge py-2 text-sm">
                            <span className="text-warm-500">Flete</span>
                            <input
                                type="number"
                                min="0"
                                step="any"
                                value={form.flete}
                                onChange={(e) => setField('flete', e.target.value)}
                                className="w-28 rounded-md border-0 bg-white px-2 py-1 text-right text-sm ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-primary-600"
                            />
                        </div>
                        <div className="mt-3 flex items-center justify-between border-t border-edge pt-3">
                            <span className="text-sm font-bold uppercase tracking-wide text-primary-700">Total</span>
                            <span className="text-2xl font-extrabold text-warm-900">{money(total)}</span>
                        </div>

                        <div className="mt-5 flex flex-col gap-2">
                            <Button onClick={guardar} loading={saving} className="w-full justify-center">
                                Registrar compra
                            </Button>
                            <Button variant="secondary" onClick={() => navigate('/compras')} className="w-full justify-center">
                                Cancelar
                            </Button>
                        </div>
                        <p className="mt-3 text-xs text-gray-400">
                            La compra registra el comprobante y el pago. El stock ingresa al almacén desde Recepciones.
                        </p>
                    </div>
                </div>
            </div>
        </Layout>
    );
}
