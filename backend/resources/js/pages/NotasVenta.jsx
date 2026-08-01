import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Ban, ReceiptText, User } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

export default function NotasVenta() {
    const toast = useToast();
    const navigate = useNavigate();
    const [notas, setNotas] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const [anularTarget, setAnularTarget] = useState(null);
    const [motivo, setMotivo] = useState('');
    const [anulando, setAnulando] = useState(false);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            setNotas(asList(await api.get('/notas-venta')));
        } catch {
            setError('No se pudieron cargar las ventas.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    const handleAnular = async () => {
        if (!motivo.trim()) {
            toast.error('Escribe el motivo de anulación.');
            return;
        }
        setAnulando(true);
        try {
            await api.post(`/notas-venta/${anularTarget.id}/anular`, { motivo_anulacion: motivo });
            toast.success('Venta anulada. Stock devuelto al almacén.');
            setAnularTarget(null);
            setMotivo('');
            await load();
        } catch (err) {
            toast.error(err.response?.data?.message ?? 'No se pudo anular la venta.');
        } finally {
            setAnulando(false);
        }
    };

    const columns = [
        {
            key: 'documento',
            label: 'Documento',
            render: (row) => <Badge variant="gray">{row.serie}-{row.numero}</Badge>,
        },
        {
            key: 'cliente',
            label: 'Cliente',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <User className="h-4 w-4 text-primary-600" />
                    {row.cliente?.nombre ?? 'Público general'}
                </span>
            ),
        },
        { key: 'fecha_emision', label: 'Fecha', render: (row) => (row.fecha_emision ? new Date(row.fecha_emision).toLocaleDateString('es-PE') : '—') },
        {
            key: 'tipo_pago',
            label: 'Pago',
            render: (row) => (
                <Badge variant={row.tipo_pago === 'contado' ? 'green' : 'amber'}>
                    {row.tipo_pago === 'contado' ? 'Contado' : 'Crédito'}
                </Badge>
            ),
        },
        { key: 'total', label: 'Total', align: 'right', render: (row) => <span className="font-semibold text-warm-900">{money(row.total)}</span> },
        {
            key: 'estado',
            label: 'Estado',
            render: (row) =>
                row.estado === 'anulada' ? <Badge variant="red">Anulada</Badge> : <Badge variant="green">Emitida</Badge>,
        },
        {
            type: 'actions',
            key: 'actions',
            label: 'Acciones',
            actions: (row) =>
                row.estado !== 'anulada' ? (
                    <button
                        aria-label="Anular"
                        title="Anular venta"
                        onClick={() => { setAnularTarget(row); setMotivo(''); }}
                        className="rounded-md p-1.5 text-red-600 transition hover:bg-red-50 hover:text-red-700"
                    >
                        <Ban className="h-4 w-4" />
                    </button>
                ) : (
                    <span className="text-xs text-gray-400">—</span>
                ),
        },
    ];

    return (
        <Layout>
            <PageHeader
                title="Notas de Venta"
                description="Ventas emitidas a clientes"
                actions={
                    <CreateButton onClick={() => navigate('/notas-venta/nueva')}>Nueva venta</CreateButton>
                }
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable columns={columns} rows={notas} loading={loading} searchPlaceholder="Buscar ventas..." />

            <Modal
                open={Boolean(anularTarget)}
                onClose={() => setAnularTarget(null)}
                title="Anular venta"
                description={`Venta ${anularTarget?.serie}-${anularTarget?.numero}. El stock volverá al almacén.`}
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setAnularTarget(null)}>Cancelar</Button>
                        <Button variant="danger" loading={anulando} onClick={handleAnular}>Anular venta</Button>
                    </>
                }
            >
                <Input
                    label="Motivo de anulación"
                    placeholder="Ej: error en el registro"
                    value={motivo}
                    onChange={(e) => setMotivo(e.target.value)}
                />
            </Modal>
        </Layout>
    );
}
