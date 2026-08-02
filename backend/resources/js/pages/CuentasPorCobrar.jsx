import { useCallback, useEffect, useState } from 'react';
import { Wallet } from 'lucide-react';
import api, { asList } from '../lib/api';
import Layout from '../components/Layout';
import PageHeader from '../components/PageHeader';
import PagosCuentaModal from '../components/PagosCuentaModal';
import { Alert, Badge, Button, DataTable } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const fecha = (v) => (v ? new Date(v).toLocaleDateString('es-PE') : '—');

const estadoBadge = (estado) => {
    const map = { pendiente: 'red', parcial: 'amber', pagado: 'green', anulado: 'gray' };
    return <Badge variant={map[estado] ?? 'gray'}>{estado ?? '—'}</Badge>;
};

export default function CuentasPorCobrar() {
    const [rows, setRows] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [pagoCuenta, setPagoCuenta] = useState(null);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            setRows(asList(await api.get('/cuentas-por-cobrar')));
        } catch {
            setError('No se pudieron cargar las cuentas por cobrar.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    const columns = [
        { key: 'id', label: '#', render: (row) => <Badge variant="blue">{String(row.id).padStart(2, '0')}</Badge> },
        {
            key: 'cliente',
            label: 'Cliente',
            render: (row) => row.cliente?.nombre ?? <span className="text-gray-400">—</span>,
        },
        { key: 'fecha_vencimiento', label: 'Vence', render: (row) => fecha(row.fecha_vencimiento) },
        { key: 'monto_total', label: 'Total', align: 'right', render: (row) => money(row.monto_total) },
        {
            key: 'monto_pagado',
            label: 'Pagado',
            align: 'right',
            render: (row) => <span className="text-green-600">{money(row.monto_pagado)}</span>,
        },
        {
            key: 'saldo',
            label: 'Saldo',
            align: 'right',
            render: (row) => <span className="font-medium text-red-600">{money(row.saldo)}</span>,
        },
        { key: 'estado', label: 'Estado', render: (row) => estadoBadge(row.estado) },
        {
            key: 'acciones',
            label: 'Acciones',
            type: 'actions',
            align: 'right',
            actions: (row) => (
                <Button size="sm" variant="secondary" onClick={() => setPagoCuenta(row)}>
                    <Wallet className="h-4 w-4" /> Pagos
                </Button>
            ),
        },
    ];

    return (
        <Layout>
            <PageHeader
                title="Cuentas por Cobrar"
                description="Deudas pendientes de tus clientes (ventas al crédito)"
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable
                columns={columns}
                rows={rows}
                loading={loading}
                searchPlaceholder="Buscar por cliente..."
                emptyMessage="No hay cuentas por cobrar registradas."
            />

            <PagosCuentaModal
                open={!!pagoCuenta}
                cuenta={pagoCuenta}
                tipo="cobrar"
                onClose={() => setPagoCuenta(null)}
                onSaved={(updated) => {
                    setPagoCuenta(updated);
                    load();
                }}
            />
        </Layout>
    );
}
