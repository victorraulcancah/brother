import { useCallback, useEffect, useState } from 'react';
import { ArrowRight, Edit, Repeat, Trash2 } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal, Select } from '../components/ui';

const emptyForm = { almacen_origen_id: '', almacen_destino_id: '', observaciones: '' };

const estadoInfo = {
    pendiente: { label: 'Pendiente', variant: 'amber' },
    en_transito: { label: 'En tránsito', variant: 'blue' },
    recibida: { label: 'Recibida', variant: 'green' },
    cancelada: { label: 'Cancelada', variant: 'red' },
};

export default function Transferencias() {
    const toast = useToast();
    const [transferencias, setTransferencias] = useState([]);
    const [almacenes, setAlmacenes] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState(null);
    const [form, setForm] = useState(emptyForm);
    const [formErrors, setFormErrors] = useState({});
    const [saving, setSaving] = useState(false);

    const [deleteTarget, setDeleteTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);

    const [filterEstado, setFilterEstado] = useState('');
    const [filterAlmacen, setFilterAlmacen] = useState('');
    const [activeFilters, setActiveFilters] = useState({});

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const [transRes, almRes] = await Promise.all([
                api.get('/transferencias'),
                api.get('/almacenes'),
            ]);
            setTransferencias(asList(transRes));
            setAlmacenes(asList(almRes));
        } catch {
            setError('No se pudieron cargar las transferencias.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    const openCreate = () => {
        setEditing(null);
        setForm(emptyForm);
        setFormErrors({});
        setModalOpen(true);
    };

    const openEdit = (transferencia) => {
        setEditing(transferencia);
        setForm({
            almacen_origen_id: String(transferencia.almacen_origen_id ?? transferencia.almacen_origen?.id ?? ''),
            almacen_destino_id: String(transferencia.almacen_destino_id ?? transferencia.almacen_destino?.id ?? ''),
            estado: transferencia.estado ?? 'pendiente',
            observaciones: transferencia.observaciones ?? '',
        });
        setFormErrors({});
        setModalOpen(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSaving(true);
        setFormErrors({});

        try {
            if (editing) {
                await api.put(`/transferencias/${editing.id}`, {
                    estado: form.estado,
                    observaciones: form.observaciones,
                });
                toast.success('Transferencia actualizada correctamente.');
            } else {
                await api.post('/transferencias', {
                    almacen_origen_id: form.almacen_origen_id,
                    almacen_destino_id: form.almacen_destino_id,
                    observaciones: form.observaciones,
                });
                toast.success('Transferencia creada correctamente.');
            }
            setModalOpen(false);
            await load();
        } catch (err) {
            if (err.response?.status === 422) {
                const validation = err.response.data?.errors ?? {};
                setFormErrors(
                    Object.fromEntries(Object.entries(validation).map(([k, v]) => [k, v[0]])),
                );
            } else {
                toast.error('No se pudo guardar la transferencia.');
            }
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async () => {
        setDeleting(true);
        try {
            await api.delete(`/transferencias/${deleteTarget.id}`);
            toast.success('Transferencia eliminada.');
            setDeleteTarget(null);
            await load();
        } catch {
            toast.error('No se pudo eliminar la transferencia.');
        } finally {
            setDeleting(false);
        }
    };

    const applyFilters = () => {
        const next = {};
        if (filterEstado) next.estado = filterEstado;
        if (filterAlmacen) next.almacen = filterAlmacen;
        setActiveFilters(next);
    };

    const clearFilters = () => {
        setFilterEstado('');
        setFilterAlmacen('');
        setActiveFilters({});
    };

    const filtered = transferencias.filter((t) => {
        if (activeFilters.estado && t.estado !== activeFilters.estado) return false;
        if (activeFilters.almacen) {
            const origen = t.almacen_origen_id ?? t.almacen_origen?.id;
            const destino = t.almacen_destino_id ?? t.almacen_destino?.id;
            if (String(origen) !== activeFilters.almacen && String(destino) !== activeFilters.almacen) {
                return false;
            }
        }
        return true;
    });

    const filterCount = Object.keys(activeFilters).length;

    const filters = (
        <div className="flex flex-wrap items-end gap-3">
            <Select
                label="Estado"
                value={filterEstado}
                onChange={(e) => setFilterEstado(e.target.value)}
                options={[
                    { value: '', label: 'Todos' },
                    { value: 'pendiente', label: 'Pendiente' },
                    { value: 'en_transito', label: 'En tránsito' },
                    { value: 'recibida', label: 'Recibida' },
                    { value: 'cancelada', label: 'Cancelada' },
                ]}
                className="w-40"
            />
            <Select
                label="Almacén"
                value={filterAlmacen}
                onChange={(e) => setFilterAlmacen(e.target.value)}
                options={[
                    { value: '', label: 'Todos' },
                    ...almacenes.map((a) => ({ value: String(a.id), label: a.nombre })),
                ]}
                className="w-48"
            />
            <Button variant="primary" size="sm" onClick={applyFilters}>
                Aplicar
            </Button>
            {filterCount > 0 && (
                <Button variant="ghost" size="sm" onClick={clearFilters}>
                    Limpiar
                </Button>
            )}
        </div>
    );

    const columns = [
        {
            key: 'id',
            label: '#',
            render: (row) => <Badge variant="blue">#{String(row.id).padStart(3, '0')}</Badge>,
        },
        {
            key: 'ruta',
            label: 'Trayecto',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <Repeat className="h-4 w-4 text-primary-600" />
                    {row.almacen_origen?.nombre ?? '—'}
                    <ArrowRight className="h-4 w-4 text-gray-400" />
                    {row.almacen_destino?.nombre ?? '—'}
                </span>
            ),
        },
        {
            key: 'estado',
            label: 'Estado',
            render: (row) => {
                const info = estadoInfo[row.estado] ?? { label: row.estado ?? '—', variant: 'gray' };
                return <Badge variant={info.variant}>{info.label}</Badge>;
            },
        },
        {
            key: 'fecha_envio',
            label: 'Fecha envío',
            render: (row) =>
                row.fecha_envio ? (
                    <span className="text-gray-700">{new Date(row.fecha_envio).toLocaleDateString('es-PE')}</span>
                ) : (
                    <span className="text-gray-400">—</span>
                ),
        },
        {
            key: 'observaciones',
            label: 'Observaciones',
            render: (row) => row.observaciones ?? <span className="text-gray-400">—</span>,
        },
        {
            type: 'actions',
            key: 'actions',
            label: 'Acciones',
            actions: (row) => (
                <>
                    <button
                        aria-label="Editar"
                        onClick={() => openEdit(row)}
                        className="rounded-md p-1.5 text-primary-600 transition hover:bg-primary-50 hover:text-primary-700"
                    >
                        <Edit className="h-4 w-4" />
                    </button>
                    <button
                        aria-label="Eliminar"
                        onClick={() => setDeleteTarget(row)}
                        className="rounded-md p-1.5 text-red-600 transition hover:bg-red-50 hover:text-red-700"
                    >
                        <Trash2 className="h-4 w-4" />
                    </button>
                </>
            ),
        },
    ];

    return (
        <Layout>
            <PageHeader
                title="Traslados"
                description="Transfiere stock entre almacenes"
                actions={<CreateButton onClick={openCreate}>Nuevo traslado</CreateButton>}
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable
                columns={columns}
                rows={filtered}
                loading={loading}
                searchPlaceholder="Buscar traslados..."
                filterable
                filters={filters}
                filterCount={filterCount}
            />

            {/* Modal crear/editar */}
            <Modal
                open={modalOpen}
                onClose={() => setModalOpen(false)}
                title={editing ? 'Editar traslado' : 'Nuevo traslado'}
                description={editing ? `Actualiza el estado del traslado #${editing.id}` : 'Transfiere stock entre dos almacenes'}
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>
                            Cancelar
                        </Button>
                        <Button type="submit" form="transferencia-form" loading={saving}>
                            {editing ? 'Guardar cambios' : 'Crear traslado'}
                        </Button>
                    </>
                }
            >
                <form id="transferencia-form" onSubmit={handleSubmit} className="space-y-4" noValidate>
                    {editing ? (
                        <Select
                            label="Estado"
                            name="estado"
                            value={form.estado}
                            onChange={(e) => setForm((prev) => ({ ...prev, estado: e.target.value }))}
                            options={Object.entries(estadoInfo).map(([value, info]) => ({
                                value,
                                label: info.label,
                            }))}
                            error={formErrors.estado}
                        />
                    ) : (
                        <>
                            <Select
                                label="Almacén origen"
                                name="almacen_origen_id"
                                value={form.almacen_origen_id}
                                onChange={(e) =>
                                    setForm((prev) => ({ ...prev, almacen_origen_id: e.target.value }))
                                }
                                options={[
                                    { value: '', label: 'Seleccione un almacén' },
                                    ...almacenes.map((a) => ({
                                        value: String(a.id),
                                        label: a.nombre,
                                    })),
                                ]}
                                error={formErrors.almacen_origen_id}
                            />
                            <Select
                                label="Almacén destino"
                                name="almacen_destino_id"
                                value={form.almacen_destino_id}
                                onChange={(e) =>
                                    setForm((prev) => ({ ...prev, almacen_destino_id: e.target.value }))
                                }
                                options={[
                                    { value: '', label: 'Seleccione un almacén' },
                                    ...almacenes.map((a) => ({
                                        value: String(a.id),
                                        label: a.nombre,
                                    })),
                                ]}
                                error={formErrors.almacen_destino_id}
                            />
                        </>
                    )}
                    <Input
                        label="Observaciones"
                        name="observaciones"
                        placeholder="Opcional"
                        value={form.observaciones}
                        onChange={(e) => setForm((prev) => ({ ...prev, observaciones: e.target.value }))}
                    />
                </form>
            </Modal>

            {/* Modal eliminar */}
            <Modal
                open={Boolean(deleteTarget)}
                onClose={() => setDeleteTarget(null)}
                title="Eliminar traslado"
                description={`¿Seguro que deseas eliminar el traslado #${deleteTarget?.id}?`}
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setDeleteTarget(null)}>
                            Cancelar
                        </Button>
                        <Button variant="danger" loading={deleting} onClick={handleDelete}>
                            Eliminar
                        </Button>
                    </>
                }
            >
                <Alert variant="warning">
                    El traslado se eliminará de forma permanente.
                </Alert>
            </Modal>
        </Layout>
    );
}
