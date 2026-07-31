import {
    Home,
    SlidersHorizontal,
    Shield,
    Users,
    Building2,
    BookOpen,
    Package,
    Tags,
    BadgeDollarSign,
    Ruler,
    ShoppingCart,
    Truck,
    FileText,
    FilePlus2,
    PackageCheck,
    Warehouse,
    ArrowLeftRight,
    ClipboardCheck,
} from 'lucide-react';

export const navigation = [
    { label: 'Inicio', icon: Home, to: '/dashboard' },
    {
        label: 'Gestión',
        icon: SlidersHorizontal,
        children: [
            { label: 'Roles', icon: Shield, to: '/roles' },
            { label: 'Usuarios', icon: Users, to: '/usuarios' },
            { label: 'Empresa', icon: Building2, to: '/empresa' },
        ],
    },
    {
        label: 'Catálogo',
        icon: BookOpen,
        children: [
            { label: 'Productos', icon: Package, to: '/productos' },
            { label: 'Categorías', icon: Tags, to: '/categorias' },
            { label: 'Marcas', icon: BadgeDollarSign, to: '/marcas' },
            { label: 'Sub-marcas', icon: BadgeDollarSign, to: '/sub-marcas' },
            { label: 'Unidades de medida', icon: Ruler, to: '/unidades-medida' },
        ],
    },
    {
        label: 'Compras',
        icon: ShoppingCart,
        children: [
            { label: 'Proveedores', icon: Truck, to: '/proveedores' },
            { label: 'Órdenes de compra', icon: FileText, to: '/ordenes-compra' },
            { label: 'Solicitudes de compra', icon: FilePlus2, to: '/solicitudes-compra' },
            { label: 'Recepciones de compra', icon: PackageCheck, to: '/recepciones-compra' },
        ],
    },
    {
        label: 'Inventario',
        icon: Warehouse,
        children: [
            { label: 'Existencias', icon: Warehouse, to: '/existencias' },
            { label: 'Movimientos', icon: ArrowLeftRight, to: '/movimientos' },
            { label: 'Tomas de inventario', icon: ClipboardCheck, to: '/tomas-inventario' },
        ],
    },
];
