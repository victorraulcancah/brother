import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './lib/auth';
import { ToastProvider } from './lib/toast';
import ProtectedRoute from './components/ProtectedRoute';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Roles from './pages/Roles';
import Usuarios from './pages/Usuarios';
import Empresa from './pages/Empresa';
import Productos from './pages/Productos';
import Categorias from './pages/Categorias';
import Marcas from './pages/Marcas';
import SubMarcas from './pages/SubMarcas';
import UnidadesMedida from './pages/UnidadesMedida';
import Almacenes from './pages/Almacenes';
import Existencias from './pages/Existencias';
import Movimientos from './pages/Movimientos';
import Transferencias from './pages/Transferencias';
import Ajustes from './pages/Ajustes';
import TomasInventario from './pages/TomasInventario';
import Prestamos from './pages/Prestamos';
import Proveedores from './pages/Proveedores';
import SolicitudesCompra from './pages/SolicitudesCompra';
import OrdenesCompra from './pages/OrdenesCompra';
import RecepcionesCompra from './pages/RecepcionesCompra';
import MetodosDePago from './pages/MetodosDePago';
import Cajas from './pages/Cajas';
import MovimientosCaja from './pages/MovimientosCaja';
import CuentasPorCobrar from './pages/CuentasPorCobrar';
import CuentasPorPagar from './pages/CuentasPorPagar';
import EnConstruccion from './pages/EnConstruccion';

const routes = [
    { path: '/dashboard', element: <Dashboard /> },
    { path: '/roles', element: <Roles /> },
    { path: '/usuarios', element: <Usuarios /> },
    { path: '/empresa', element: <Empresa /> },
    { path: '/productos', element: <Productos /> },
    { path: '/categorias', element: <Categorias /> },
    { path: '/marcas', element: <Marcas /> },
    { path: '/sub-marcas', element: <SubMarcas /> },
    { path: '/unidades-medida', element: <UnidadesMedida /> },
    { path: '/almacenes', element: <Almacenes /> },
    { path: '/existencias', element: <Existencias /> },
    { path: '/movimientos', element: <Movimientos /> },
    { path: '/transferencias', element: <Transferencias /> },
    { path: '/ajustes', element: <Ajustes /> },
    { path: '/tomas-inventario', element: <TomasInventario /> },
    { path: '/prestamos', element: <Prestamos /> },
    { path: '/proveedores', element: <Proveedores /> },
    { path: '/solicitudes-compra', element: <SolicitudesCompra /> },
    { path: '/ordenes-compra', element: <OrdenesCompra /> },
    { path: '/recepciones-compra', element: <RecepcionesCompra /> },
    { path: '/metodos-de-pago', element: <MetodosDePago /> },
    { path: '/cajas', element: <Cajas /> },
    { path: '/movimientos-caja', element: <MovimientosCaja /> },
    { path: '/cuentas-por-cobrar', element: <CuentasPorCobrar /> },
    { path: '/cuentas-por-pagar', element: <CuentasPorPagar /> },
];

createRoot(document.getElementById('root')).render(
    <StrictMode>
        <BrowserRouter>
            <ToastProvider>
                <AuthProvider>
                    <Routes>
                    <Route path="/login" element={<Login />} />
                    {routes.map(({ path, element }) => (
                        <Route
                            key={path}
                            path={path}
                            element={<ProtectedRoute>{element}</ProtectedRoute>}
                        />
                    ))}
                        {/* Rutas del menú aún sin página: muestran "En construcción"
                            (con sidebar) en vez de botar al login. Si el usuario no
                            está autenticado, ProtectedRoute lo manda a /login. */}
                        <Route
                            path="*"
                            element={
                                <ProtectedRoute>
                                    <EnConstruccion />
                                </ProtectedRoute>
                            }
                        />
                    </Routes>
                </AuthProvider>
            </ToastProvider>
        </BrowserRouter>
    </StrictMode>,
);
