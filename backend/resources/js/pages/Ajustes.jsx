import { useCallback, useEffect, useState } from 'react';
import { ArrowDownLeft, ArrowUpRight, Edit, Scale, Trash2 } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal, Select } from '../components/ui';

const emptyForm = { almacen_id: '', tipo: 'entrada', motivo: '', observaciones: '' };

const estadoInfo = {
    pendiente: { label: 'Pendiente', variant: 'amber' },
    aprobado: { label: 'Aprobado', variant: 'green' },
    rechazado: { label: 'Rechazado', variant: 'red' },
};

export default function Ajustes() {
    const toast = useToast();
    const [ajustes, setAjustes] = useState([]);
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
    const [filterTipo, setFilterTipo] = useState('');
    const [activeFilters, setActiveFilters] = useState({});

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const [ajustesRes, almRes] = await Promise.all([
                api.get('/ajustes'),
                api.get('/almacenes'),
            ]);
            setAjustes(asList(ajustesRes));
            setAlmacenes(asList(almRes));
        } catch {
            setError('No se pudieron cargar los ajustes.');
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

    const openEdit = (ajuste) => {
        setEditing(ajuste);
        setForm({
            almacen_id: String(ajuste.almacen_id ?? ajuste.almacen?.id ?? ''),
            tipo: ajuste.tipo ?? 'entrada',
            motivo: ajuste.motivo ?? '',
            estado: ajuste.estado ?? 'pendiente',
            observaciones: ajuste.observaciones ?? '',
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
                await api.put(`/ajustes/${editing.id}`, {
                    estado: form.estado,
                    observaciones: form.observaciones,
                });
                toast.success('Ajuste actualizado correctamente.');
            } else {
                await api.post('/ajustes', {
                    almacen_id: form.almacen_id,
                    tipo: form.tipo,
                    motivo: form.motivo,
                    observaciones: form.observaciones,
                });
                toast.success('Ajuste creado correctamente.');
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
                toast.error('No se pudo guardar el ajuste.');
            }
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async () => {
        setDeleting(true);
        try {
            await api.delete(`/ajustes/${deleteTarget.id}`);
            toast.success('Ajuste eliminado.');
            setDeleteTarget(null);
            await load();
        } catch {
            toast.error('No se pudo eliminar el ajuste.');
        } finally {
            setDeleting(false);
        }
    };

    const applyFilters = () => {
        const next = {};
        if (filterEstado) next.estado = filterEstado;
        if (filterTipo) next.tipo = filterTipo;
        setActiveFilters(next);
    };

    const clearFilters = () => {
        setFilterEstado('');
        setFilterTipo('');
        setActiveFilters({});
    };

    const filtered = ajustes.filter((a) => {
        if (activeFilters.estado && a.estado !== activeFilters.estado) return false;
        if (activeFilters.tipo && a.tipo !== activeFilters.tipo) return false;
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
                    { value: 'aprobado', label: 'Aprobado' },
                    { value: 'rechazado', label: 'Rechazado' },
                ]}
                className="w-40"
            />
            <Select
                label="Tipo"
                value={filterTipo}
                onChange={(e) => setFilterTipo(e.target.value)}
                options={[
                    { value: '', label: 'Todos' },
                    { value: 'entrada', label: 'Entrada' },
                    { value: 'salida', label: 'Salida' },
                ]}
                className="w-40"
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
            key: 'almacen',
            label: 'Almacén',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <Scale className="h-4 w-4 text-primary-600" />
                    {row.almacen?.nombre ?? '—'}
                </span>
            ),
        },
        {
            key: 'tipo',
            label: 'Tipo',
            render: (row) =>
                row.tipo === 'entrada' ? (
                    <Badge variant="green">
                        <ArrowDownLeft className="mr-1 h-3 w-3" /> Entrada
                    </Badge>
                ) : (
                    <Badge variant="red">
                        <ArrowUpRight className="mr-1 h-3 w-3" /> Salida
                    </Badge>
                ),
        },
        {
            key: 'motivo',
            label: 'Motivo',
            render: (row) => row.motivo ?? <span className="text-gray-400">—</span>,
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
            key: 'fecha',
            label: 'Fecha',
            render: (row) =>
                row.fecha ? (
                    <span className="text-gray-700">{new Date(row.fecha).toLocaleDateString('es-PE')}</span>
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
                title="Ajustes"
                description="Corrige diferencias de stock con entradas o salidas manuales"
                actions={<CreateButton onClick={openCreate}>Nuevo ajuste</CreateButton>}
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable
                columns={columns}
                rows={filtered}
                loading={loading}
                searchPlaceholder="Buscar ajustes..."
                filterable
                filters={filters}
                filterCount={filterCount}
            />

            {/* Modal crear/editar */}
            <Modal
                open={modalOpen}
                onClose={() => setModalOpen(false)}
                title={editing ? 'Editar ajuste' : 'Nuevo ajuste'}
                description={editing ? `Actualiza el estado del ajuste #${editing.id}` : 'Registra un ajuste de inventario'}
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>
                            Cancelar
                        </Button>
                        <Button type="submit" form="ajuste-form" loading={saving}>
                            {editing ? 'Guardar cambios' : 'Crear ajuste'}
                        </Button>
                    </>
                }
            >
                <form id="ajuste-form" onSubmit={handleSubmit} className="space-y-4" noValidate>
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
                                label="Almacén"
                                name="almacen_id"
                                value={form.almacen_id}
                                onChange={(e) =>
                                    setForm((prev) => ({ ...prev, almacen_id: e.target.value }))
                                }
                                options={almacenes.map((a) => ({
                                    value: String(a.id),
                                    label: a.nombre,
                                }))}
                                error={formErrors.almacen_id}
                            />
                            <Select
                                label="Tipo"
                                name="tipo"
                                value={form.tipo}
                                onChange={(e) => setForm((prev) => ({ ...prev, tipo: e.target.value }))}
                                options={[
                                    { value: 'entrada', label: 'Entrada' },
                                    { value: 'salida', label: 'Salida' },
                                ]}
                                error={formErrors.tipo}
                            />
                            <Input
                                label="Motivo"
                                name="motivo"
                                placeholder="Ej: Merma, sobrante, error de registro"
                                value={form.motivo}
                                onChange={(e) => {
                                    setForm((prev) => ({ ...prev, motivo: e.target.value }));
                                    if (formErrors.motivo) {
                                        setFormErrors((prev) => ({ ...prev, motivo: undefined }));
                                    }
                                }}
                                error={formErrors.motivo}
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
                title="Eliminar ajuste"
                description={`¿Seguro que deseas eliminar el ajuste #${deleteTarget?.id}?`}
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
                    El ajuste se eliminará de forma permanente.
                </Alert>
            </Modal>
        </Layout>
    );
}
