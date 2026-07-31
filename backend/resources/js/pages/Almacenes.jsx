import { useCallback, useEffect, useState } from 'react';
import { BadgeCheck, Edit, MapPin, Tag, Trash2, Warehouse } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal, Select } from '../components/ui';

const emptyForm = { nombre: '', codigo: '', tipo: 'principal', direccion: '', activo: true };

export default function Almacenes() {
    const toast = useToast();
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
    const [activeFilters, setActiveFilters] = useState({});

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            setAlmacenes(asList(await api.get('/almacenes')));
        } catch {
            setError('No se pudieron cargar los almacenes.');
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

    const openEdit = (almacen) => {
        setEditing(almacen);
        setForm({
            nombre: almacen.nombre,
            codigo: almacen.codigo,
            tipo: almacen.tipo ?? 'principal',
            direccion: almacen.direccion ?? '',
            activo: Boolean(almacen.activo),
        });
        setFormErrors({});
        setModalOpen(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSaving(true);
        setFormErrors({});

        const payload = { ...form };

        try {
            if (editing) {
                await api.put(`/almacenes/${editing.id}`, payload);
                toast.success('Almacén actualizado correctamente.');
            } else {
                await api.post('/almacenes', payload);
                toast.success('Almacén creado correctamente.');
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
                toast.error('No se pudo guardar el almacén.');
            }
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async () => {
        setDeleting(true);
        try {
            await api.delete(`/almacenes/${deleteTarget.id}`);
            toast.success('Almacén eliminado.');
            setDeleteTarget(null);
            await load();
        } catch {
            toast.error('No se pudo eliminar el almacén.');
        } finally {
            setDeleting(false);
        }
    };

    const applyFilters = () => {
        const next = {};
        if (filterEstado) next.estado = filterEstado;
        setActiveFilters(next);
    };

    const clearFilters = () => {
        setFilterEstado('');
        setActiveFilters({});
    };

    const filtered = almacenes.filter((a) => {
        if (activeFilters.estado === 'activos') return a.activo !== false;
        if (activeFilters.estado === 'inactivos') return a.activo === false;
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
                    { value: 'activos', label: 'Solo activos' },
                    { value: 'inactivos', label: 'Solo inactivos' },
                ]}
                className="w-44"
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
            render: (row) => <Badge variant="blue">{String(row.id).padStart(2, '0')}</Badge>,
        },
        {
            key: 'nombre',
            label: 'Almacén',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <Warehouse className="h-4 w-4 text-primary-600" />
                    {row.nombre}
                </span>
            ),
        },
        {
            key: 'codigo',
            label: 'Código',
            render: (row) => (
                <span className="inline-flex items-center gap-1.5 text-gray-700">
                    <Tag className="h-3.5 w-3.5 text-gray-400" />
                    {row.codigo}
                </span>
            ),
        },
        {
            key: 'tipo',
            label: 'Tipo',
            render: (row) => (
                <Badge variant={row.tipo === 'principal' ? 'green' : 'gray'}>
                    {row.tipo ?? '—'}
                </Badge>
            ),
        },
        {
            key: 'direccion',
            label: 'Dirección',
            render: (row) =>
                row.direccion ? (
                    <span className="inline-flex items-center gap-1.5 text-gray-700">
                        <MapPin className="h-3.5 w-3.5 text-gray-400" />
                        {row.direccion}
                    </span>
                ) : (
                    <span className="text-gray-400">—</span>
                ),
        },
        {
            key: 'activo',
            label: 'Estado',
            render: (row) =>
                row.activo ? (
                    <Badge variant="green">Activo</Badge>
                ) : (
                    <Badge variant="red">Inactivo</Badge>
                ),
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
                title="Almacenes"
                description="Administra los almacenes o puntos de venta de tu negocio"
                actions={<CreateButton onClick={openCreate}>Crear almacén</CreateButton>}
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable
                columns={columns}
                rows={filtered}
                loading={loading}
                searchPlaceholder="Buscar almacenes..."
                filterable
                filters={filters}
                filterCount={filterCount}
            />

            {/* Modal crear/editar */}
            <Modal
                open={modalOpen}
                onClose={() => setModalOpen(false)}
                title={editing ? 'Editar almacén' : 'Crear almacén'}
                description={
                    editing ? `Modifica "${editing.nombre}"` : 'Agrega un nuevo almacén'
                }
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>
                            Cancelar
                        </Button>
                        <Button type="submit" form="almacen-form" loading={saving}>
                            {editing ? 'Guardar cambios' : 'Crear almacén'}
                        </Button>
                    </>
                }
            >
                <form id="almacen-form" onSubmit={handleSubmit} className="space-y-4" noValidate>
                    <Input
                        label="Nombre"
                        name="nombre"
                        placeholder="Ej: Almacén Central"
                        value={form.nombre}
                        onChange={(e) => {
                            setForm((prev) => ({ ...prev, nombre: e.target.value }));
                            if (formErrors.nombre) {
                                setFormErrors((prev) => ({ ...prev, nombre: undefined }));
                            }
                        }}
                        error={formErrors.nombre}
                    />
                    <Input
                        label="Código"
                        name="codigo"
                        placeholder="Ej: ALM-001"
                        value={form.codigo}
                        onChange={(e) => {
                            setForm((prev) => ({ ...prev, codigo: e.target.value }));
                            if (formErrors.codigo) {
                                setFormErrors((prev) => ({ ...prev, codigo: undefined }));
                            }
                        }}
                        error={formErrors.codigo}
                    />
                    <Select
                        label="Tipo"
                        name="tipo"
                        value={form.tipo}
                        onChange={(e) => setForm((prev) => ({ ...prev, tipo: e.target.value }))}
                        options={[
                            { value: 'principal', label: 'Principal' },
                            { value: 'secundario', label: 'Secundario' },
                            { value: 'tienda', label: 'Tienda' },
                        ]}
                    />
                    <Input
                        label="Dirección"
                        name="direccion"
                        placeholder="Opcional"
                        value={form.direccion}
                        onChange={(e) => setForm((prev) => ({ ...prev, direccion: e.target.value }))}
                        error={formErrors.direccion}
                    />
                    <label className="flex items-center gap-2 text-sm text-gray-700">
                        <input
                            type="checkbox"
                            checked={form.activo}
                            onChange={(e) =>
                                setForm((prev) => ({ ...prev, activo: e.target.checked }))
                            }
                            className="h-4 w-4 rounded border-gray-300 accent-primary-600"
                        />
                        <BadgeCheck className="h-4 w-4 text-primary-600" />
                        Almacén activo
                    </label>
                </form>
            </Modal>

            {/* Modal eliminar */}
            <Modal
                open={Boolean(deleteTarget)}
                onClose={() => setDeleteTarget(null)}
                title="Eliminar almacén"
                description={`¿Seguro que deseas eliminar "${deleteTarget?.nombre}"?`}
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
                    El stock y los movimientos asociados a este almacén podrían verse afectados.
                </Alert>
            </Modal>
        </Layout>
    );
}
