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
                        <Route path="*" element={<Login />} />
                    </Routes>
                </AuthProvider>
            </ToastProvider>
        </BrowserRouter>
    </StrictMode>,
);
