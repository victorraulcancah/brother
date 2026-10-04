import { useEffect, useState } from 'react';
import { useNavigate, useLocation, Link } from 'react-router-dom';
import { Eye, EyeOff, Loader2, Lock, Mail } from 'lucide-react';
import ModulosCarrusel from '../components/ModulosCarrusel';
import { cn } from '../components/ui';
import { useAuth } from '../lib/auth';

const REMEMBER_KEY = 'brava_remember';

/** Entrada con ícono a la izquierda y, opcionalmente, un control a la derecha (ver contraseña). */
function Campo({ id, label, icon: Icon, error, trailing, ...props }) {
    return (
        <div>
            <label htmlFor={id} className="mb-2 block text-[13px] font-semibold text-slate-700">
                {label}
            </label>
            <div className="relative">
                <Icon
                    className="pointer-events-none absolute left-3.5 top-1/2 h-[18px] w-[18px] -translate-y-1/2 text-slate-500"
                    aria-hidden="true"
                />
                <input
                    id={id}
                    aria-invalid={Boolean(error)}
                    aria-describedby={error ? `${id}-error` : undefined}
                    className={cn(
                        'h-12 w-full rounded-xl border bg-white pl-11 pr-11 text-[15px] text-slate-900 caret-primary-600 outline-none transition',
                        'placeholder:text-slate-500 focus:ring-4',
                        // El autocompletado del navegador pinta su propio fondo claro: se le da el del campo.
                        '[&:-webkit-autofill]:shadow-[inset_0_0_0_1000px_#ffffff] [&:-webkit-autofill]:[-webkit-text-fill-color:#0f172a]',
                        error
                            ? 'border-red-500 focus:border-red-500 focus:ring-red-500/20'
                            : 'border-slate-300 hover:border-slate-400 focus:border-primary-600 focus:ring-primary-600/20',
                    )}
                    {...props}
                />
                {trailing}
            </div>
            {error && (
                <p id={`${id}-error`} className="mt-1.5 text-xs text-red-600">
                    {error}
                </p>
            )}
        </div>
    );
}

/** Espiga de arroz de la marca: tallo, tres pares de granos y el de la punta. */
function EspigaMark({ className }) {
    const pares = [
        { y: 46, largo: 15 },
        { y: 37, largo: 14 },
        { y: 28, largo: 13 },
    ];
    const abrir = 42; // grados respecto a la vertical

    return (
        <svg viewBox="0 0 64 64" className={className} aria-hidden="true" fill="currentColor">
            <rect x="31" y="24" width="2" height="30" rx="1" />
            {pares.map(({ y, largo }) =>
                [1, -1].map((lado) => {
                    const a = (abrir * Math.PI) / 180;
                    const cx = 32 + lado * Math.sin(a) * (largo / 2);
                    const cy = y - Math.cos(a) * (largo / 2);
                    return (
                        <ellipse
                            key={`${y}-${lado}`}
                            cx={cx}
                            cy={cy}
                            rx={largo / 2}
                            ry={3.3}
                            transform={`rotate(${-90 + lado * abrir} ${cx} ${cy})`}
                            stroke="#3b6cf0"
                            strokeWidth="1.3"
                        />
                    );
                }),
            )}
            <ellipse cx="32" cy="19" rx="3.3" ry="7.2" stroke="#3b6cf0" strokeWidth="1.3" />
        </svg>
    );
}

/** Granos de arroz en contorno, repetidos en diagonal: la textura del panel de marca. */
function FondoGranos() {
    return (
        <svg
            className="pointer-events-none absolute inset-0 -z-10 h-full w-full text-white opacity-[0.07]"
            aria-hidden="true"
        >
            <defs>
                <pattern id="granos" width="64" height="64" patternUnits="userSpaceOnUse">
                    <g transform="rotate(-38 16 16)" fill="none" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round">
                        <ellipse cx="16" cy="16" rx="10" ry="4.2" />
                        <path d="M8 16h16" />
                    </g>
                    <g transform="rotate(-38 48 48)" fill="none" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round">
                        <ellipse cx="48" cy="48" rx="10" ry="4.2" />
                        <path d="M40 48h16" />
                    </g>
                </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#granos)" />
        </svg>
    );
}

