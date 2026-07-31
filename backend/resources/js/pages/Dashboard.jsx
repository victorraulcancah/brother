import { useState } from 'react';
import { Edit, Trash2 } from 'lucide-react';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Button, Card, Badge, DataTable, Select } from '../components/ui';
import { useAuth } from '../lib/auth';

const sampleProducts = [
    { id: 1, codigo: 'P001', nombre: 'Leche Gloria 1L', categoria: 'Lácteos', marca: 'Gloria', precio: 5.5, stock: 120 },
    { id: 2, codigo: 'P002', nombre: 'Arroz Costeño 5kg', categoria: 'Abarrotes', marca: 'Costeño', precio: 18.9, stock: 45 },
    { id: 3, codigo: 'P003', nombre: 'Aceite Primor 1L', categoria: 'Abarrotes', marca: 'Primor', precio: 12.5, stock: 0 },
    { id: 4, codigo: 'P004', nombre: 'Azúcar Rubia 1kg', categoria: 'Abarrotes', marca: 'Nativa', precio: 4.2, stock: 80 },
    { id: 5, codigo: 'P005', nombre: 'Fideos Don Vittorio 500g', categoria: 'Abarrotes', marca: 'Don Vittorio', precio: 3.8, stock: 200 },
    { id: 6, codigo: 'P006', nombre: 'Yogurt Gloria 900g', categoria: 'Lácteos', marca: 'Gloria', precio: 7.2, stock: 34 },
];

const productColumns = [
    { key: 'codigo', label: 'Código' },
    { key: 'nombre', label: 'Producto' },
    { key: 'categoria', label: 'Categoría' },
    { key: 'marca', label: 'Marca' },
    {
        key: 'precio',
        label: 'Precio',
        align: 'right',
        render: (row) => `S/ ${row.precio.toFixed(2)}`,
    },
    {
        key: 'stock',
        label: 'Stock',
        align: 'right',
        render: (row) =>
            row.stock === 0 ? (
                <Badge variant="red">Agotado</Badge>
            ) : row.stock < 50 ? (
                <Badge variant="amber">{row.stock}</Badge>
            ) : (
                <Badge variant="green">{row.stock}</Badge>
            ),
    },
    {
        type: 'actions',
        key: 'actions',
        label: 'Acciones',
        actions: () => (
            <>
                <button
                    aria-label="Editar"
                    className="rounded-md p-1.5 text-gray-500 transition hover:bg-primary-50 hover:text-primary-700"
                >
                    <Edit className="h-4 w-4" />
                </button>
                <button
                    aria-label="Eliminar"
                    className="rounded-md p-1.5 text-gray-500 transition hover:bg-red-50 hover:text-red-600"
                >
                    <Trash2 className="h-4 w-4" />
                </button>
            </>
        ),
    },
];

export default function Dashboard() {
    const { user } = useAuth();
    const [filterCategoria, setFilterCategoria] = useState('');
    const [activeFilters, setActiveFilters] = useState({});

    const applyFilters = () => {
        const next = {};
        if (filterCategoria) next.categoria = filterCategoria;
        setActiveFilters(next);
    };

    const clearFilters = () => {
        setFilterCategoria('');
        setActiveFilters({});
    };

    const filteredProducts = sampleProducts.filter(
        (p) => !activeFilters.categoria || p.categoria === activeFilters.categoria,
    );

    const filterCount = Object.keys(activeFilters).length;

    const productFilters = (
        <div className="flex flex-wrap items-end gap-3">
            <Select
                label="Categoría"
                value={filterCategoria}
                onChange={(e) => setFilterCategoria(e.target.value)}
                options={[
                    { value: '', label: 'Todas' },
                    { value: 'Lácteos', label: 'Lácteos' },
                    { value: 'Abarrotes', label: 'Abarrotes' },
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

    return (
        <Layout>
            <PageHeader
                title="Escritorio"
                description="Resumen general del sistema"
                actions={<CreateButton>Nuevo producto</CreateButton>}
            />

            <div className="mb-6 grid gap-4 sm:grid-cols-3">
                <Card className="text-center">
                    <p className="text-sm text-gray-500">Rol</p>
                    <div className="mt-2">
                        <Badge variant="blue">{user?.roles?.[0]?.name ?? 'Sin rol'}</Badge>
                    </div>
                </Card>
                <Card className="text-center">
                    <p className="text-sm text-gray-500">Empresa</p>
                    <p className="mt-2 text-sm font-medium text-warm-900">
                        {user?.empresa?.nombre ?? '—'}
                    </p>
                </Card>
                <Card className="text-center">
                    <p className="text-sm text-gray-500">Estado</p>
                    <p className="mt-2 text-sm font-medium text-warm-900">Activo</p>
                </Card>
            </div>

            <DataTable
                columns={productColumns}
                rows={filteredProducts}
                searchPlaceholder="Buscar productos..."
                filterable
                filters={productFilters}
                filterCount={filterCount}
            />
        </Layout>
    );
}
