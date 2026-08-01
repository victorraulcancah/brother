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

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const num = (n) => Number(n ?? 0).toLocaleString('es-PE', { maximumFractionDigits: 2 });

const ORIGEN_LABEL = {
    compra: 'Compra',
    venta: 'Venta',
    devolucion: 'Devolución',
    merma: 'Merma',
    transferencia: 'Traslado',
    ajuste_manual: 'Ajuste',
    prestamo: 'Préstamo',
    toma_inventario: 'Toma inventario',
};

const DOC_LABEL = {
    recepcion_compra: 'Recepción',
    ajuste_inventario: 'Ajuste',
    transferencia: 'Traslado',
    prestamo: 'Préstamo',
    toma_inventario: 'Toma',
    nota_venta: 'Venta',
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

    const esEntrada = (row) => row.tipo_movimiento === 'entrada';
    const cantAbs = (row) => Math.abs(Number(row.cantidad ?? 0));

    const columns = [
        { key: 'id', label: '#', render: (row) => <span className="text-gray-500">{row.id}</span> },
        {
            key: 'fecha',
            label: 'Fecha',
            render: (row) => <span className="whitespace-nowrap text-gray-700">{fmtFecha(row.fecha)}</span>,
        },
        {
            key: 'codigo',
            label: 'Código',
            getSearchValue: (row) => row.producto?.codigo,
            render: (row) => row.producto?.codigo ?? <span className="text-gray-400">—</span>,
        },
        {
            key: 'producto',
            label: 'Producto',
            getSearchValue: (row) => row.producto?.nombre,
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <Package className="h-4 w-4 text-primary-600" />
                    {row.producto?.nombre ?? '—'}
                </span>
            ),
        },
        {
            key: 'proveedor',
            label: 'Proveedor',
            getSearchValue: (row) => row.proveedor_nombre,
            render: (row) => row.proveedor_nombre ?? <span className="text-gray-400">—</span>,
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
            key: 'origen',
            label: 'Mov.',
            render: (row) => <Badge variant="gray">{ORIGEN_LABEL[row.origen] ?? row.origen ?? '—'}</Badge>,
        },
        {
            key: 'documento',
            label: 'Documento',
            searchable: false,
            render: (row) =>
                row.documento_referencia_tipo ? (
                    <span className="whitespace-nowrap text-gray-600">
                        {DOC_LABEL[row.documento_referencia_tipo] ?? row.documento_referencia_tipo}
                        {row.documento_referencia_id ? ` #${row.documento_referencia_id}` : ''}
                    </span>
                ) : (
                    <span className="text-gray-400">—</span>
                ),
        },
        {
            key: 'unidad',
            label: 'Unidad',
            searchable: false,
            render: (row) =>
                row.producto?.unidad_base?.abreviatura ??
                row.producto?.unidad_base?.nombre ?? <span className="text-gray-400">—</span>,
        },
        {
            key: 'cantidad',
            label: 'Cantidad',
            align: 'right',
            render: (row) => <span className="text-gray-700">{num(cantAbs(row))}</span>,
        },
        {
            key: 'costo_anterior',
            label: 'Costo Anterior',
            align: 'right',
            searchable: false,
            render: (row) => <span className="text-gray-600">{money(row.costo_anterior)}</span>,
        },
        {
            key: 'costo_actual',
            label: 'Costo Actual',
            align: 'right',
            searchable: false,
            render: (row) => <span className="text-gray-700">{money(row.costo_actual)}</span>,
        },
        {
            key: 'stock_anterior',
            label: 'Stock Anterior',
            align: 'right',
            searchable: false,
            render: (row) => <span className="text-gray-600">{num(row.stock_anterior)}</span>,
        },
        {
            key: 'ingreso',
            label: 'Cant. Ingreso',
            align: 'right',
            searchable: false,
            render: (row) =>
                esEntrada(row) ? (
                    <span className="font-semibold text-green-600">+{num(cantAbs(row))}</span>
                ) : (
                    <span className="text-gray-300">—</span>
                ),
        },
        {
            key: 'salida',
            label: 'Cant. Salida',
            align: 'right',
            searchable: false,
            render: (row) =>
                !esEntrada(row) ? (
                    <span className="font-semibold text-red-600">−{num(cantAbs(row))}</span>
                ) : (
                    <span className="text-gray-300">—</span>
                ),
        },
        {
            key: 'saldo_stock',
            label: 'Stock Actual',
            align: 'right',
            searchable: false,
            render: (row) => <span className="font-medium text-gray-900">{num(row.saldo_stock)}</span>,
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
