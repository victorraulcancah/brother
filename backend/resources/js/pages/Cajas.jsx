import { useCallback, useEffect, useState } from 'react';
import { Coins, Edit, Trash2 } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal, Select } from '../components/ui';

const emptyForm = { nombre: '', almacen_id: '', activo: true };

export default function Cajas() {
    const toast = useToast();
    const [cajas, setCajas] = useState([]);
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

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const [cajasRes, almacenesRes] = await Promise.all([
                api.get('/cajas'),
                api.get('/almacenes'),
            ]);
            setCajas(asList(cajasRes));
            setAlmacenes(asList(almacenesRes));
        } catch {
            setError('No se pudieron cargar las cajas.');
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

    const openEdit = (caja) => {
        setEditing(caja);
        setForm({
            nombre: caja.nombre,
            almacen_id: caja.almacen_id ?? '',
            activo: Boolean(caja.activo),
        });
        setFormErrors({});
        setModalOpen(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSaving(true);
        setFormErrors({});
        const payload = { ...form, almacen_id: form.almacen_id || null };
        try {
            if (editing) {
                await api.put(`/cajas/${editing.id}`, payload);
                toast.success('Caja actualizada correctamente.');
            } else {
                await api.post('/cajas', payload);
                toast.success('Caja creada correctamente.');
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
                toast.error('No se pudo guardar la caja.');
            }
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async () => {
        setDeleting(true);
        try {
            await api.delete(`/cajas/${deleteTarget.id}`);
            toast.success('Caja eliminada.');
            setDeleteTarget(null);
            await load();
        } catch {
            toast.error('No se pudo eliminar la caja.');
        } finally {
            setDeleting(false);
        }
    };

    const columns = [
        {
            key: 'nombre',
            label: 'Caja',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <Coins className="h-4 w-4 text-primary-600" />
                    {row.nombre}
                </span>
            ),
        },
        {
            key: 'almacen',
            label: 'Almacén',
            render: (row) => row.almacen?.nombre ?? <span className="text-gray-400">—</span>,
        },
        {
            key: 'activo',
            label: 'Estado',
            render: (row) =>
                row.activo ? (
                    <Badge variant="green">Activa</Badge>
                ) : (
                    <Badge variant="red">Inactiva</Badge>
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
                title="Cajas"
                description="Cajas registradoras del negocio"
                actions={<CreateButton onClick={openCreate}>Crear caja</CreateButton>}
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable
                columns={columns}
                rows={cajas}
                loading={loading}
                searchPlaceholder="Buscar cajas..."
            />

            <Modal
                open={modalOpen}
                onClose={() => setModalOpen(false)}
                title={editing ? 'Editar caja' : 'Crear caja'}
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>
                            Cancelar
                        </Button>
                        <Button type="submit" form="caja-form" loading={saving}>
                            {editing ? 'Guardar cambios' : 'Crear caja'}
                        </Button>
                    </>
                }
            >
                <form id="caja-form" onSubmit={handleSubmit} className="space-y-4" noValidate>
                    <Input
                        label="Nombre"
                        placeholder="Ej: Caja principal"
                        value={form.nombre}
                        onChange={(e) => {
                            setForm((prev) => ({ ...prev, nombre: e.target.value }));
                            if (formErrors.nombre) setFormErrors((p) => ({ ...p, nombre: undefined }));
                        }}
                        error={formErrors.nombre}
                    />
                    <Select
                        label="Almacén"
                        value={form.almacen_id}
                        onChange={(e) => setForm((prev) => ({ ...prev, almacen_id: e.target.value }))}
                        options={[
                            { value: '', label: 'Sin almacén' },
                            ...almacenes.map((a) => ({ value: a.id, label: a.nombre })),
                        ]}
                        error={formErrors.almacen_id}
                    />
                    <label className="flex items-center gap-2 text-sm text-gray-700">
                        <input
                            type="checkbox"
                            checked={form.activo}
                            onChange={(e) => setForm((prev) => ({ ...prev, activo: e.target.checked }))}
                            className="h-4 w-4 rounded border-gray-300 accent-primary-600"
                        />
                        Caja activa
                    </label>
                </form>
            </Modal>

            <Modal
                open={Boolean(deleteTarget)}
                onClose={() => setDeleteTarget(null)}
                title="Eliminar caja"
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
                    Las aperturas y movimientos históricos de esta caja podrían verse afectados.
                </Alert>
            </Modal>
        </Layout>
    );
}
