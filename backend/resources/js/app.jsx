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

createRoot(document.getElementById('root')).render(
    <StrictMode>
        <BrowserRouter>
            <ToastProvider>
                <AuthProvider>
                    <Routes>
                    <Route path="/login" element={<Login />} />
                    <Route
                        path="/dashboard"
                        element={
                            <ProtectedRoute>
                                <Dashboard />
                            </ProtectedRoute>
                        }
                    />
                    <Route
                        path="/roles"
                        element={
                            <ProtectedRoute>
                                <Roles />
                            </ProtectedRoute>
                        }
                    />
                    <Route
                        path="/usuarios"
                        element={
                            <ProtectedRoute>
                                <Usuarios />
                            </ProtectedRoute>
                        }
                    />
                    <Route
                        path="/empresa"
                        element={
                            <ProtectedRoute>
                                <Empresa />
                            </ProtectedRoute>
                        }
                    />
                        <Route path="*" element={<Login />} />
                    </Routes>
                </AuthProvider>
            </ToastProvider>
        </BrowserRouter>
    </StrictMode>,
);
