import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ShoppingCart, Trash2 } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Modal } from '../components/ui';

const estadoInfo = {
    pendiente: { label: 'Pendiente', variant: 'amber' },
    aprobada: { label: 'Aprobada', variant: 'green' },
    enviada: { label: 'Enviada', variant: 'blue' },
    parcial: { label: 'Parcial', variant: 'amber' },
    completada: { label: 'Completada', variant: 'green' },
    anulada: { label: 'Anulada', variant: 'red' },
};

export default function OrdenesCompra() {
    const toast = useToast();
    const navigate = useNavigate();
    const [ordenes, setOrdenes] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const [deleteTarget, setDeleteTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            setOrdenes(asList(await api.get('/ordenes-compra')));
        } catch {
            setError('No se pudieron cargar las órdenes de compra.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

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
                actions={<CreateButton onClick={() => navigate('/ordenes-compra/nueva')}>Nueva orden</CreateButton>}
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable columns={columns} rows={ordenes} loading={loading} searchPlaceholder="Buscar órdenes..." />

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
