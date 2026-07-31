import { useState } from 'react';
import { useNavigate, useLocation, Link } from 'react-router-dom';
import { Button, Input, Alert } from '../components/ui';
import { useAuth } from '../lib/auth';

export default function Login() {
    const { login } = useAuth();
    const navigate = useNavigate();
    const location = useLocation();
    const [form, setForm] = useState({ email: '', password: '' });
    const [errors, setErrors] = useState({});
    const [formError, setFormError] = useState(null);
    const [loading, setLoading] = useState(false);

    const from = location.state?.from?.pathname || '/dashboard';

    const handleChange = (e) => {
        const { name, value } = e.target;
        setForm((prev) => ({ ...prev, [name]: value }));
        if (errors[name]) {
            setErrors((prev) => ({ ...prev, [name]: undefined }));
        }
        setFormError(null);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setFormError(null);

        const newErrors = {};
        if (!form.email.trim()) newErrors.email = 'El correo es obligatorio';
        if (!form.password) newErrors.password = 'La contraseña es obligatoria';

        if (Object.keys(newErrors).length) {
            setErrors(newErrors);
            setLoading(false);
            return;
        }

        try {
            await login(form.email.trim(), form.password);
            navigate(from, { replace: true });
        } catch (err) {
            const status = err.response?.status;
            if (status === 401) {
                setFormError('Credenciales inválidas. Verifica tu correo y contraseña.');
            } else if (status === 422) {
                const validation = err.response.data?.errors ?? {};
                setErrors(Object.fromEntries(Object.entries(validation).map(([k, v]) => [k, v[0]])));
            } else {
                setFormError('No se pudo conectar con el servidor. Inténtalo de nuevo.');
            }
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="flex min-h-screen items-center justify-center bg-cream px-4 py-12">
            <div className="w-full max-w-md">
                <div className="mb-8 text-center">
                    <img
                        src="/images/brava-horizontal.png"
                        alt="BRAVA"
                        className="mx-auto h-14 w-auto"
                    />
                    <p className="mt-4 text-sm text-warm-500">
                        Ingresa a tu cuenta para continuar
                    </p>
                </div>

                <div className="rounded-lg border border-edge bg-white p-6 shadow-sm sm:p-8">
                    {formError && (
                        <Alert variant="error" className="mb-4">
                            {formError}
                        </Alert>
                    )}

                    <form onSubmit={handleSubmit} className="space-y-4" noValidate>
                        <Input
                            label="Correo electrónico"
                            name="email"
                            type="email"
                            autoComplete="email"
                            placeholder="tucorreo@empresa.com"
                            value={form.email}
                            onChange={handleChange}
                            error={errors.email}
                        />
                        <Input
                            label="Contraseña"
                            name="password"
                            type="password"
                            autoComplete="current-password"
                            placeholder="••••••••"
                            value={form.password}
                            onChange={handleChange}
                            error={errors.password}
                        />
                        <Button
                            type="submit"
                            size="lg"
                            loading={loading}
                            className="w-full"
                        >
                            {loading ? 'Ingresando...' : 'Iniciar sesión'}
                        </Button>
                    </form>

                    <p className="mt-6 text-center text-sm text-gray-500">
                        ¿No tienes cuenta?{' '}
                        <Link to="/registro" className="font-medium text-primary-600 hover:text-primary-700">
                            Regístrate
                        </Link>
                    </p>
                </div>
            </div>
        </div>
    );
}
