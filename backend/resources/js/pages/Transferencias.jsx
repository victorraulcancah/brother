import { useCallback, useEffect, useState } from 'react';
import { ArrowRight, Ban, Edit, PackageCheck, Plus, Repeat, Send, Trash2 } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal, Select } from '../components/ui';

const emptyForm = { almacen_origen_id: '', almacen_destino_id: '', observaciones: '' };
const emptyDetalle = { producto_presentacion_id: '', cantidad_enviada: '' };

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
    const [productos, setProductos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState(null);
    const [form, setForm] = useState(emptyForm);
    const [detalles, setDetalles] = useState([{ ...emptyDetalle }]);
    const [formErrors, setFormErrors] = useState({});
    const [saving, setSaving] = useState(false);
    const [actionId, setActionId] = useState(null);

    const [deleteTarget, setDeleteTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);

    const [filterEstado, setFilterEstado] = useState('');
    const [filterAlmacen, setFilterAlmacen] = useState('');
    const [activeFilters, setActiveFilters] = useState({});

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const [transRes, almRes, prodRes] = await Promise.all([
                api.get('/transferencias'),
                api.get('/almacenes'),
                api.get('/productos'),
            ]);
            setTransferencias(asList(transRes));
            setAlmacenes(asList(almRes));
            setProductos(asList(prodRes));
        } catch {
            setError('No se pudieron cargar las transferencias.');
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

    const setDetalle = (index, patch) =>
        setDetalles((prev) => prev.map((d, i) => (i === index ? { ...d, ...patch } : d)));
    const addDetalle = () => setDetalles((prev) => [...prev, { ...emptyDetalle }]);
    const removeDetalle = (index) =>
        setDetalles((prev) => (prev.length === 1 ? prev : prev.filter((_, i) => i !== index)));

    const runAccion = async (row, accion, exito) => {
        setActionId(row.id);
        try {
            await api.post(`/transferencias/${row.id}/${accion}`);
            toast.success(exito);
            await load();
        } catch (err) {
            toast.error(err.response?.data?.message ?? 'No se pudo completar la acción.');
        } finally {
            setActionId(null);
        }
    };

    const openCreate = () => {
        setEditing(null);
        setForm(emptyForm);
        setDetalles([{ ...emptyDetalle }]);
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
                const lineas = detalles.filter((d) => d.producto_presentacion_id && Number(d.cantidad_enviada) > 0);
                if (lineas.length === 0) {
                    setFormErrors((prev) => ({ ...prev, detalles: 'Agrega al menos un producto con cantidad.' }));
                    setSaving(false);
                    return;
                }
                await api.post('/transferencias', {
                    almacen_origen_id: form.almacen_origen_id,
                    almacen_destino_id: form.almacen_destino_id,
                    observaciones: form.observaciones,
                    detalles: lineas.map((d) => ({
                        producto_presentacion_id: d.producto_presentacion_id,
                        cantidad_enviada: d.cantidad_enviada,
                    })),
                });
                toast.success('Traslado creado. Ahora puedes enviarlo.');
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
            actions: (row) => {
                const busy = actionId === row.id;
                return (
                    <>
                        {row.estado === 'pendiente' && (
                            <>
                                <button
                                    aria-label="Enviar"
                                    title="Enviar (descuenta de origen)"
                                    disabled={busy}
                                    onClick={() => runAccion(row, 'enviar', 'Traslado enviado. Stock descontado del origen.')}
                                    className="rounded-md p-1.5 text-blue-600 transition hover:bg-blue-50 disabled:opacity-40"
                                >
                                    <Send className="h-4 w-4" />
                                </button>
                                <button
                                    aria-label="Editar"
                                    onClick={() => openEdit(row)}
                                    className="rounded-md p-1.5 text-primary-600 transition hover:bg-primary-50 hover:text-primary-700"
                                >
                                    <Edit className="h-4 w-4" />
                                </button>
                                <button
                                    aria-label="Anular"
                                    title="Anular"
                                    disabled={busy}
                                    onClick={() => runAccion(row, 'anular', 'Traslado anulado.')}
                                    className="rounded-md p-1.5 text-gray-500 transition hover:bg-gray-100 disabled:opacity-40"
                                >
                                    <Ban className="h-4 w-4" />
                                </button>
                                <button
                                    aria-label="Eliminar"
                                    onClick={() => setDeleteTarget(row)}
                                    className="rounded-md p-1.5 text-red-600 transition hover:bg-red-50 hover:text-red-700"
                                >
                                    <Trash2 className="h-4 w-4" />
                                </button>
                            </>
                        )}
                        {row.estado === 'en_transito' && (
                            <button
                                aria-label="Recibir"
                                title="Recibir (ingresa al destino)"
                                disabled={busy}
                                onClick={() => runAccion(row, 'recibir', 'Traslado recibido. Stock ingresado al destino.')}
                                className="inline-flex items-center gap-1 rounded-md px-2 py-1.5 text-sm font-medium text-green-600 transition hover:bg-green-50 disabled:opacity-40"
                            >
                                <PackageCheck className="h-4 w-4" />
                                Recibir
                            </button>
                        )}
                        {(row.estado === 'recibida' || row.estado === 'cancelada') && (
                            <span className="text-xs text-gray-400">—</span>
                        )}
                    </>
                );
            },
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
                        <Alert variant="info">
                            El estado se maneja con los botones Enviar / Recibir de la tabla. Aquí solo
                            puedes editar las observaciones.
                        </Alert>
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

                            <div>
                                <div className="mb-1 flex items-center justify-between">
                                    <span className="text-sm font-medium text-gray-700">Productos</span>
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
                                                value={d.cantidad_enviada}
                                                onChange={(e) => setDetalle(index, { cantidad_enviada: e.target.value })}
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
