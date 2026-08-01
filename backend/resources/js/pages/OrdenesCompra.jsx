import { useCallback, useEffect, useState } from 'react';
import { ShoppingCart, Plus, Trash2 } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal, Select } from '../components/ui';

const emptyDetalle = { producto_presentacion_id: '', cantidad: '', precio_unitario: '' };

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const estadoInfo = {
    pendiente: { label: 'Pendiente', variant: 'amber' },
    aprobada: { label: 'Aprobada', variant: 'green' },
    enviada: { label: 'Enviada', variant: 'blue' },
    parcial: { label: 'Parcial', variant: 'amber' },
    completada: { label: 'Completada', variant: 'green' },
    anulada: { label: 'Anulada', variant: 'red' },
};

const hoy = () => new Date().toISOString().slice(0, 10);

export default function OrdenesCompra() {
    const toast = useToast();
    const [ordenes, setOrdenes] = useState([]);
    const [proveedores, setProveedores] = useState([]);
    const [productos, setProductos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const [modalOpen, setModalOpen] = useState(false);
    const [form, setForm] = useState({ codigo: '', proveedor_id: '', fecha_emision: hoy(), fecha_entrega_estimada: '', moneda: 'PEN', observaciones: '' });
    const [detalles, setDetalles] = useState([{ ...emptyDetalle }]);
    const [formErrors, setFormErrors] = useState({});
    const [saving, setSaving] = useState(false);

    const [deleteTarget, setDeleteTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const [ordRes, provRes, prodRes] = await Promise.all([
                api.get('/ordenes-compra'),
                api.get('/proveedores'),
                api.get('/productos'),
            ]);
            setOrdenes(asList(ordRes));
            setProveedores(asList(provRes));
            setProductos(asList(prodRes));
        } catch {
            setError('No se pudieron cargar las órdenes de compra.');
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

    const total = detalles.reduce((acc, d) => acc + (Number(d.cantidad) || 0) * (Number(d.precio_unitario) || 0), 0);

    const openCreate = () => {
        setForm({ codigo: '', proveedor_id: '', fecha_emision: hoy(), fecha_entrega_estimada: '', moneda: 'PEN', observaciones: '' });
        setDetalles([{ ...emptyDetalle }]);
        setFormErrors({});
        setModalOpen(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSaving(true);
        setFormErrors({});
        const lineas = detalles.filter((d) => d.producto_presentacion_id && Number(d.cantidad) > 0);
        if (lineas.length === 0) {
            setFormErrors({ detalles: 'Agrega al menos un producto.' });
            setSaving(false);
            return;
        }
        try {
            await api.post('/ordenes-compra', {
                ...form,
                fecha_entrega_estimada: form.fecha_entrega_estimada || null,
                detalles: lineas.map((d) => ({
                    producto_presentacion_id: d.producto_presentacion_id,
                    cantidad: d.cantidad,
                    precio_unitario: d.precio_unitario || 0,
                })),
            });
            toast.success('Orden de compra creada correctamente.');
            setModalOpen(false);
            await load();
        } catch (err) {
            if (err.response?.status === 422) {
                setFormErrors(Object.fromEntries(Object.entries(err.response.data?.errors ?? {}).map(([k, v]) => [k, v[0]])));
            } else {
                toast.error('No se pudo guardar la orden.');
            }
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async () => {
        setDeleting(true);
        try {
            await api.delete(`/ordenes-compra/${deleteTarget.id}`);
            toast.success('Orden eliminada.');
            setDeleteTarget(null);
            await load();
        } catch {
            toast.error('No se pudo eliminar la orden.');
        } finally {
            setDeleting(false);
        }
    };

    const columns = [
        { key: 'codigo', label: 'Código', render: (row) => <Badge variant="gray">{row.codigo}</Badge> },
        {
            key: 'proveedor',
            label: 'Proveedor',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <ShoppingCart className="h-4 w-4 text-primary-600" />
                    {row.proveedor?.nombre ?? '—'}
                </span>
            ),
        },
        { key: 'fecha_emision', label: 'Emisión', render: (row) => (row.fecha_emision ? new Date(row.fecha_emision).toLocaleDateString('es-PE') : '—') },
        { key: 'detalles_count', label: 'Ítems', render: (row) => <Badge variant="blue">{row.detalles_count ?? 0}</Badge> },
        {
            key: 'estado',
            label: 'Estado',
            render: (row) => {
                const info = estadoInfo[row.estado] ?? { label: row.estado ?? '—', variant: 'gray' };
                return <Badge variant={info.variant}>{info.label}</Badge>;
            },
        },
        {
            type: 'actions',
            key: 'actions',
            label: 'Acciones',
            actions: (row) => (
                <button
                    aria-label="Eliminar"
                    onClick={() => setDeleteTarget(row)}
                    className="rounded-md p-1.5 text-red-600 transition hover:bg-red-50 hover:text-red-700"
                >
                    <Trash2 className="h-4 w-4" />
                </button>
            ),
        },
    ];

    return (
        <Layout>
            <PageHeader
                title="Órdenes de Compra"
                description="Pedidos formales de compra a proveedores"
                actions={<CreateButton onClick={openCreate}>Nueva orden</CreateButton>}
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable columns={columns} rows={ordenes} loading={loading} searchPlaceholder="Buscar órdenes..." />

            <Modal
                open={modalOpen}
                onClose={() => setModalOpen(false)}
                title="Nueva orden de compra"
                size="lg"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancelar</Button>
                        <Button type="submit" form="orden-form" loading={saving}>Crear orden</Button>
                    </>
                }
            >
                <form id="orden-form" onSubmit={handleSubmit} className="space-y-4" noValidate>
                    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                        <Input label="Código" placeholder="Ej: OC-001" value={form.codigo} onChange={(e) => setForm((p) => ({ ...p, codigo: e.target.value }))} error={formErrors.codigo} />
                        <Select
                            label="Proveedor"
                            value={form.proveedor_id}
                            onChange={(e) => setForm((p) => ({ ...p, proveedor_id: e.target.value }))}
                            options={[{ value: '', label: 'Selecciona…' }, ...proveedores.map((p) => ({ value: String(p.id), label: p.nombre }))]}
                            error={formErrors.proveedor_id}
                        />
                        <Input label="Fecha emisión" type="date" value={form.fecha_emision} onChange={(e) => setForm((p) => ({ ...p, fecha_emision: e.target.value }))} error={formErrors.fecha_emision} />
                        <Input label="Entrega estimada" type="date" value={form.fecha_entrega_estimada} onChange={(e) => setForm((p) => ({ ...p, fecha_entrega_estimada: e.target.value }))} />
                    </div>

                    <div>
                        <div className="mb-1 flex items-center justify-between">
                            <span className="text-sm font-medium text-gray-700">Productos</span>
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
                                    <Input type="number" min="0" step="any" placeholder="Cant." value={d.cantidad} onChange={(e) => setDetalle(i, { cantidad: e.target.value })} className="w-20" />
                                    <Input type="number" min="0" step="any" placeholder="Precio" value={d.precio_unitario} onChange={(e) => setDetalle(i, { precio_unitario: e.target.value })} className="w-24" />
                                    <button type="button" onClick={() => removeDetalle(i)} disabled={detalles.length === 1} className="mt-1 rounded-md p-2 text-red-600 hover:bg-red-50 disabled:opacity-40" aria-label="Quitar">
                                        <Trash2 className="h-4 w-4" />
                                    </button>
                                </div>
                            ))}
                        </div>
                        {formErrors.detalles && <p className="mt-1 text-xs text-red-600">{formErrors.detalles}</p>}
                        <div className="mt-2 text-right text-sm font-semibold text-warm-900">
                            Total estimado: {money(total)}
                        </div>
                    </div>

                    <Input label="Observaciones" value={form.observaciones} onChange={(e) => setForm((p) => ({ ...p, observaciones: e.target.value }))} />
                </form>
            </Modal>

            <Modal
                open={Boolean(deleteTarget)}
                onClose={() => setDeleteTarget(null)}
                title="Eliminar orden"
                description={`¿Eliminar la orden ${deleteTarget?.codigo}?`}
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setDeleteTarget(null)}>Cancelar</Button>
                        <Button variant="danger" loading={deleting} onClick={handleDelete}>Eliminar</Button>
                    </>
                }
            >
                <Alert variant="warning">La orden se eliminará permanentemente.</Alert>
            </Modal>
        </Layout>
    );
}
