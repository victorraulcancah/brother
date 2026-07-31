import { useCallback, useEffect, useState } from 'react';
import { ArrowDownLeft, ArrowRightLeft, ArrowUpRight, Package } from 'lucide-react';
import api, { asList } from '../lib/api';
import Layout from '../components/Layout';
import PageHeader from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Select } from '../components/ui';

const fmtFecha = (value) =>
    value
        ? new Date(value).toLocaleString('es-PE', {
              day: '2-digit',
              month: 'short',
              year: 'numeric',
              hour: '2-digit',
              minute: '2-digit',
          })
        : '—';

const tipoInfo = (tipo) => {
    if (tipo === 'entrada') return { label: 'Entrada', variant: 'green', icon: ArrowDownLeft };
    if (tipo === 'salida') return { label: 'Salida', variant: 'red', icon: ArrowUpRight };
    return { label: tipo ?? '—', variant: 'gray', icon: ArrowRightLeft };
};

export default function Movimientos() {
    const [movimientos, setMovimientos] = useState([]);
    const [almacenes, setAlmacenes] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const [filterTipo, setFilterTipo] = useState('');
    const [filterAlmacen, setFilterAlmacen] = useState('');
    const [activeFilters, setActiveFilters] = useState({});

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const [movRes, almRes] = await Promise.all([
                api.get('/movimientos'),
                api.get('/almacenes'),
            ]);
            setMovimientos(asList(movRes));
            setAlmacenes(asList(almRes));
        } catch {
            setError('No se pudieron cargar los movimientos.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    const applyFilters = () => {
        const next = {};
        if (filterTipo) next.tipo = filterTipo;
        if (filterAlmacen) next.almacen = filterAlmacen;
        setActiveFilters(next);
    };

    const clearFilters = () => {
        setFilterTipo('');
        setFilterAlmacen('');
        setActiveFilters({});
    };

    const filtered = movimientos.filter((m) => {
        if (activeFilters.tipo && m.tipo_movimiento !== activeFilters.tipo) return false;
        if (activeFilters.almacen) {
            const id = m.almacen_id ?? m.almacen?.id;
            if (String(id) !== activeFilters.almacen) return false;
        }
        return true;
    });

    const filterCount = Object.keys(activeFilters).length;

    const filters = (
        <div className="flex flex-wrap items-end gap-3">
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
            key: 'fecha',
            label: 'Fecha',
            render: (row) => <span className="whitespace-nowrap text-gray-700">{fmtFecha(row.fecha)}</span>,
        },
        {
            key: 'tipo_movimiento',
            label: 'Tipo',
            render: (row) => {
                const { label, variant, icon: Icon } = tipoInfo(row.tipo_movimiento);
                return (
                    <Badge variant={variant}>
                        <Icon className="mr-1 h-3 w-3" />
                        {label}
                    </Badge>
                );
            },
        },
        {
            key: 'producto',
            label: 'Producto',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <Package className="h-4 w-4 text-primary-600" />
                    {row.producto?.nombre ?? '—'}
                </span>
            ),
        },
        {
            key: 'almacen',
            label: 'Almacén',
            render: (row) => <Badge variant="blue">{row.almacen?.nombre ?? '—'}</Badge>,
        },
        {
            key: 'cantidad',
            label: 'Cantidad',
            align: 'right',
            render: (row) => {
                const cantidad = Number(row.cantidad ?? 0);
                return (
                    <span className={`font-semibold ${row.tipo_movimiento === 'salida' ? 'text-red-600' : 'text-green-600'}`}>
                        {row.tipo_movimiento === 'salida' ? '−' : '+'}{cantidad}
                    </span>
                );
            },
        },
        {
            key: 'saldo_stock',
            label: 'Saldo stock',
            align: 'right',
            render: (row) => <span className="text-gray-700">{Number(row.saldo_stock ?? 0)}</span>,
        },
        {
            key: 'origen',
            label: 'Origen',
            render: (row) => <Badge variant="gray">{row.origen ?? '—'}</Badge>,
        },
    ];

    return (
        <Layout>
            <PageHeader
                title="Movimientos"
                description="Historial de entradas y salidas de inventario"
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable
                columns={columns}
                rows={filtered}
                loading={loading}
                searchPlaceholder="Buscar movimientos..."
                filterable
                filters={filters}
                filterCount={filterCount}
            />
        </Layout>
    );
}
