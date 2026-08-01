import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Ban, ShoppingBag, Trash2 } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Modal } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const docLabel = { factura: 'Factura', boleta: 'Boleta', guia: 'Guía' };

export default function Compras() {
    const toast = useToast();
    const navigate = useNavigate();
    const [compras, setCompras] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const [deleteTarget, setDeleteTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);
    const [actionId, setActionId] = useState(null);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            setCompras(asList(await api.get('/compras')));
        } catch {
            setError('No se pudieron cargar las compras.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    const anular = async (row) => {
        setActionId(row.id);
        try {
            await api.post(`/compras/${row.id}/anular`);
            toast.success('Compra anulada.');
            await load();
        } catch {
            toast.error('No se pudo anular la compra.');
        } finally {
            setActionId(null);
        }
    };

    const handleDelete = async () => {
        setDeleting(true);
        try {
            await api.delete(`/compras/${deleteTarget.id}`);
            toast.success('Compra eliminada.');
            setDeleteTarget(null);
            await load();
        } catch {
            toast.error('No se pudo eliminar la compra.');
        } finally {
            setDeleting(false);
        }
    };

    const columns = [
        { key: 'id', label: '#', render: (row) => <Badge variant="blue">#{String(row.id).padStart(4, '0')}</Badge> },
        { key: 'fecha', label: 'Fecha', render: (row) => (row.fecha ? new Date(row.fecha).toLocaleDateString('es-PE') : '—') },
        {
            key: 'proveedor',
            label: 'Proveedor',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <ShoppingBag className="h-4 w-4 text-primary-600" />
                    {row.proveedor?.nombre ?? '—'}
                </span>
            ),
        },
        {
            key: 'documento',
            label: 'Documento',
            render: (row) => (
                <span className="text-gray-700">
                    {docLabel[row.tipo_documento] ?? row.tipo_documento}
                    {row.serie || row.numero ? ` ${row.serie ?? ''}-${row.numero ?? ''}` : ''}
                </span>
            ),
        },
        {
            key: 'forma_pago',
            label: 'Pago',
            render: (row) => (
                <Badge variant={row.forma_pago === 'contado' ? 'green' : 'amber'}>
                    {row.forma_pago === 'contado' ? 'Contado' : 'Crédito'}
                </Badge>
            ),
        },
        { key: 'detalles_count', label: 'Ítems', render: (row) => <Badge variant="gray">{row.detalles_count ?? 0}</Badge> },
        { key: 'total', label: 'Total', align: 'right', render: (row) => <span className="font-semibold text-warm-900">{money(row.total)}</span> },
        {
            key: 'estado',
            label: 'Estado',
            render: (row) =>
                row.estado === 'anulada' ? <Badge variant="red">Anulada</Badge> : <Badge variant="green">Registrada</Badge>,
        },
        {
            type: 'actions',
            key: 'actions',
            label: 'Acciones',
            actions: (row) => (
                <>
                    {row.estado !== 'anulada' && (
                        <button
                            aria-label="Anular"
                            title="Anular"
                            disabled={actionId === row.id}
                            onClick={() => anular(row)}
                            className="rounded-md p-1.5 text-gray-500 transition hover:bg-gray-100 disabled:opacity-40"
                        >
                            <Ban className="h-4 w-4" />
                        </button>
                    )}
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
                title="Compras"
                description="Comprobantes de compra a proveedores"
                actions={<CreateButton onClick={() => navigate('/compras/nueva')}>Nueva compra</CreateButton>}
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable
                columns={columns}
                rows={compras}
                loading={loading}
                searchPlaceholder="Buscar compras..."
            />

            <Modal
                open={Boolean(deleteTarget)}
                onClose={() => setDeleteTarget(null)}
                title="Eliminar compra"
                description={`¿Eliminar la compra #${deleteTarget?.id}?`}
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setDeleteTarget(null)}>Cancelar</Button>
                        <Button variant="danger" loading={deleting} onClick={handleDelete}>Eliminar</Button>
                    </>
                }
            >
                <Alert variant="warning">La compra y sus pagos se eliminarán permanentemente.</Alert>
            </Modal>
        </Layout>
    );
}
