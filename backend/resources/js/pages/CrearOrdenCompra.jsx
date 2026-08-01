import { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, FileText, Package, Plus, Trash2 } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import { Button, Input, Select, Spinner } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const hoy = () => new Date().toISOString().slice(0, 10);

const emptyLinea = { producto_presentacion_id: '', cantidad: '1', precio_unitario: '0' };

export default function CrearOrdenCompra() {
    const toast = useToast();
    const navigate = useNavigate();

    const [proveedores, setProveedores] = useState([]);
    const [productos, setProductos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [formErrors, setFormErrors] = useState({});

    const [form, setForm] = useState({
        codigo: '',
        proveedor_id: '',
        fecha_emision: hoy(),
        fecha_entrega_estimada: '',
        observaciones: '',
    });
    const [lineas, setLineas] = useState([{ ...emptyLinea }]);

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

    const setField = (name, value) => {
        setForm((prev) => ({ ...prev, [name]: value }));
        if (formErrors[name]) setFormErrors((prev) => ({ ...prev, [name]: undefined }));
    };

    const setLinea = (i, patch) => setLineas((prev) => prev.map((l, idx) => (idx === i ? { ...l, ...patch } : l)));
    const addLinea = () => setLineas((prev) => [...prev, { ...emptyLinea }]);
    const removeLinea = (i) => setLineas((prev) => (prev.length === 1 ? prev : prev.filter((_, idx) => idx !== i)));

    const total = lineas.reduce((acc, l) => acc + (Number(l.cantidad) || 0) * (Number(l.precio_unitario) || 0), 0);

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
            await api.post('/ordenes-compra', {
                codigo: form.codigo,
                proveedor_id: form.proveedor_id,
                fecha_emision: form.fecha_emision,
                fecha_entrega_estimada: form.fecha_entrega_estimada || null,
                moneda: 'PEN',
                observaciones: form.observaciones,
                detalles: lineasValidas.map((l) => ({
                    producto_presentacion_id: l.producto_presentacion_id,
                    cantidad: l.cantidad,
                    precio_unitario: l.precio_unitario || 0,
                })),
            });
            toast.success('Orden de compra creada correctamente.');
            navigate('/ordenes-compra');
        } catch (err) {
            if (err.response?.status === 422) {
                setFormErrors(Object.fromEntries(Object.entries(err.response.data?.errors ?? {}).map(([k, v]) => [k, v[0]])));
                toast.error('Revisa los datos del formulario.');
            } else {
                toast.error('No se pudo crear la orden.');
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
            <div className="mb-6 flex items-center gap-3">
                <button
                    onClick={() => navigate('/ordenes-compra')}
                    className="flex h-9 w-9 items-center justify-center rounded-lg border border-edge text-gray-500 transition hover:bg-gray-50 hover:text-gray-800"
                    aria-label="Volver"
                >
                    <ArrowLeft className="h-4 w-4" />
                </button>
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary-50 text-primary-600">
                    <FileText className="h-5 w-5" />
                </div>
                <div>
                    <h1 className="text-xl font-bold tracking-tight text-warm-900">Crear Orden de Compra</h1>
                    <p className="text-sm text-warm-500">Pedido formal de productos al proveedor</p>
                </div>
            </div>

            {/* Datos de la orden */}
            <div className="mb-6 rounded-xl border border-edge bg-white shadow-sm">
                <div className="border-b border-edge px-5 py-3">
                    <h2 className="text-xs font-bold uppercase tracking-wide text-warm-500">Datos de la orden</h2>
                </div>
                <div className="grid grid-cols-2 gap-4 p-5 md:grid-cols-4">
                    <Input label="Código" placeholder="OC-001" value={form.codigo} onChange={(e) => setField('codigo', e.target.value)} error={formErrors.codigo} />
                    <Select
                        label="Proveedor"
                        value={form.proveedor_id}
                        onChange={(e) => setField('proveedor_id', e.target.value)}
                        options={[{ value: '', label: 'Selecciona…' }, ...proveedores.map((p) => ({ value: String(p.id), label: p.nombre }))]}
                        error={formErrors.proveedor_id}
                        className="md:col-span-2"
                    />
                    <Input label="Fecha emisión" type="date" value={form.fecha_emision} onChange={(e) => setField('fecha_emision', e.target.value)} error={formErrors.fecha_emision} />
                    <Input label="Entrega estimada" type="date" value={form.fecha_entrega_estimada} onChange={(e) => setField('fecha_entrega_estimada', e.target.value)} />
                </div>
            </div>

            {/* Productos */}
            <div className="mb-6 rounded-xl border border-edge bg-white shadow-sm">
                <div className="flex items-center justify-between border-b border-edge px-5 py-3">
                    <h2 className="inline-flex items-center gap-2 text-xs font-bold uppercase tracking-wide text-warm-500">
                        <Package className="h-4 w-4" /> Productos a pedir
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
                                            onChange={(e) => setLinea(i, { producto_presentacion_id: e.target.value })}
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

            {/* Observaciones + total */}
            <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1fr_360px]">
                <div className="rounded-xl border border-edge bg-white p-5 shadow-sm">
                    <h2 className="mb-2 text-xs font-bold uppercase tracking-wide text-warm-500">Observaciones</h2>
                    <textarea
                        rows={3}
                        value={form.observaciones}
                        onChange={(e) => setField('observaciones', e.target.value)}
                        placeholder="Notas para el proveedor o internas…"
                        className="block w-full resize-none rounded-lg border-0 bg-white p-3 text-sm text-gray-900 ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-primary-600"
                    />
                </div>

                <div className="lg:sticky lg:top-6 lg:self-start">
                    <div className="rounded-xl border border-edge bg-white p-5 shadow-sm">
                        <h2 className="mb-3 text-xs font-bold uppercase tracking-wide text-warm-500">Resumen</h2>
                        <div className="mt-1 flex items-center justify-between border-t border-edge pt-3">
                            <span className="text-sm font-bold uppercase tracking-wide text-primary-700">Total</span>
                            <span className="text-2xl font-extrabold text-warm-900">{money(total)}</span>
                        </div>
                        <div className="mt-5 flex flex-col gap-2">
                            <Button onClick={guardar} loading={saving} className="w-full justify-center">
                                Crear orden
                            </Button>
                            <Button variant="secondary" onClick={() => navigate('/ordenes-compra')} className="w-full justify-center">
                                Cancelar
                            </Button>
                        </div>
                    </div>
                </div>
            </div>
        </Layout>
    );
}
