import { useCallback, useEffect, useState } from 'react';
import api, { asList } from '../lib/api';
import Layout from '../components/Layout';
import PageHeader from '../components/PageHeader';
import { Alert, Badge, DataTable } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const fecha = (v) => (v ? new Date(v).toLocaleString('es-PE') : '—');

export default function MovimientosCaja() {
    const [rows, setRows] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            setRows(asList(await api.get('/movimientos-caja')));
        } catch {
            setError('No se pudieron cargar los movimientos de caja.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    const columns = [
        { key: 'fecha', label: 'Fecha', render: (row) => fecha(row.fecha) },
        {
            key: 'apertura',
            label: 'Caja',
            render: (row) => row.apertura?.caja?.nombre ?? '—',
        },
        {
            key: 'tipo',
            label: 'Tipo',
            render: (row) => (
                <Badge variant={row.tipo === 'ingreso' ? 'green' : 'red'}>
                    {row.tipo === 'ingreso' ? 'Ingreso' : 'Egreso'}
                </Badge>
            ),
        },
        {
            key: 'metodo_pago',
            label: 'Método',
            render: (row) => row.metodo_pago?.nombre ?? <span className="text-gray-400">—</span>,
        },
        {
            key: 'numero_operacion',
            label: 'N° Operación',
            render: (row) => row.numero_operacion || <span className="text-gray-400">—</span>,
        },
        {
            key: 'monto',
            label: 'Monto',
            align: 'right',
            render: (row) => (
                <span className={row.tipo === 'ingreso' ? 'text-green-600' : 'text-red-600'}>
                    {row.tipo === 'ingreso' ? '+' : '-'} {money(row.monto)}
                </span>
            ),
        },
    ];

    return (
        <Layout>
            <PageHeader
                title="Movimientos de Caja"
                description="Historial de ingresos y egresos por caja"
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable
                columns={columns}
                rows={rows}
                loading={loading}
                searchPlaceholder="Buscar movimientos..."
                emptyMessage="Aún no hay movimientos de caja registrados."
            />
        </Layout>
    );
}
