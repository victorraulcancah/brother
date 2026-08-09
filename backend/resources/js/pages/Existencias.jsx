import { useCallback, useEffect, useState } from 'react';
import { Package, Store } from 'lucide-react';
import api, { asList } from '../lib/api';
import Layout from '../components/Layout';
import PageHeader from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Select, Tabs } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const num = (n) => new Intl.NumberFormat('es-PE', { maximumFractionDigits: 2 }).format(Number(n) || 0);

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
        // El mínimo del almacén manda; si no está definido, se usa el del producto.
        const minimo = Number(row.stock_minimo ?? 0) || Number(row.producto?.stock_minimo ?? 0);
        const maximo = Number(row.stock_maximo ?? 0) || Number(row.producto?.stock_maximo ?? 0);
        return { stock, minimo, maximo };
    };

    const stockBadge = (row) => {
        const { stock, minimo, maximo } = stockInfo(row);
        const texto = num(stock);

        if (stock <= 0) return <Badge variant="red">{texto}</Badge>;
        if (minimo > 0 && stock <= minimo) return <Badge variant="amber">{texto}</Badge>;
        if (maximo > 0 && stock > maximo) return <Badge variant="blue">{texto}</Badge>;
        return <Badge variant="green">{texto}</Badge>;
    };

    const rowsFor = (almacenId) => {
        const rows = almacenId
            ? existencias.filter(
                  (e) =>
                      e.almacen_id === almacenId || e.almacen?.id === almacenId,
              )
            : existencias;
        return rows.filter((row) => {
            const { stock, minimo, maximo } = stockInfo(row);
            if (activeFilters.stock === 'sin') return stock <= 0;
            if (activeFilters.stock === 'bajo') return stock > 0 && minimo > 0 && stock <= minimo;
            if (activeFilters.stock === 'sobre') return maximo > 0 && stock > maximo;
            if (activeFilters.stock === 'normal') return stock > 0 && (minimo <= 0 || stock > minimo);
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
                    { value: 'bajo', label: 'Bajo el mínimo' },
                    { value: 'sobre', label: 'Sobre el máximo' },
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
            width: '110px',
            getSearchValue: (row) => row.producto?.codigo,
            render: (row) => <Badge variant="blue">{row.producto?.codigo ?? '—'}</Badge>,
        },
        {
            key: 'producto',
            label: 'Producto',
            getSearchValue: (row) => row.producto?.nombre,
            render: (row) => (
                <span className="flex items-center gap-2 font-medium text-warm-900">
                    <Package className="h-4 w-4 shrink-0 text-primary-600" />
                    <span className="truncate" title={row.producto?.nombre ?? ''}>
                        {row.producto?.nombre ?? '—'}
                    </span>
                </span>
            ),
        },
        {
            key: 'marca',
            label: 'Marca',
            width: '120px',
            getSearchValue: (row) => row.producto?.marca?.nombre,
            render: (row) => (
                <span className="block truncate text-warm-500">{row.producto?.marca?.nombre ?? '—'}</span>
            ),
        },
        {
            key: 'categoria',
            label: 'Categoría',
            width: '130px',
            getSearchValue: (row) => row.producto?.categoria?.nombre,
            render: (row) => (
                <Badge variant="gray">{row.producto?.categoria?.nombre ?? '—'}</Badge>
            ),
        },
        // El almacén solo aporta cuando se ven todos juntos.
        ...(tab === 'todos'
            ? [
                  {
                      key: 'almacen',
                      label: 'Almacén',
                      width: '140px',
                      getSearchValue: (row) => row.almacen?.nombre,
                      render: (row) => (
                          <span className="block truncate text-warm-500">{row.almacen?.nombre ?? '—'}</span>
                      ),
                  },
              ]
            : []),
        {
            key: 'unidad',
            label: 'Und.',
            width: '70px',
            searchable: false,
            render: (row) => (
                <span className="text-warm-500">
                    {row.producto?.unidad_base?.abreviatura ?? row.producto?.unidad_base?.nombre ?? '—'}
                </span>
            ),
        },
        {
            key: 'stock_actual',
            label: 'Stock',
            width: '90px',
            align: 'right',
            searchable: false,
            render: stockBadge,
        },
        {
            key: 'stock_reservado',
            label: 'Reserv.',
            width: '85px',
            align: 'right',
            searchable: false,
            render: (row) => <span className="text-warm-500">{num(row.stock_reservado)}</span>,
        },
        {
            key: 'stock_disponible',
            label: 'Disp.',
            width: '85px',
            align: 'right',
            searchable: false,
            render: (row) => (
                <span className="font-medium text-warm-900">{num(row.stock_disponible)}</span>
            ),
        },
        {
            key: 'stock_minimo',
            label: 'Mín.',
            width: '75px',
            align: 'right',
            searchable: false,
            render: (row) => <span className="text-warm-500">{num(stockInfo(row).minimo)}</span>,
        },
        {
            key: 'stock_maximo',
            label: 'Máx.',
            width: '75px',
            align: 'right',
            searchable: false,
            render: (row) => <span className="text-warm-500">{num(stockInfo(row).maximo)}</span>,
        },
        {
            key: 'costo_promedio',
            label: 'C. Prom.',
            width: '100px',
            align: 'right',
            searchable: false,
            render: (row) => <span className="text-warm-500">{money(row.costo_promedio)}</span>,
        },
        {
            key: 'valorizado',
            label: 'Valorizado',
            width: '110px',
            align: 'right',
            searchable: false,
            render: (row) => (
                <span className="font-semibold text-primary-600">
                    {money(Number(row.stock_actual ?? 0) * Number(row.costo_promedio ?? 0))}
                </span>
            ),
        },
        {
            key: 'precio',
            label: 'P. Venta',
            width: '100px',
            align: 'right',
            searchable: false,
            render: (row) =>
                row.producto?.precio_base != null ? money(row.producto.precio_base) : '—',
        },
        {
            key: 'ubicacion',
            label: 'Ubic.',
            width: '100px',
            getSearchValue: (row) => row.ubicacion,
            render: (row) => (
                <span className="block truncate text-warm-500">{row.ubicacion ?? '—'}</span>
            ),
        },
    ];

    const visibles = rowsFor(tab === 'todos' ? null : Number(tab));

    const resumen = visibles.reduce(
        (acc, row) => {
            const { stock, minimo } = stockInfo(row);
            acc.items += 1;
            if (stock <= 0) acc.sinStock += 1;
            else if (minimo > 0 && stock <= minimo) acc.bajoMinimo += 1;
            acc.valorizado += stock * Number(row.costo_promedio ?? 0);
            return acc;
        },
        { items: 0, sinStock: 0, bajoMinimo: 0, valorizado: 0 },
    );

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

            {/* Resumen de lo que se está viendo */}
            <div className="mb-4 grid grid-cols-2 gap-3 lg:grid-cols-4">
                {[
                    { label: 'Productos', valor: resumen.items, tono: 'text-warm-900' },
                    { label: 'Sin stock', valor: resumen.sinStock, tono: 'text-red-600' },
                    { label: 'Bajo el mínimo', valor: resumen.bajoMinimo, tono: 'text-amber-600' },
                    { label: 'Valorizado', valor: money(resumen.valorizado), tono: 'text-primary-600' },
                ].map((c) => (
                    <div key={c.label} className="rounded-xl border border-edge bg-white p-4 shadow-sm">
                        <p className="text-xs font-semibold uppercase tracking-wide text-warm-500">{c.label}</p>
                        <p className={`mt-1 text-xl font-bold ${c.tono}`}>{c.valor}</p>
                    </div>
                ))}
            </div>

            <DataTable
                columns={columns}
                rows={visibles}
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
