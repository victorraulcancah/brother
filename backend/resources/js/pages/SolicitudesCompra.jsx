import { useCallback, useEffect, useState } from 'react';
import { FileText, Plus, Trash2 } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal, Select } from '../components/ui';

const emptyDetalle = { producto_presentacion_id: '', cantidad_solicitada: '' };

const estadoInfo = {
    pendiente: { label: 'Pendiente', variant: 'amber' },
    aprobada: { label: 'Aprobada', variant: 'green' },
    rechazada: { label: 'Rechazada', variant: 'red' },
    completada: { label: 'Completada', variant: 'blue' },
};

export default function SolicitudesCompra() {
    const toast = useToast();
    const [solicitudes, setSolicitudes] = useState([]);
    const [productos, setProductos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const [modalOpen, setModalOpen] = useState(false);
    const [form, setForm] = useState({ codigo: '', observaciones: '' });
    const [detalles, setDetalles] = useState([{ ...emptyDetalle }]);
    const [formErrors, setFormErrors] = useState({});
    const [saving, setSaving] = useState(false);

    const [deleteTarget, setDeleteTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const [solRes, prodRes] = await Promise.all([
                api.get('/solicitudes-compra'),
                api.get('/productos'),
            ]);
            setSolicitudes(asList(solRes));
            setProductos(asList(prodRes));
        } catch {
            setError('No se pudieron cargar las solicitudes.');
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

    const openCreate = () => {
        setForm({ codigo: '', observaciones: '' });
        setDetalles([{ ...emptyDetalle }]);
        setFormErrors({});
        setModalOpen(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSaving(true);
        setFormErrors({});
        const lineas = detalles.filter((d) => d.producto_presentacion_id && Number(d.cantidad_solicitada) > 0);
        if (lineas.length === 0) {
            setFormErrors({ detalles: 'Agrega al menos un producto.' });
            setSaving(false);
            return;
        }
        try {
            await api.post('/solicitudes-compra', {
                codigo: form.codigo,
                observaciones: form.observaciones,
                detalles: lineas.map((d) => ({
                    producto_presentacion_id: d.producto_presentacion_id,
                    cantidad_solicitada: d.cantidad_solicitada,
                })),
            });
            toast.success('Solicitud creada correctamente.');
            setModalOpen(false);
            await load();
        } catch (err) {
            if (err.response?.status === 422) {
                setFormErrors(Object.fromEntries(Object.entries(err.response.data?.errors ?? {}).map(([k, v]) => [k, v[0]])));
            } else {
                toast.error('No se pudo guardar la solicitud.');
            }
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async () => {
        setDeleting(true);
        try {
            await api.delete(`/solicitudes-compra/${deleteTarget.id}`);
            toast.success('Solicitud eliminada.');
            setDeleteTarget(null);
            await load();
        } catch {
            toast.error('No se pudo eliminar la solicitud.');
        } finally {
            setDeleting(false);
        }
    };

    const columns = [
        { key: 'codigo', label: 'Código', render: (row) => <Badge variant="gray">{row.codigo}</Badge> },
        {
            key: 'fecha_solicitud',
            label: 'Fecha',
            render: (row) => (row.fecha_solicitud ? new Date(row.fecha_solicitud).toLocaleDateString('es-PE') : '—'),
        },
        { key: 'detalles_count', label: 'Ítems', render: (row) => <Badge variant="blue">{row.detalles_count ?? 0}</Badge> },
        {
            key: 'estado',
            label: 'Estado',
            render: (row) => {
                const info = estadoInfo[row.estado] ?? { label: row.estado ?? '—', variant: 'gray' };
                return <Badge variant={info.variant}>{info.label}</Badge>;
            },
        },
        { key: 'observaciones', label: 'Observaciones', render: (row) => row.observaciones ?? <span className="text-gray-400">—</span> },
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
                title="Solicitudes de Compra"
                description="Pedidos internos de productos para comprar"
                actions={<CreateButton onClick={openCreate}>Nueva solicitud</CreateButton>}
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable columns={columns} rows={solicitudes} loading={loading} searchPlaceholder="Buscar solicitudes..." />

            <Modal
                open={modalOpen}
                onClose={() => setModalOpen(false)}
                title="Nueva solicitud de compra"
                size="lg"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancelar</Button>
                        <Button type="submit" form="solicitud-form" loading={saving}>Crear solicitud</Button>
                    </>
                }
            >
                <form id="solicitud-form" onSubmit={handleSubmit} className="space-y-4" noValidate>
                    <Input
                        label="Código"
                        placeholder="Ej: SOL-001"
                        value={form.codigo}
                        onChange={(e) => setForm((p) => ({ ...p, codigo: e.target.value }))}
                        error={formErrors.codigo}
                    />
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
                                    <Input
                                        type="number"
                                        min="0"
                                        step="any"
                                        placeholder="Cant."
                                        value={d.cantidad_solicitada}
                                        onChange={(e) => setDetalle(i, { cantidad_solicitada: e.target.value })}
                                        className="w-24"
                                    />
                                    <button type="button" onClick={() => removeDetalle(i)} disabled={detalles.length === 1}
                                        className="mt-1 rounded-md p-2 text-red-600 hover:bg-red-50 disabled:opacity-40" aria-label="Quitar">
                                        <Trash2 className="h-4 w-4" />
                                    </button>
                                </div>
                            ))}
                        </div>
                        {formErrors.detalles && <p className="mt-1 text-xs text-red-600">{formErrors.detalles}</p>}
                    </div>
                    <Input
                        label="Observaciones"
                        value={form.observaciones}
                        onChange={(e) => setForm((p) => ({ ...p, observaciones: e.target.value }))}
                    />
                </form>
            </Modal>

            <Modal
                open={Boolean(deleteTarget)}
                onClose={() => setDeleteTarget(null)}
                title="Eliminar solicitud"
                description={`¿Eliminar la solicitud ${deleteTarget?.codigo}?`}
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setDeleteTarget(null)}>Cancelar</Button>
                        <Button variant="danger" loading={deleting} onClick={handleDelete}>Eliminar</Button>
                    </>
                }
            >
                <Alert variant="warning">La solicitud se eliminará permanentemente.</Alert>
            </Modal>
        </Layout>
    );
}
