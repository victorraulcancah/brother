import { useCallback, useEffect, useState } from 'react';
import {
    ArrowDownLeft,
    ArrowUpRight,
    BadgeCheck,
    Edit,
    Lock,
    Plus,
    Scale,
    Trash2,
} from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal, Select, Tabs } from '../components/ui';

const emptyForm = { almacen_id: '', tipo: 'entrada', motivo: '', observaciones: '' };
const emptyMotivoForm = { nombre: '', tipo: 'entrada', activo: true };
const emptyDetalle = { producto_presentacion_id: '', cantidad: '' };

const estadoInfo = {
    pendiente: { label: 'Pendiente', variant: 'amber' },
    aprobado: { label: 'Aprobado', variant: 'green' },
    rechazado: { label: 'Rechazado', variant: 'red' },
};

const tipoInfo = {
    entrada: { label: 'Entrada', variant: 'green', icon: ArrowDownLeft },
    salida: { label: 'Salida', variant: 'red', icon: ArrowUpRight },
};

export default function Ajustes() {
    const toast = useToast();
    const [ajustes, setAjustes] = useState([]);
    const [almacenes, setAlmacenes] = useState([]);
    const [productos, setProductos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState(null);
    const [form, setForm] = useState(emptyForm);
    const [detalles, setDetalles] = useState([{ ...emptyDetalle }]);
    const [formErrors, setFormErrors] = useState({});
    const [saving, setSaving] = useState(false);

    const [deleteTarget, setDeleteTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);

    const [filterEstado, setFilterEstado] = useState('');
    const [filterTipo, setFilterTipo] = useState('');
    const [activeFilters, setActiveFilters] = useState({});

    const [activeTab, setActiveTab] = useState('ajustes');

    const [motivos, setMotivos] = useState([]);
    const [motivosLoading, setMotivosLoading] = useState(false);
    const [motivosError, setMotivosError] = useState(null);
    const [motivoModalOpen, setMotivoModalOpen] = useState(false);
    const [editingMotivo, setEditingMotivo] = useState(null);
    const [motivoForm, setMotivoForm] = useState(emptyMotivoForm);
    const [motivoFormErrors, setMotivoFormErrors] = useState({});
    const [motivoSaving, setMotivoSaving] = useState(false);
    const [motivoDeleteTarget, setMotivoDeleteTarget] = useState(null);
    const [motivoDeleting, setMotivoDeleting] = useState(false);
    const [motivoFilterTipo, setMotivoFilterTipo] = useState('');
    const [motivoFilterEstado, setMotivoFilterEstado] = useState('');
    const [motivoActiveFilters, setMotivoActiveFilters] = useState({});

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const [ajustesRes, almRes, prodRes] = await Promise.all([
                api.get('/ajustes'),
                api.get('/almacenes'),
                api.get('/productos'),
            ]);
            setAjustes(asList(ajustesRes));
            setAlmacenes(asList(almRes));
            setProductos(asList(prodRes));
        } catch {
            setError('No se pudieron cargar los ajustes.');
        } finally {
            setLoading(false);
        }
    }, []);

    const loadMotivos = useCallback(async () => {
        setMotivosLoading(true);
        setMotivosError(null);
        try {
            setMotivos(asList(await api.get('/motivos-movimiento')));
        } catch {
            setMotivosError('No se pudieron cargar los motivos.');
        } finally {
            setMotivosLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    useEffect(() => {
        if (activeTab === 'motivos') {
            loadMotivos();
        }
    }, [activeTab, loadMotivos]);

    const presentacionesOptions = productos.flatMap((p) =>
        (Array.isArray(p.presentaciones) ? p.presentaciones : []).map((pres) => ({
            value: String(pres.id),
            label: `${p.nombre} — ${pres.nombre}`,
        })),
    );

    const setDetalle = (index, patch) => {
        setDetalles((prev) => prev.map((d, i) => (i === index ? { ...d, ...patch } : d)));
    };
    const addDetalle = () => setDetalles((prev) => [...prev, { ...emptyDetalle }]);
    const removeDetalle = (index) =>
        setDetalles((prev) => (prev.length === 1 ? prev : prev.filter((_, i) => i !== index)));

    const openCreate = () => {
        setEditing(null);
        setForm(emptyForm);
        setDetalles([{ ...emptyDetalle }]);
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
                const lineas = detalles.filter((d) => d.producto_presentacion_id && Number(d.cantidad) > 0);
                if (lineas.length === 0) {
                    setFormErrors((prev) => ({ ...prev, detalles: 'Agrega al menos un producto con cantidad.' }));
                    setSaving(false);
                    return;
                }
                await api.post('/ajustes', {
                    almacen_id: form.almacen_id,
                    tipo: form.tipo,
                    motivo: form.motivo,
                    observaciones: form.observaciones,
                    detalles: lineas.map((d) => ({
                        producto_presentacion_id: d.producto_presentacion_id,
                        cantidad: d.cantidad,
                    })),
                });
                toast.success('Ajuste creado y stock actualizado.');
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

    const openMotivoCreate = () => {
        setEditingMotivo(null);
        setMotivoForm(emptyMotivoForm);
        setMotivoFormErrors({});
        setMotivoModalOpen(true);
    };

    const openMotivoEdit = (motivo) => {
        setEditingMotivo(motivo);
        setMotivoForm({
            nombre: motivo.nombre ?? '',
            tipo: motivo.tipo ?? 'entrada',
            activo: motivo.activo ?? true,
        });
        setMotivoFormErrors({});
        setMotivoModalOpen(true);
    };

    const handleMotivoSubmit = async (e) => {
        e.preventDefault();
        setMotivoSaving(true);
        setMotivoFormErrors({});

        try {
            const payload = {
                nombre: motivoForm.nombre,
                tipo: motivoForm.tipo,
                activo: motivoForm.activo,
            };
            if (editingMotivo) {
                await api.put(`/motivos-movimiento/${editingMotivo.id}`, payload);
                toast.success('Motivo actualizado correctamente.');
            } else {
                await api.post('/motivos-movimiento', payload);
                toast.success('Motivo creado correctamente.');
            }
            setMotivoModalOpen(false);
            await loadMotivos();
        } catch (err) {
            if (err.response?.status === 422 && err.response.data?.errors) {
                const validation = err.response.data.errors;
                setMotivoFormErrors(
                    Object.fromEntries(Object.entries(validation).map(([k, v]) => [k, v[0]])),
                );
            } else {
                toast.error(err.response?.data?.message ?? 'No se pudo guardar el motivo.');
            }
        } finally {
            setMotivoSaving(false);
        }
    };

    const handleMotivoDelete = async () => {
        setMotivoDeleting(true);
        try {
            await api.delete(`/motivos-movimiento/${motivoDeleteTarget.id}`);
            toast.success('Motivo eliminado.');
            setMotivoDeleteTarget(null);
            await loadMotivos();
        } catch (err) {
            toast.error(err.response?.data?.message ?? 'No se pudo eliminar el motivo.');
        } finally {
            setMotivoDeleting(false);
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

    const applyMotivoFilters = () => {
        const next = {};
        if (motivoFilterTipo) next.tipo = motivoFilterTipo;
        if (motivoFilterEstado) next.activo = motivoFilterEstado;
        setMotivoActiveFilters(next);
    };

    const clearMotivoFilters = () => {
        setMotivoFilterTipo('');
        setMotivoFilterEstado('');
        setMotivoActiveFilters({});
    };

    const filteredMotivos = motivos.filter((m) => {
        if (motivoActiveFilters.tipo && m.tipo !== motivoActiveFilters.tipo) return false;
        if (motivoActiveFilters.activo === '1' && !m.activo) return false;
        if (motivoActiveFilters.activo === '0' && m.activo) return false;
        return true;
    });

    const filterCount = Object.keys(activeFilters).length;
    const motivoFilterCount = Object.keys(motivoActiveFilters).length;

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

    const motivoFilters = (
        <div className="flex flex-wrap items-end gap-3">
            <Select
                label="Tipo"
                value={motivoFilterTipo}
                onChange={(e) => setMotivoFilterTipo(e.target.value)}
                options={[
                    { value: '', label: 'Todos' },
                    { value: 'entrada', label: 'Entrada' },
                    { value: 'salida', label: 'Salida' },
                ]}
                className="w-40"
            />
            <Select
                label="Estado"
                value={motivoFilterEstado}
                onChange={(e) => setMotivoFilterEstado(e.target.value)}
                options={[
                    { value: '', label: 'Todos' },
                    { value: '1', label: 'Activos' },
                    { value: '0', label: 'Inactivos' },
                ]}
                className="w-40"
            />
            <Button variant="primary" size="sm" onClick={applyMotivoFilters}>
                Aplicar
            </Button>
            {motivoFilterCount > 0 && (
                <Button variant="ghost" size="sm" onClick={clearMotivoFilters}>
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
            render: (row) => {
                const info = tipoInfo[row.tipo] ?? { label: row.tipo ?? '—', variant: 'gray' };
                const Icon = info.icon;
                return (
                    <Badge variant={info.variant}>
                        {Icon && <Icon className="mr-1 h-3 w-3" />}
                        {info.label}
                    </Badge>
                );
            },
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

    const motivoColumns = [
        {
            key: 'id',
            label: '#',
            render: (row) => <Badge variant="blue">#{String(row.id).padStart(3, '0')}</Badge>,
        },
        {
            key: 'nombre',
            label: 'Motivo',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    {row.es_sistema && <Lock className="h-4 w-4 text-primary-600" />}
                    {row.nombre}
                </span>
            ),
        },
        {
            key: 'tipo',
            label: 'Tipo',
            render: (row) => {
                const info = tipoInfo[row.tipo] ?? { label: row.tipo ?? '—', variant: 'gray' };
                const Icon = info.icon;
                return (
                    <Badge variant={info.variant}>
                        {Icon && <Icon className="mr-1 h-3 w-3" />}
                        {info.label}
                    </Badge>
                );
            },
        },
        {
            key: 'es_sistema',
            label: 'Origen',
            render: (row) =>
                row.es_sistema ? (
                    <Badge variant="blue">
                        <Lock className="mr-1 h-3 w-3" /> Sistema
                    </Badge>
                ) : (
                    <Badge variant="gray">Manual</Badge>
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
            actions: (row) =>
                row.es_sistema ? (
                    <span
                        className="inline-flex items-center gap-1 text-xs text-gray-400"
                        title="Los motivos del sistema no se pueden editar ni eliminar"
                    >
                        <Lock className="h-3.5 w-3.5" /> Fijo
                    </span>
                ) : (
                    <>
                        <button
                            aria-label="Editar"
                            onClick={() => openMotivoEdit(row)}
                            className="rounded-md p-1.5 text-primary-600 transition hover:bg-primary-50 hover:text-primary-700"
                        >
                            <Edit className="h-4 w-4" />
                        </button>
                        <button
                            aria-label="Eliminar"
                            onClick={() => setMotivoDeleteTarget(row)}
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
                description={
                    activeTab === 'ajustes'
                        ? 'Corrige diferencias de stock con entradas o salidas manuales'
                        : 'Administra los motivos de los movimientos de inventario'
                }
                actions={
                    activeTab === 'ajustes' ? (
                        <CreateButton onClick={openCreate}>Nuevo ajuste</CreateButton>
                    ) : (
                        <CreateButton onClick={openMotivoCreate}>Nuevo motivo</CreateButton>
                    )
                }
            />

            <Tabs
                items={[
                    { key: 'ajustes', label: 'Ajustes' },
                    { key: 'motivos', label: 'Motivos' },
                ]}
                value={activeTab}
                onChange={setActiveTab}
                className="mb-4"
            />

            {activeTab === 'ajustes' ? (
                <>
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
                </>
            ) : (
                <>
                    {motivosError && <Alert variant="error" className="mb-4">{motivosError}</Alert>}

                    <DataTable
                        columns={motivoColumns}
                        rows={filteredMotivos}
                        loading={motivosLoading}
                        searchPlaceholder="Buscar motivos..."
                        filterable
                        filters={motivoFilters}
                        filterCount={motivoFilterCount}
                    />
                </>
            )}

            {/* Modal crear/editar ajuste */}
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
                                options={[
                                    { value: '', label: 'Seleccione un almacén' },
                                    ...almacenes.map((a) => ({
                                        value: String(a.id),
                                        label: a.nombre,
                                    })),
                                ]}
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

                            <div>
                                <div className="mb-1 flex items-center justify-between">
                                    <span className="text-sm font-medium text-gray-700">
                                        Productos ({form.tipo === 'salida' ? 'a restar' : 'a sumar'})
                                    </span>
                                    <Button type="button" variant="ghost" size="sm" onClick={addDetalle}>
                                        <Plus className="h-4 w-4" />
                                        Agregar
                                    </Button>
                                </div>
                                <div className="space-y-2">
                                    {detalles.map((d, index) => (
                                        <div key={index} className="flex items-start gap-2">
                                            <Select
                                                value={d.producto_presentacion_id}
                                                onChange={(e) => {
                                                    setDetalle(index, { producto_presentacion_id: e.target.value });
                                                    if (formErrors.detalles) {
                                                        setFormErrors((prev) => ({ ...prev, detalles: undefined }));
                                                    }
                                                }}
                                                options={[
                                                    { value: '', label: 'Producto — presentación' },
                                                    ...presentacionesOptions,
                                                ]}
                                                className="flex-1"
                                            />
                                            <Input
                                                type="number"
                                                min="0"
                                                step="any"
                                                placeholder="Cant."
                                                value={d.cantidad}
                                                onChange={(e) => setDetalle(index, { cantidad: e.target.value })}
                                                className="w-24"
                                            />
                                            <button
                                                type="button"
                                                onClick={() => removeDetalle(index)}
                                                disabled={detalles.length === 1}
                                                aria-label="Quitar"
                                                className="mt-1 rounded-md p-2 text-red-600 transition hover:bg-red-50 disabled:opacity-40"
                                            >
                                                <Trash2 className="h-4 w-4" />
                                            </button>
                                        </div>
                                    ))}
                                </div>
                                {formErrors.detalles && (
                                    <p className="mt-1 text-xs text-red-600">{formErrors.detalles}</p>
                                )}
                            </div>
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

            {/* Modal eliminar ajuste */}
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

            {/* Modal crear/editar motivo */}
            <Modal
                open={motivoModalOpen}
                onClose={() => setMotivoModalOpen(false)}
                title={editingMotivo ? 'Editar motivo' : 'Nuevo motivo'}
                description={
                    editingMotivo
                        ? `Actualiza el motivo #${editingMotivo.id}`
                        : 'Agrega un motivo para los movimientos de inventario'
                }
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setMotivoModalOpen(false)}>
                            Cancelar
                        </Button>
                        <Button type="submit" form="motivo-form" loading={motivoSaving}>
                            {editingMotivo ? 'Guardar cambios' : 'Crear motivo'}
                        </Button>
                    </>
                }
            >
                <form id="motivo-form" onSubmit={handleMotivoSubmit} className="space-y-4" noValidate>
                    <Input
                        label="Nombre"
                        name="nombre"
                        placeholder="Ej: Entrada por compra"
                        value={motivoForm.nombre}
                        onChange={(e) => {
                            setMotivoForm((prev) => ({ ...prev, nombre: e.target.value }));
                            if (motivoFormErrors.nombre) {
                                setMotivoFormErrors((prev) => ({ ...prev, nombre: undefined }));
                            }
                        }}
                        error={motivoFormErrors.nombre}
                    />
                    <Select
                        label="Tipo"
                        name="tipo"
                        value={motivoForm.tipo}
                        onChange={(e) => setMotivoForm((prev) => ({ ...prev, tipo: e.target.value }))}
                        options={[
                            { value: 'entrada', label: 'Entrada' },
                            { value: 'salida', label: 'Salida' },
                        ]}
                        error={motivoFormErrors.tipo}
                    />
                    <label className="flex items-center gap-2 text-sm text-gray-700">
                        <input
                            type="checkbox"
                            checked={motivoForm.activo}
                            onChange={(e) =>
                                setMotivoForm((prev) => ({ ...prev, activo: e.target.checked }))
                            }
                            className="h-4 w-4 rounded border-gray-300 accent-primary-600"
                        />
                        <BadgeCheck className="h-4 w-4 text-primary-600" />
                        Motivo activo
                    </label>
                </form>
            </Modal>

            {/* Modal eliminar motivo */}
            <Modal
                open={Boolean(motivoDeleteTarget)}
                onClose={() => setMotivoDeleteTarget(null)}
                title="Eliminar motivo"
                description={`¿Seguro que deseas eliminar el motivo "${motivoDeleteTarget?.nombre}"?`}
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setMotivoDeleteTarget(null)}>
                            Cancelar
                        </Button>
                        <Button variant="danger" loading={motivoDeleting} onClick={handleMotivoDelete}>
                            Eliminar
                        </Button>
                    </>
                }
            >
                <Alert variant="warning">
                    El motivo se eliminará de forma permanente.
                </Alert>
            </Modal>
        </Layout>
    );
}
