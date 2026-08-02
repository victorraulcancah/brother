import { useCallback, useEffect, useState } from 'react';
import { Truck, Plus, Trash2 } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal, Select } from '../components/ui';

const emptyDetalle = { producto_presentacion_id: '', cantidad_recibida: '', costo_unitario: '' };

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const hoy = () => new Date().toISOString().slice(0, 10);

export default function RecepcionesCompra() {
    const toast = useToast();
    const [recepciones, setRecepciones] = useState([]);
    const [proveedores, setProveedores] = useState([]);
    const [almacenes, setAlmacenes] = useState([]);
    const [productos, setProductos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const [modalOpen, setModalOpen] = useState(false);
    const [form, setForm] = useState({ proveedor_id: '', almacen_id: '', numero_documento: '', tipo_documento: 'factura', fecha_recepcion: hoy(), observaciones: '' });
    const [detalles, setDetalles] = useState([{ ...emptyDetalle }]);
    const [formErrors, setFormErrors] = useState({});
    const [saving, setSaving] = useState(false);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const [recRes, provRes, almRes, prodRes] = await Promise.all([
                api.get('/recepciones-compra'),
                api.get('/proveedores'),
                api.get('/almacenes'),
                api.get('/productos'),
            ]);
            setRecepciones(asList(recRes));
            setProveedores(asList(provRes));
            setAlmacenes(asList(almRes));
            setProductos(asList(prodRes));
        } catch {
            setError('No se pudieron cargar las recepciones.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    const presentacionesOptions = productos.flatMap((p) =>
        (Array.isArray(p.presentaciones) ? p.presentaciones : []).map((pres) => ({
            value: String(pres.id),
            label: `${p.nombre} — ${pres.nombre}`,
        })),
    );

    const setDetalle = (i, patch) => setDetalles((prev) => prev.map((d, idx) => (idx === i ? { ...d, ...patch } : d)));
    const addDetalle = () => setDetalles((prev) => [...prev, { ...emptyDetalle }]);
    const removeDetalle = (i) => setDetalles((prev) => (prev.length === 1 ? prev : prev.filter((_, idx) => idx !== i)));

    const total = detalles.reduce((acc, d) => acc + (Number(d.cantidad_recibida) || 0) * (Number(d.costo_unitario) || 0), 0);

    const openCreate = () => {
        setForm({ proveedor_id: '', almacen_id: '', numero_documento: '', tipo_documento: 'factura', fecha_recepcion: hoy(), observaciones: '' });
        setDetalles([{ ...emptyDetalle }]);
        setFormErrors({});
        setModalOpen(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSaving(true);
        setFormErrors({});
        const lineas = detalles.filter((d) => d.producto_presentacion_id && Number(d.cantidad_recibida) > 0);
        if (lineas.length === 0) {
            setFormErrors({ detalles: 'Agrega al menos un producto recibido.' });
            setSaving(false);
            return;
        }
        try {
            await api.post('/recepciones-compra', {
                ...form,
                proveedor_id: form.proveedor_id || null,
                detalles: lineas.map((d) => ({
                    producto_presentacion_id: d.producto_presentacion_id,
                    cantidad_recibida: d.cantidad_recibida,
                    costo_unitario: d.costo_unitario || 0,
                })),
            });
            toast.success('Recepción registrada. Stock ingresado al almacén.');
            setModalOpen(false);
            await load();
        } catch (err) {
            if (err.response?.status === 422) {
                setFormErrors(Object.fromEntries(Object.entries(err.response.data?.errors ?? {}).map(([k, v]) => [k, v[0]])));
                if (err.response.data?.message && !err.response.data?.errors) {
                    toast.error(err.response.data.message);
                }
            } else {
                toast.error('No se pudo registrar la recepción.');
            }
        } finally {
            setSaving(false);
        }
    };

    const columns = [
        {
            key: 'documento',
            label: 'Recepción',
            render: (row) =>
                row.documento ? (
                    <span className="font-semibold text-warm-900">{row.documento}</span>
                ) : (
                    <Badge variant="blue">#{String(row.id).padStart(3, '0')}</Badge>
                ),
        },
        {
            key: 'proveedor',
            label: 'Proveedor',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <Truck className="h-4 w-4 text-primary-600" />
                    {row.proveedor?.nombre ?? '—'}
                </span>
            ),
        },
        { key: 'almacen', label: 'Almacén', render: (row) => <Badge variant="blue">{row.almacen?.nombre ?? '—'}</Badge> },
        { key: 'numero_documento', label: 'Documento', render: (row) => row.numero_documento || <span className="text-gray-400">—</span> },
        { key: 'fecha_recepcion', label: 'Fecha', render: (row) => (row.fecha_recepcion ? new Date(row.fecha_recepcion).toLocaleDateString('es-PE') : '—') },
        { key: 'detalles_count', label: 'Ítems', render: (row) => <Badge variant="gray">{row.detalles_count ?? 0}</Badge> },
        {
            key: 'stock_aplicado',
            label: 'Stock',
            render: (row) => (row.stock_aplicado ? <Badge variant="green">Ingresado</Badge> : <Badge variant="amber">Pendiente</Badge>),
        },
    ];

    return (
        <Layout>
            <PageHeader
                title="Recepciones de Compra"
                description="Ingreso de mercadería al almacén (actualiza stock y costo)"
                actions={<CreateButton onClick={openCreate}>Nueva recepción</CreateButton>}
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable columns={columns} rows={recepciones} loading={loading} searchPlaceholder="Buscar recepciones..." />

            <Modal
                open={modalOpen}
                onClose={() => setModalOpen(false)}
                title="Nueva recepción de compra"
                size="lg"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancelar</Button>
                        <Button type="submit" form="recepcion-form" loading={saving}>Registrar e ingresar stock</Button>
                    </>
                }
            >
                <form id="recepcion-form" onSubmit={handleSubmit} className="space-y-4" noValidate>
                    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                        <Select
                            label="Proveedor"
                            value={form.proveedor_id}
                            onChange={(e) => setForm((p) => ({ ...p, proveedor_id: e.target.value }))}
                            options={[{ value: '', label: 'Sin proveedor' }, ...proveedores.map((p) => ({ value: String(p.id), label: p.nombre }))]}
                        />
                        <Select
                            label="Almacén"
                            value={form.almacen_id}
                            onChange={(e) => setForm((p) => ({ ...p, almacen_id: e.target.value }))}
                            options={[{ value: '', label: 'Selecciona…' }, ...almacenes.map((a) => ({ value: String(a.id), label: a.nombre }))]}
                            error={formErrors.almacen_id}
                        />
                        <Select
                            label="Tipo documento"
                            value={form.tipo_documento}
                            onChange={(e) => setForm((p) => ({ ...p, tipo_documento: e.target.value }))}
                            options={[{ value: 'factura', label: 'Factura' }, { value: 'guia_remision', label: 'Guía de Remisión' }, { value: 'boleta', label: 'Boleta' }]}
                        />
                        <Input label="N° Documento" value={form.numero_documento} onChange={(e) => setForm((p) => ({ ...p, numero_documento: e.target.value }))} />
                        <Input label="Fecha recepción" type="date" value={form.fecha_recepcion} onChange={(e) => setForm((p) => ({ ...p, fecha_recepcion: e.target.value }))} error={formErrors.fecha_recepcion} />
                    </div>

                    <div>
                        <div className="mb-1 flex items-center justify-between">
                            <span className="text-sm font-medium text-gray-700">Productos recibidos</span>
                            <Button type="button" variant="ghost" size="sm" onClick={addDetalle}>
                                <Plus className="h-4 w-4" />
                                Agregar
                            </Button>
                        </div>
                        <div className="space-y-2">
                            {detalles.map((d, i) => (
                                <div key={i} className="flex items-start gap-2">
                                    <Select
                                        value={d.producto_presentacion_id}
                                        onChange={(e) => setDetalle(i, { producto_presentacion_id: e.target.value })}
                                        options={[{ value: '', label: 'Producto — presentación' }, ...presentacionesOptions]}
                                        className="flex-1"
                                    />
                                    <Input type="number" min="0" step="any" placeholder="Cant." value={d.cantidad_recibida} onChange={(e) => setDetalle(i, { cantidad_recibida: e.target.value })} className="w-20" />
                                    <Input type="number" min="0" step="any" placeholder="Costo" value={d.costo_unitario} onChange={(e) => setDetalle(i, { costo_unitario: e.target.value })} className="w-24" />
                                    <button type="button" onClick={() => removeDetalle(i)} disabled={detalles.length === 1} className="mt-1 rounded-md p-2 text-red-600 hover:bg-red-50 disabled:opacity-40" aria-label="Quitar">
                                        <Trash2 className="h-4 w-4" />
                                    </button>
                                </div>
                            ))}
                        </div>
                        {formErrors.detalles && <p className="mt-1 text-xs text-red-600">{formErrors.detalles}</p>}
                        <div className="mt-2 text-right text-sm font-semibold text-warm-900">Total: {money(total)}</div>
                        <p className="mt-1 text-xs text-gray-500">El costo es por presentación (ej. por caja). Al registrar, el stock ingresa al almacén y se actualiza el costo promedio.</p>
                    </div>

                    <Input label="Observaciones" value={form.observaciones} onChange={(e) => setForm((p) => ({ ...p, observaciones: e.target.value }))} />
                </form>
            </Modal>
        </Layout>
    );
}