export default function Login() {
    const { login } = useAuth();
    const navigate = useNavigate();
    const location = useLocation();

    const [form, setForm] = useState(() => {
        const saved = localStorage.getItem(REMEMBER_KEY);
        if (saved) {
            try {
                return JSON.parse(saved);
            } catch {
                /* ignore */
            }
        }
        return { email: '', password: '' };
    });
    const [remember, setRemember] = useState(() => Boolean(localStorage.getItem(REMEMBER_KEY)));
    const [showPassword, setShowPassword] = useState(false);
    const [errors, setErrors] = useState({});
    const [formError, setFormError] = useState(null);
    const [loading, setLoading] = useState(false);

    const from = location.state?.from?.pathname || '/dashboard';

    useEffect(() => {
        if (remember) {
            localStorage.setItem(REMEMBER_KEY, JSON.stringify(form));
        } else {
            localStorage.removeItem(REMEMBER_KEY);
        }
    }, [form, remember]);

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
        <div className="grid min-h-dvh bg-slate-50 font-display text-white selection:bg-primary-500/40 lg:grid-cols-[1.04fr_1fr]">
            {/* Panel de marca */}
            <section className="relative isolate flex flex-col overflow-hidden bg-[linear-gradient(160deg,#0a1a52_0%,#0b1f5c_55%,#0e2a7e_100%)] px-6 pb-8 pt-7 sm:px-10 lg:min-h-dvh lg:px-14 lg:py-12">
                <FondoGranos />
                <div
                    className="pointer-events-none absolute inset-0 -z-10 bg-[radial-gradient(70%_55%_at_0%_100%,rgba(37,99,235,0.55),transparent_70%)]"
                    aria-hidden="true"
                />

                <div className="flex items-center gap-3">
                    <span className="grid h-10 w-10 place-items-center rounded-xl bg-primary-500 shadow-[0_8px_20px_-6px_rgba(59,130,246,0.7)]">
                        <EspigaMark className="h-6 w-6 text-white" />
                    </span>
                    <span>
                        <span className="block text-[22px] font-extrabold leading-none tracking-wide">BRAVA</span>
                        <span className="mt-1 block text-[11px] font-medium leading-none text-blue-200/80">
                            Distribuidora de arroz
                        </span>
                    </span>
                </div>

                {/* En celular el panel es una banda con el titular; en escritorio el titular lo
                    llevan los módulos del carrusel y este queda solo para lectores de pantalla. */}
                <h1 className="max-w-[30rem] animate-[login-in_0.7s_cubic-bezier(0.16,1,0.3,1)] text-[1.75rem] font-extrabold leading-[1.08] tracking-[-0.015em] motion-reduce:animate-none max-lg:mt-8 sm:text-4xl lg:sr-only">
                    Del molino a tu almacén, todo en un solo lugar.
                </h1>

                <ModulosCarrusel className="hidden w-full max-w-[36rem] lg:m-auto lg:block" />
            </section>

            {/* Formulario */}
            <main className="flex items-center justify-center bg-slate-50 px-6 py-10 text-slate-900 [color-scheme:light] sm:px-10 lg:py-12">
                <div className="w-full max-w-[22.5rem] animate-[login-in_0.7s_cubic-bezier(0.16,1,0.3,1)_0.08s_backwards] motion-reduce:animate-none">
                    <div className="flex flex-col items-center text-center">
                        <span className="text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-500">
                            Desarrollado por
                        </span>
                        {/* El logo se entregó sobre fondo negro: el marco circular lo conserva tal cual. */}
                        <span className="mt-3 grid h-36 w-36 place-items-center overflow-hidden rounded-full bg-black shadow-[0_14px_32px_-14px_rgba(37,99,235,0.55)] ring-4 ring-primary-600">
                            <img
                                src="/images/brintech-oscuro.jpg"
                                alt="BRINTECH Technology Consulting"
                                className="h-[74%] w-auto"
                            />
                        </span>
                        <h2 className="mt-6 text-[1.75rem] font-extrabold leading-tight tracking-[-0.015em] text-slate-900">
                            Bienvenido de nuevo
                        </h2>
                        <p className="mt-1.5 text-[15px] text-slate-500">Ingresa a tu cuenta para continuar.</p>
                    </div>

                    {formError && (
                        <div
                            role="alert"
                            className="mt-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
                        >
                            {formError}
                        </div>
                    )}

                    <form onSubmit={handleSubmit} className="mt-8 space-y-5" noValidate>
                        <Campo
                            id="email"
                            name="email"
                            type="email"
                            label="Correo electrónico"
                            icon={Mail}
                            autoComplete="email"
                            placeholder="tucorreo@empresa.com"
                            value={form.email}
                            onChange={handleChange}
                            error={errors.email}
                        />

                        <Campo
                            id="password"
                            name="password"
                            type={showPassword ? 'text' : 'password'}
                            label="Contraseña"
                            icon={Lock}
                            autoComplete={showPassword ? 'off' : 'current-password'}
                            placeholder="Tu contraseña"
                            value={form.password}
                            onChange={handleChange}
                            error={errors.password}
                            trailing={
                                <button
                                    type="button"
                                    onClick={() => setShowPassword((v) => !v)}
                                    aria-label={showPassword ? 'Ocultar contraseña' : 'Ver contraseña'}
                                    aria-pressed={showPassword}
                                    className="absolute right-0.5 top-1/2 grid h-11 w-11 -translate-y-1/2 place-items-center rounded-xl text-slate-500 transition hover:text-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-600"
                                >
                                    {showPassword ? (
                                        <EyeOff className="h-[18px] w-[18px]" />
                                    ) : (
                                        <Eye className="h-[18px] w-[18px]" />
                                    )}
                                </button>
                            }
                        />

                        <div className="flex items-center justify-between gap-3">
                            <label className="flex min-h-11 cursor-pointer select-none items-center gap-2.5 text-[13px] font-medium text-slate-700">
                                <input
                                    type="checkbox"
                                    checked={remember}
                                    onChange={(e) => setRemember(e.target.checked)}
                                    className="h-[18px] w-[18px] shrink-0 cursor-pointer appearance-none rounded-md border border-slate-400 bg-white transition checked:border-primary-500 checked:bg-primary-500 check-brava focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-600"
                                />
                                Recordarme
                            </label>
                            <Link
                                to="/recuperar"
                                className="inline-flex min-h-11 items-center rounded text-[13px] font-semibold text-primary-600 transition hover:text-primary-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-600"
                            >
                                ¿Olvidaste tu contraseña?
                            </Link>
                        </div>

                        <button
                            type="submit"
                            disabled={loading}
                            className="flex h-12 w-full items-center justify-center gap-2 rounded-xl bg-[#2f6df0] text-[15px] font-bold text-white shadow-[0_10px_24px_-10px_rgba(37,99,235,0.6)] transition hover:bg-primary-600 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-600 active:translate-y-px disabled:cursor-not-allowed disabled:opacity-70"
                        >
                            {loading && <Loader2 className="h-4 w-4 animate-spin" aria-hidden="true" />}
                            {loading ? 'Ingresando...' : 'Iniciar sesión'}
                        </button>
                    </form>

                    <p className="mt-3 flex min-h-11 flex-wrap items-center justify-center gap-x-1 text-center text-[13px] text-slate-500">
                        ¿No tienes cuenta?
                        <Link
                            to="/registro"
                            className="inline-flex min-h-11 items-center rounded px-0.5 font-semibold text-primary-600 transition hover:text-primary-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-600"
                        >
                            Regístrate
                        </Link>
                    </p>
                </div>
            </main>
        </div>
    );
}
