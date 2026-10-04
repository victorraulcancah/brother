import { useEffect, useRef, useState } from 'react';
import { ChevronDown, ChevronsUpDown, LogOut } from 'lucide-react';
import { useAuth } from '../lib/auth';
import { cn } from './ui';

function Avatar({ user, size = 'md' }) {
    const initials = (user?.name ?? '?')
        .split(' ')
        .map((p) => p[0])
        .slice(0, 2)
        .join('')
        .toUpperCase();

    return (
        <div
            className={cn(
                'flex shrink-0 items-center justify-center rounded-full bg-primary-600 font-semibold text-white',
                size === 'md' ? 'h-9 w-9 text-xs' : 'h-8 w-8 text-[10px]',
            )}
        >
            {initials}
        </div>
    );
}

/**
 * Menú del usuario. `variant="topbar"` es la versión de la barra superior (junto a la
 * campana): botón en forma de píldora y menú que se abre hacia abajo. La variante por
 * defecto es la del pie del menú lateral.
 */
export default function UserMenu({ compact = false, variant = 'sidebar' }) {
    const { user, logout } = useAuth();
    const [open, setOpen] = useState(false);
    const menuRef = useRef(null);

    useEffect(() => {
        const handler = (e) => {
            if (menuRef.current && !menuRef.current.contains(e.target)) {
                setOpen(false);
            }
        };
        document.addEventListener('mousedown', handler);
        return () => document.removeEventListener('mousedown', handler);
    }, []);

    if (variant === 'topbar') {
        return (
            <div ref={menuRef} className="relative">
                <button
                    onClick={() => setOpen((v) => !v)}
                    aria-haspopup="menu"
                    aria-expanded={open}
                    aria-label={`Menú de ${user?.name ?? 'usuario'}`}
                    className="flex h-10 items-center gap-2.5 rounded-full border border-edge bg-white p-0.5 shadow-sm transition hover:bg-primary-50 lg:pr-3"
                >
                    <Avatar user={user} size="md" />
                    {/* Con poco ancho solo se ve la inicial: el nombre y el correo no caben. */}
                    <span className="hidden min-w-0 text-left lg:block">
                        <span className="block max-w-[11rem] truncate text-[13px] font-semibold leading-tight text-gray-900">
                            {user?.name}
                        </span>
                        <span className="block max-w-[11rem] truncate text-[11px] leading-tight text-gray-500">
                            {user?.email}
                        </span>
                    </span>
                    <ChevronDown className="hidden h-4 w-4 shrink-0 text-gray-400 lg:block" />
                </button>

                {open && (
                    <div
                        role="menu"
                        className="absolute right-0 top-full z-50 mt-2 w-64 overflow-hidden rounded-xl border border-edge bg-white shadow-lg"
                    >
                        <div className="border-b border-edge bg-gray-50 px-4 py-3">
                            <p className="truncate text-sm font-medium text-gray-900">{user?.name}</p>
                            <p className="truncate text-xs text-gray-500">{user?.email}</p>
                        </div>
                        <div className="p-1.5">
                            <button
                                role="menuitem"
                                onClick={logout}
                                className="flex w-full items-center gap-3 rounded-md px-3 py-2 text-sm font-medium text-red-600 transition hover:bg-red-50"
                            >
                                <LogOut className="h-4 w-4" />
                                Cerrar sesión
                            </button>
                        </div>
                    </div>
                )}
            </div>
        );
    }

    return (
        <div ref={menuRef} className="relative">
            <button
                onClick={() => setOpen((v) => !v)}
                aria-haspopup="menu"
                aria-expanded={open}
                title={compact ? user?.name : undefined}
                className={cn(
                    'flex w-full items-center rounded-lg transition hover:bg-gray-100',
                    compact ? 'justify-center p-1.5' : 'gap-3 px-2 py-2 text-left',
                )}
            >
                <Avatar user={user} size={compact ? 'sm' : 'md'} />
                {!compact && (
                    <>
                        <span className="min-w-0 flex-1">
                            <span className="block truncate text-sm font-medium text-gray-900">
                                {user?.name}
                            </span>
                            <span className="block truncate text-xs text-gray-500">
                                {user?.email}
                            </span>
                        </span>
                        <ChevronsUpDown className="h-4 w-4 shrink-0 text-gray-400" />
                    </>
                )}
            </button>

            {open && (
                <div
                    role="menu"
                    className={cn(
                        'absolute bottom-full z-50 mb-2 overflow-hidden rounded-lg border border-edge bg-white shadow-lg',
                        compact ? 'left-0 w-56' : 'left-0 right-0',
                    )}
                >
                    <div className="border-b border-edge bg-gray-50 px-4 py-3">
                        <p className="truncate text-sm font-medium text-gray-900">{user?.name}</p>
                        <p className="truncate text-xs text-gray-500">{user?.email}</p>
                    </div>
                    <div className="p-1.5">
                        <button
                            role="menuitem"
                            onClick={logout}
                            className="flex w-full items-center gap-3 rounded-md px-3 py-2 text-sm font-medium text-red-600 transition hover:bg-red-50"
                        >
                            <LogOut className="h-4 w-4" />
                            Cerrar sesión
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}
