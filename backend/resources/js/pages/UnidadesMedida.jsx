import { useCallback, useEffect, useState } from 'react';
import { Edit, Ruler, Trash2 } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal } from '../components/ui';

export default function UnidadesMedida() {
    const toast = useToast();
    const [unidades, setUnidades] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState(null);
    const [form, setForm] = useState({ nombre: '', abreviatura: '' });
    const [errors, setErrors] = useState({});
    const [saving, setSaving] = useState(false);

    const [deleteTarget, setDeleteTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const res = await api.get('/unidades-medida');
            setUnidades(asList(res));
        } catch {
            setError('No se pudieron cargar las unidades de medida.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    const openCreate = () => {
        setEditing(null);
        setForm({ nombre: '', abreviatura: '' });
        setErrors({});
        setModalOpen(true);
    };

    const openEdit = (u) => {
        setEditing(u);
        setForm({ nombre: u.nombre, abreviatura: u.abreviatura });
        setErrors({});
        setModalOpen(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSaving(true);
        setErrors({});

        try {
            if (editing) {
                await api.put(`/unidades-medida/${editing.id}`, form);
                toast.success('Unidad actualizada correctamente.');
            } else {
                await api.post('/unidades-medida', form);
                toast.success('Unidad creada correctamente.');
            }
            setModalOpen(false);
            await load();
        } catch (err) {
            if (err.response?.status === 422) {
                const validation = err.response.data?.errors ?? {};
                setErrors(
                    Object.fromEntries(Object.entries(validation).map(([k, v]) => [k, v[0]])),
                );
            } else {
                toast.error('No se pudo guardar la unidad de medida.');
            }
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async () => {
        setDeleting(true);
        try {
            await api.delete(`/unidades-medida/${deleteTarget.id}`);
            toast.success('Unidad eliminada.');
            setDeleteTarget(null);
            await load();
        } catch {
            toast.error('No se pudo eliminar la unidad de medida.');
        } finally {
            setDeleting(false);
        }
    };

    const columns = [
        {
            key: 'nombre',
            label: 'Unidad',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <Ruler className="h-4 w-4 text-primary-600" />
                    {row.nombre}
                </span>
            ),
        },
        {
            key: 'abreviatura',
            label: 'Abreviatura',
            render: (row) => <Badge variant="blue">{row.abreviatura}</Badge>,
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
                title="Unidades de medida"
                description="Administra las unidades de medida de tus productos"
                actions={<CreateButton onClick={openCreate}>Crear unidad</CreateButton>}
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable
                columns={columns}
                rows={unidades}
                loading={loading}
                searchPlaceholder="Buscar unidades..."
            />

            <Modal
                open={modalOpen}
                onClose={() => setModalOpen(false)}
                title={editing ? 'Editar unidad' : 'Crear unidad'}
                description={
                    editing ? `Modifica "${editing.nombre}"` : 'Agrega una nueva unidad de medida'
                }
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>
                            Cancelar
                        </Button>
                        <Button type="submit" form="unidad-form" loading={saving}>
                            {editing ? 'Guardar cambios' : 'Crear unidad'}
                        </Button>
                    </>
                }
            >
                <form id="unidad-form" onSubmit={handleSubmit} className="space-y-4" noValidate>
                    <Input
                        label="Nombre"
                        name="nombre"
                        placeholder="Ej: Kilogramo, Litro, Unidad"
                        value={form.nombre}
                        onChange={(e) => {
                            setForm((prev) => ({ ...prev, nombre: e.target.value }));
                            if (errors.nombre) {
                                setErrors((prev) => ({ ...prev, nombre: undefined }));
                            }
                        }}
                        error={errors.nombre}
                    />
                    <Input
                        label="Abreviatura"
                        name="abreviatura"
                        placeholder="Ej: kg, L, und"
                        value={form.abreviatura}
                        onChange={(e) => {
                            setForm((prev) => ({ ...prev, abreviatura: e.target.value }));
                            if (errors.abreviatura) {
                                setErrors((prev) => ({ ...prev, abreviatura: undefined }));
                            }
                        }}
                        error={errors.abreviatura}
                    />
                </form>
            </Modal>

            <Modal
                open={Boolean(deleteTarget)}
                onClose={() => setDeleteTarget(null)}
                title="Eliminar unidad"
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
                    Los productos que usen esta unidad quedarán sin referencia.
                </Alert>
            </Modal>
        </Layout>
    );
}
