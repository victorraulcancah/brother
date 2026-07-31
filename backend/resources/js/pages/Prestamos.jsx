import { useCallback, useEffect, useState } from 'react';
import {
    ArrowLeftRight,
    Edit,
    HandCoins,
    Handshake,
    Plus,
    Trash2,
    Undo2,
    X,
} from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal, Select, Tabs } from '../components/ui';

const estadoInfo = {
    pendiente: { label: 'Pendiente', variant: 'amber' },
    prestado: { label: 'Prestado', variant: 'blue' },
    parcial: { label: 'Parcial', variant: 'amber' },
    devuelto: { label: 'Devuelto', variant: 'green' },
};

const fmtFecha = (value) => {
    if (!value) return '—';
    const s = String(value);
    const parts = s.slice(0, 10).split('-');
    if (parts.length === 3 && parts[0].length === 4) {
        return `${parts[2]}/${parts[1]}/${parts[0]}`;
    }
    return new Date(value).toLocaleDateString('es-PE');
};

const emptyDetalle = { producto_presentacion_id: '', cantidad_prestada: '' };

export default function Prestamos() {
    const toast = useToast();
    const [tab, setTab] = useState('prestado');

    const [prestamos, setPrestamos] = useState([]);
    const [almacenes, setAlmacenes] = useState([]);
    const [productos, setProductos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState(null);
    const [form, setForm] = useState({
        tipo: 'prestado',
        tercero: '',
        almacen_id: '',
        fecha_prestamo: '',
        fecha_devolucion_esperada: '',
        observaciones: '',
    });
    const [detalles, setDetalles] = useState([{ ...emptyDetalle }]);
    const [formErrors, setFormErrors] = useState({});
    const [saving, setSaving] = useState(false);

    const [deleteTarget, setDeleteTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);

    const [devTarget, setDevTarget] = useState(null);
    const [devLoading, setDevLoading] = useState(false);
    const [devForm, setDevForm] = useState({ producto_presentacion_id: '', cantidad: '' });
    const [devErrors, setDevErrors] = useState({});
    const [savingDev, setSavingDev] = useState(false);

    const [filterEstado, setFilterEstado] = useState('');
    const [activeFilters, setActiveFilters] = useState({});

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const [presRes, almRes, prodRes] = await Promise.all([
                api.get('/prestamos'),
                api.get('/almacenes'),
                api.get('/productos'),
            ]);
            setPrestamos(asList(presRes));
            setAlmacenes(asList(almRes));
            setProductos(asList(prodRes));
        } catch {
            setError('No se pudieron cargar los préstamos.');
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

    const presentacionLabel = (id) =>
        presentacionesOptions.find((o) => o.value === String(id))?.label ?? 'Producto';

    const openCreate = () => {
        setEditing(null);
        setForm({
            tipo: tab,
            tercero: '',
            almacen_id: '',
            fecha_prestamo: new Date().toISOString().slice(0, 10),
            fecha_devolucion_esperada: '',
            observaciones: '',
        });
        setDetalles([{ ...emptyDetalle }]);
        setFormErrors({});
        setModalOpen(true);
    };

    const openEdit = (prestamo) => {
        setEditing(prestamo);
        setForm({
            tipo: prestamo.tipo ?? 'prestado',
            tercero: prestamo.tercero ?? '',
            almacen_id: String(prestamo.almacen_id ?? prestamo.almacen?.id ?? ''),
            fecha_prestamo: prestamo.fecha_prestamo
                ? String(prestamo.fecha_prestamo).slice(0, 10)
                : '',
            fecha_devolucion_esperada: prestamo.fecha_devolucion_esperada
                ? String(prestamo.fecha_devolucion_esperada).slice(0, 10)
                : '',
            observaciones: prestamo.observaciones ?? '',
        });
        setFormErrors({});
        setModalOpen(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSaving(true);
        setFormErrors({});

        const errors = {};
        if (!form.tercero.trim()) errors.tercero = 'Indique con quién se realiza el préstamo';
        if (!form.almacen_id) errors.almacen_id = 'Seleccione un almacén';
        if (detalles.length === 0) {
            errors.detalles = 'Agregue al menos un artículo';
        }
        detalles.forEach((d, i) => {
            if (!d.producto_presentacion_id) {
                errors[`detalles.${i}.producto_presentacion_id`] = 'Seleccione un producto';
            }
            if (!d.cantidad_prestada || Number(d.cantidad_prestada) <= 0) {
                errors[`detalles.${i}.cantidad_prestada`] = 'Cantidad inválida';
            }
        });
        if (Object.keys(errors).length > 0) {
            setFormErrors(errors);
            setSaving(false);
            return;
        }

        try {
            if (editing) {
                await api.put(`/prestamos/${editing.id}`, {
                    tercero: form.tercero.trim(),
                    fecha_devolucion_esperada: form.fecha_devolucion_esperada || null,
                    observaciones: form.observaciones,
                });
                toast.success('Préstamo actualizado correctamente.');
            } else {
                await api.post('/prestamos', {
                    tipo: form.tipo,
                    tercero: form.tercero.trim(),
                    almacen_id: form.almacen_id,
                    fecha_prestamo: form.fecha_prestamo,
                    fecha_devolucion_esperada: form.fecha_devolucion_esperada || null,
                    observaciones: form.observaciones,
                    detalles: detalles.map((d) => ({
                        producto_presentacion_id: d.producto_presentacion_id,
                        cantidad_prestada: Number(d.cantidad_prestada),
                    })),
                });
                toast.success('Préstamo creado correctamente.');
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
                toast.error(err.response?.data?.message ?? 'No se pudo guardar el préstamo.');
            }
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async () => {
        setDeleting(true);
        try {
            await api.delete(`/prestamos/${deleteTarget.id}`);
            toast.success('Préstamo eliminado.');
            setDeleteTarget(null);
            await load();
        } catch {
            toast.error('No se pudo eliminar el préstamo.');
        } finally {
            setDeleting(false);
        }
    };

    // ----- Devoluciones -----

    const openDevolucion = async (prestamo) => {
        setDevLoading(true);
        setDevErrors({});
        setDevForm({ producto_presentacion_id: '', cantidad: '' });
        setDevTarget(null);
        try {
            const res = await api.get(`/prestamos/${prestamo.id}`);
            setDevTarget(res.data?.data ?? res.data);
        } catch {
            toast.error('No se pudo cargar el préstamo.');
        } finally {
            setDevLoading(false);
        }
    };

    const devueltoDe = (presId) =>
        (devTarget?.devoluciones ?? [])
            .filter((d) => d.producto_presentacion_id === presId)
            .reduce((sum, d) => sum + Number(d.cantidad), 0);

    const handleDevolucion = async (e) => {
        e.preventDefault();
        setSavingDev(true);
        setDevErrors({});

        const errors = {};
        if (!devForm.producto_presentacion_id) errors.producto_presentacion_id = 'Seleccione un artículo';
        if (!devForm.cantidad || Number(devForm.cantidad) <= 0) errors.cantidad = 'Cantidad inválida';
        if (Object.keys(errors).length > 0) {
            setDevErrors(errors);
            setSavingDev(false);
            return;
        }

        try {
            const res = await api.post(`/prestamos/${devTarget.id}/devoluciones`, {
                producto_presentacion_id: devForm.producto_presentacion_id,
                cantidad: Number(devForm.cantidad),
            });
            toast.success('Devolución registrada.');
            setDevTarget(res.data?.data ?? res.data);
            setDevForm({ producto_presentacion_id: '', cantidad: '' });
            setDevErrors({});
            await load();
        } catch (err) {
            toast.error(err.response?.data?.message ?? 'No se pudo registrar la devolución.');
        } finally {
            setSavingDev(false);
        }
    };

    // ----- Filtros -----

    const applyFilters = () => {
        const next = {};
        if (filterEstado) next.estado = filterEstado;
        setActiveFilters(next);
    };

    const clearFilters = () => {
        setFilterEstado('');
        setActiveFilters({});
    };

    const filtered = prestamos.filter(
        (p) => p.tipo === tab && (!activeFilters.estado || p.estado === activeFilters.estado),
    );

    const filterCount = Object.keys(activeFilters).length;

    const filters = (
        <div className="flex flex-wrap items-end gap-3">
            <Select
                label="Estado"
                value={filterEstado}
                onChange={(e) => setFilterEstado(e.target.value)}
                options={[
                    { value: '', label: 'Todos' },
                    { value: 'prestado', label: 'Prestado' },
                    { value: 'parcial', label: 'Parcial' },
                    { value: 'devuelto', label: 'Devuelto' },
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

    // ----- Columnas -----

    const columns = [
        {
            key: 'id',
            label: '#',
            render: (row) => <Badge variant="blue">#{String(row.id).padStart(3, '0')}</Badge>,
        },
        {
            key: 'tercero',
            label: tab === 'prestado' ? 'Presté a' : 'Me prestaron',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <Handshake className="h-4 w-4 text-primary-600" />
                    {row.tercero ?? '—'}
                </span>
            ),
        },
        {
            key: 'almacen',
            label: 'Almacén',
            render: (row) => <Badge variant="gray">{row.almacen?.nombre ?? '—'}</Badge>,
        },
        {
            key: 'fecha_prestamo',
            label: 'Fecha préstamo',
            render: (row) => <span className="text-gray-700">{fmtFecha(row.fecha_prestamo)}</span>,
        },
        {
            key: 'fecha_devolucion_esperada',
            label: 'Dev. esperada',
            render: (row) => <span className="text-gray-700">{fmtFecha(row.fecha_devolucion_esperada)}</span>,
        },
        {
            key: 'detalles',
            label: 'Artículos',
            render: (row) => (
                <Badge variant="blue">{Array.isArray(row.detalles) ? row.detalles.length : 0}</Badge>
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
            type: 'actions',
            key: 'actions',
            label: 'Acciones',
            actions: (row) => (
                <>
                    <button
                        aria-label="Devolución"
                        title="Registrar devolución"
                        onClick={() => openDevolucion(row)}
                        className="rounded-md p-1.5 text-amber-600 transition hover:bg-amber-50 hover:text-amber-700"
                    >
                        <Undo2 className="h-4 w-4" />
                    </button>
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
                title="Préstamos"
                description="La tienda presta mercadería o pide prestada"
                actions={<CreateButton onClick={openCreate}>Nuevo préstamo</CreateButton>}
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <div className="mb-4">
                <Tabs
                    items={[
                        { key: 'prestado', label: 'Presté', icon: HandCoins },
                        { key: 'recibido', label: 'Me prestaron', icon: Handshake },
                    ]}
                    value={tab}
                    onChange={setTab}
                />
            </div>

            <DataTable
                columns={columns}
                rows={filtered}
                loading={loading}
                searchPlaceholder="Buscar por tercero..."
                filterable
                filters={filters}
                filterCount={filterCount}
            />

            {/* Modal crear/editar */}
            <Modal
                open={modalOpen}
                onClose={() => setModalOpen(false)}
                title={editing ? 'Editar préstamo' : 'Nuevo préstamo'}
                description={
                    editing
                        ? `Modifica el préstamo con "${editing.tercero}"`
                        : form.tipo === 'prestado'
                          ? 'La tienda presta mercadería a un tercero'
                          : 'La tienda pide mercadería prestada a un tercero'
                }
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>
                            Cancelar
                        </Button>
                        <Button type="submit" form="prestamo-form" loading={saving}>
                            {editing ? 'Guardar cambios' : 'Crear préstamo'}
                        </Button>
                    </>
                }
            >
                <form id="prestamo-form" onSubmit={handleSubmit} className="space-y-4" noValidate>
                    <Select
                        label="Dirección"
                        name="tipo"
                        value={form.tipo}
                        onChange={(e) => setForm((prev) => ({ ...prev, tipo: e.target.value }))}
                        options={[
                            { value: 'prestado', label: 'Presté (la tienda presta)' },
                            { value: 'recibido', label: 'Me prestaron (la tienda pide prestado)' },
                        ]}
                        disabled={Boolean(editing)}
                    />
                    <Input
                        label="Tercero"
                        name="tercero"
                        placeholder="¿A quién? Ej: Tienda Los Andes"
                        value={form.tercero}
                        onChange={(e) => {
                            setForm((prev) => ({ ...prev, tercero: e.target.value }));
                            if (formErrors.tercero) {
                                setFormErrors((prev) => ({ ...prev, tercero: undefined }));
                            }
                        }}
                        error={formErrors.tercero}
                    />
                    <Select
                        label="Almacén"
                        name="almacen_id"
                        value={form.almacen_id}
                        onChange={(e) => setForm((prev) => ({ ...prev, almacen_id: e.target.value }))}
                        options={[
                            { value: '', label: 'Seleccione un almacén' },
                            ...almacenes.map((a) => ({ value: String(a.id), label: a.nombre })),
                        ]}
                        error={formErrors.almacen_id}
                        disabled={Boolean(editing)}
                    />
                    <div className="grid grid-cols-2 gap-3">
                        <Input
                            type="date"
                            label="Fecha del préstamo"
                            name="fecha_prestamo"
                            value={form.fecha_prestamo}
                            onChange={(e) => setForm((prev) => ({ ...prev, fecha_prestamo: e.target.value }))}
                            disabled={Boolean(editing)}
                        />
                        <Input
                            type="date"
                            label="Devolución esperada"
                            name="fecha_devolucion_esperada"
                            value={form.fecha_devolucion_esperada}
                            onChange={(e) =>
                                setForm((prev) => ({ ...prev, fecha_devolucion_esperada: e.target.value }))
                            }
                        />
                    </div>

                    {!editing && (
                        <div>
                            <p className="mb-1 block text-sm font-medium text-gray-700">Artículos</p>
                            <div className="space-y-2">
                                {detalles.map((d, index) => (
                                    <div key={index} className="flex items-start gap-2">
                                        <Select
                                            value={d.producto_presentacion_id}
                                            onChange={(e) => {
                                                const next = [...detalles];
                                                next[index] = { ...d, producto_presentacion_id: e.target.value };
                                                setDetalles(next);
                                                setFormErrors((prev) => ({
                                                    ...prev,
                                                    [`detalles.${index}.producto_presentacion_id`]: undefined,
                                                }));
                                            }}
                                            options={[
                                                { value: '', label: 'Seleccione producto — presentación' },
                                                ...presentacionesOptions,
                                            ]}
                                            error={formErrors[`detalles.${index}.producto_presentacion_id`]}
                                        />
                                        <Input
                                            type="number"
                                            min="0"
                                            step="any"
                                            placeholder="Cant."
                                            value={d.cantidad_prestada}
                                            onChange={(e) => {
                                                const next = [...detalles];
                                                next[index] = { ...d, cantidad_prestada: e.target.value };
                                                setDetalles(next);
                                                setFormErrors((prev) => ({
                                                    ...prev,
                                                    [`detalles.${index}.cantidad_prestada`]: undefined,
                                                }));
                                            }}
                                            className="w-28 shrink-0"
                                            error={formErrors[`detalles.${index}.cantidad_prestada`]}
                                        />
                                        <button
                                            type="button"
                                            aria-label="Quitar artículo"
                                            onClick={() => {
                                                setDetalles((prev) => prev.filter((_, i) => i !== index));
                                            }}
                                            disabled={detalles.length === 1}
                                            className="mt-1 shrink-0 rounded-md p-2 text-gray-400 transition hover:bg-red-50 hover:text-red-600 disabled:opacity-30"
                                        >
                                            <X className="h-4 w-4" />
                                        </button>
                                    </div>
                                ))}
                            </div>
                            <button
                                type="button"
                                onClick={() => setDetalles((prev) => [...prev, { ...emptyDetalle }])}
                                className="mt-2 inline-flex items-center gap-1.5 rounded-md px-2 py-1.5 text-sm font-medium text-primary-600 transition hover:bg-primary-50"
                            >
                                <Plus className="h-4 w-4" />
                                Agregar artículo
                            </button>
                            {formErrors.detalles && (
                                <p className="mt-1 text-xs text-red-600">{formErrors.detalles}</p>
                            )}
                        </div>
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

            {/* Modal devolución */}
            <Modal
                open={Boolean(devTarget) || devLoading}
                onClose={() => setDevTarget(null)}
                title="Registrar devolución"
                description={
                    devTarget
                        ? `${devTarget.tercero} — ${devTarget.tipo === 'prestado' ? 'me devuelve' : 'devuelvo'}`
                        : 'Cargando...'
                }
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setDevTarget(null)}>
                            Cerrar
                        </Button>
                        <Button
                            type="submit"
                            form="devolucion-form"
                            loading={savingDev}
                            disabled={!devTarget}
                        >
                            Registrar devolución
                        </Button>
                    </>
                }
            >
                {devLoading ? (
                    <p className="py-4 text-center text-sm text-gray-400">Cargando...</p>
                ) : (
                    <div className="space-y-4">
                        <div className="rounded-lg border border-edge bg-gray-50 p-3">
                            <p className="mb-2 flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wider text-gray-500">
                                <ArrowLeftRight className="h-3.5 w-3.5" />
                                Estado del préstamo
                            </p>
                            <ul className="space-y-1.5">
                                {(devTarget?.detalles ?? []).map((det) => (
                                    <li
                                        key={det.id}
                                        className="flex items-center justify-between gap-2 text-sm"
                                    >
                                        <span className="min-w-0 truncate text-gray-700">
                                            {det.presentacion?.producto?.nombre ?? 'Producto'} —{' '}
                                            {det.presentacion?.nombre ?? ''}
                                        </span>
                                        <span className="shrink-0">
                                            <Badge variant={devueltoDe(det.producto_presentacion_id) >= Number(det.cantidad_prestada) ? 'green' : 'amber'}>
                                                {devueltoDe(det.producto_presentacion_id)} / {Number(det.cantidad_prestada)}
                                            </Badge>
                                        </span>
                                    </li>
                                ))}
                            </ul>
                        </div>

                        <form id="devolucion-form" onSubmit={handleDevolucion} className="space-y-4" noValidate>
                            <Select
                                label="Artículo a devolver"
                                name="producto_presentacion_id"
                                value={devForm.producto_presentacion_id}
                                onChange={(e) => {
                                    setDevForm((prev) => ({ ...prev, producto_presentacion_id: e.target.value }));
                                    if (devErrors.producto_presentacion_id) {
                                        setDevErrors((prev) => ({ ...prev, producto_presentacion_id: undefined }));
                                    }
                                }}
                                options={[
                                    { value: '', label: 'Seleccione un artículo' },
                                    ...(devTarget?.detalles ?? []).map((det) => ({
                                        value: String(det.producto_presentacion_id),
                                        label: `${det.presentacion?.producto?.nombre ?? 'Producto'} — ${det.presentacion?.nombre ?? ''}`,
                                    })),
                                ]}
                                error={devErrors.producto_presentacion_id}
                            />
                            <Input
                                type="number"
                                min="0"
                                step="any"
                                label="Cantidad"
                                name="cantidad"
                                placeholder="Ej: 2"
                                value={devForm.cantidad}
                                onChange={(e) => {
                                    setDevForm((prev) => ({ ...prev, cantidad: e.target.value }));
                                    if (devErrors.cantidad) {
                                        setDevErrors((prev) => ({ ...prev, cantidad: undefined }));
                                    }
                                }}
                                error={devErrors.cantidad}
                            />
                            {devTarget && devTarget.estado === 'devuelto' && (
                                <Alert variant="success">Este préstamo ya está devuelto por completo.</Alert>
                            )}
                        </form>
                    </div>
                )}
            </Modal>

            {/* Modal eliminar */}
            <Modal
                open={Boolean(deleteTarget)}
                onClose={() => setDeleteTarget(null)}
                title="Eliminar préstamo"
                description={`¿Seguro que deseas eliminar el préstamo con "${deleteTarget?.tercero}"?`}
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
                    Se eliminará el préstamo y sus artículos y devoluciones asociadas.
                </Alert>
            </Modal>
        </Layout>
    );
}
