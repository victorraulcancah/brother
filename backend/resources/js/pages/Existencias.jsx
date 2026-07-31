import { useCallback, useEffect, useState } from 'react';
import { Package, Store } from 'lucide-react';
import api, { asList } from '../lib/api';
import Layout from '../components/Layout';
import PageHeader from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Select, Tabs } from '../components/ui';

export default function Existencias() {
    const [tab, setTab] = useState('todos');

    const [almacenes, setAlmacenes] = useState([]);
    const [existencias, setExistencias] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const [filterStock, setFilterStock] = useState('');
    const [activeFilters, setActiveFilters] = useState({});

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const [almacenesRes, existenciasRes] = await Promise.all([
                api.get('/almacenes'),
                api.get('/existencias'),
            ]);
            setAlmacenes(asList(almacenesRes));
            setExistencias(asList(existenciasRes));
        } catch {
            setError('No se pudieron cargar las existencias.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    const applyFilters = () => {
        const next = {};
        if (filterStock) next.stock = filterStock;
        setActiveFilters(next);
    };

    const clearFilters = () => {
        setFilterStock('');
        setActiveFilters({});
    };

    const stockInfo = (row) => {
        const stock = Number(row.stock_actual ?? 0);
        const minimo = Number(row.stock_minimo ?? 0);
        const abrev = row.producto?.unidad_base?.abreviatura ?? '';
        const text = `${stock} ${abrev}`.trim();
        return { stock, minimo, text };
    };

    const stockBadge = (row) => {
        const { stock, minimo, text } = stockInfo(row);
        if (stock <= 0) return <Badge variant="red">{text}</Badge>;
        if (stock <= minimo) return <Badge variant="amber">{text}</Badge>;
        return <Badge variant="green">{text}</Badge>;
    };

    const rowsFor = (almacenId) => {
        const rows = almacenId
            ? existencias.filter(
                  (e) =>
                      e.almacen_id === almacenId || e.almacen?.id === almacenId,
              )
            : existencias;
        return rows.filter((row) => {
            const { stock, minimo } = stockInfo(row);
            if (activeFilters.stock === 'sin') return stock <= 0;
            if (activeFilters.stock === 'bajo') return stock > 0 && stock <= minimo;
            if (activeFilters.stock === 'normal') return stock > minimo;
            return true;
        });
    };

    const filterCount = Object.keys(activeFilters).length;

    const filters = (
        <div className="flex flex-wrap items-end gap-3">
            <Select
                label="Stock"
                value={filterStock}
                onChange={(e) => setFilterStock(e.target.value)}
                options={[
                    { value: '', label: 'Todos' },
                    { value: 'sin', label: 'Sin stock' },
                    { value: 'bajo', label: 'Bajo stock (≤ mínimo)' },
                    { value: 'normal', label: 'Stock normal' },
                ]}
                className="w-52"
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
            key: 'codigo',
            label: 'Código',
            render: (row) => (
                <Badge variant="blue">{row.producto?.codigo ?? '—'}</Badge>
            ),
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
            key: 'categoria',
            label: 'Categoría',
            render: (row) => (
                <Badge variant="gray">{row.producto?.categoria?.nombre ?? '—'}</Badge>
            ),
        },
        {
            key: 'stock_actual',
            label: 'Stock (unidad base)',
            render: stockBadge,
        },
        {
            key: 'precio',
            label: 'Precio venta',
            align: 'right',
            render: (row) =>
                row.producto?.precio_base != null
                    ? `S/ ${Number(row.producto.precio_base).toFixed(2)}`
                    : '—',
        },
    ];

    const tabItems = [
        { key: 'todos', label: 'Todos', icon: Store },
        ...almacenes.map((a) => ({
            key: String(a.id),
            label: a.nombre,
            icon: Store,
        })),
    ];

    return (
        <Layout>
            <PageHeader
                title="Existencias"
                description="Consulta el stock de productos por almacén"
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <div className="mb-4">
                <Tabs items={tabItems} value={tab} onChange={setTab} />
            </div>

            <DataTable
                columns={columns}
                rows={rowsFor(tab === 'todos' ? null : Number(tab))}
                loading={loading}
                searchPlaceholder="Buscar existencias..."
                filterable
                filters={filters}
                filterCount={filterCount}
                emptyMessage="Sin existencias en este almacén"
            />
        </Layout>
    );
}
