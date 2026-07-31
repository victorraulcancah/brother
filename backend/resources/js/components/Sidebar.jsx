import { useEffect, useState } from 'react';
import { NavLink } from 'react-router-dom';
import { ChevronDown, ChevronsLeft, ChevronsRight, Menu, X } from 'lucide-react';
import { navigation } from '../config/navigation';
import { cn } from './ui';
import UserMenu from './UserMenu';

const GROUPS_STORAGE = 'sidebar_groups';
const GROUP_LABELS = navigation.filter((i) => i.children).map((i) => i.label);

// Estado inicial de los grupos: contraídos por defecto (o lo guardado en localStorage).
function initGroups() {
    try {
        const saved = JSON.parse(localStorage.getItem(GROUPS_STORAGE));
        if (saved && typeof saved === 'object') return saved;
    } catch {
        /* localStorage no disponible o corrupto */
    }
    return Object.fromEntries(GROUP_LABELS.map((label) => [label, true]));
}

function persistGroups(groups) {
    try {
        localStorage.setItem(GROUPS_STORAGE, JSON.stringify(groups));
    } catch {
        /* ignorar */
    }
}

export default function Sidebar({ collapsed = false, onToggleCollapse }) {
    const [collapsedGroups, setCollapsedGroups] = useState(initGroups);
    const [mobileOpen, setMobileOpen] = useState(false);
    const [isDesktop, setIsDesktop] = useState(
        () => typeof window !== 'undefined' && window.matchMedia('(min-width: 1024px)').matches,
    );

    // Detecta escritorio para saber si el modo "rail" (barra de iconos) aplica.
    useEffect(() => {
        const mq = window.matchMedia('(min-width: 1024px)');
        const handler = (e) => setIsDesktop(e.matches);
        mq.addEventListener('change', handler);
        return () => mq.removeEventListener('change', handler);
    }, []);

    // El sidebar se contrae a iconos solo en escritorio; en móvil siempre es el drawer completo.
    const rail = collapsed && isDesktop;

    const toggleGroup = (label) => {
        setCollapsedGroups((prev) => {
            const next = { ...prev, [label]: !prev[label] };
            persistGroups(next);
            return next;
        });
    };

    return (
        <>
            <button
                onClick={() => setMobileOpen(true)}
                aria-label="Abrir menú"
                className="fixed left-4 top-4 z-40 rounded-md p-2 text-gray-600 hover:bg-gray-100 lg:hidden"
            >
                <Menu className="h-5 w-5" />
            </button>

            {mobileOpen && (
                <div
                    className="fixed inset-0 z-40 bg-black/50 lg:hidden"
                    onClick={() => setMobileOpen(false)}
                />
            )}

            <aside
                className={cn(
                    'fixed inset-y-0 left-0 z-50 flex w-64 flex-col border-r border-edge bg-white transition-[transform,width] lg:translate-x-0',
                    mobileOpen ? 'translate-x-0' : '-translate-x-full',
                    collapsed ? 'lg:w-16' : 'lg:w-64',
                )}
            >
                <div
                    className={cn(
                        'flex h-16 items-center border-b border-edge',
                        rail ? 'justify-center px-2' : 'justify-between px-4',
                    )}
                >
                    {rail ? (
                        <button
                            onClick={onToggleCollapse}
                            aria-label="Desplegar menú"
                            title="Desplegar menú"
                            className="rounded-md p-1.5 text-gray-500 transition hover:bg-gray-100 hover:text-gray-700"
                        >
                            <ChevronsRight className="h-5 w-5" />
                        </button>
                    ) : (
                        <>
                            <img
                                src="/images/brava-horizontal.png"
                                alt="BRAVA"
                                className="h-8 w-auto"
                            />
                            <div className="flex items-center gap-1">
                                <button
                                    onClick={onToggleCollapse}
                                    aria-label="Contraer menú"
                                    title="Contraer menú"
                                    className="hidden rounded-md p-1.5 text-gray-500 transition hover:bg-gray-100 hover:text-gray-700 lg:inline-flex"
                                >
                                    <ChevronsLeft className="h-5 w-5" />
                                </button>
                                <button
                                    onClick={() => setMobileOpen(false)}
                                    aria-label="Cerrar menú"
                                    className="rounded-md p-1.5 text-gray-500 hover:bg-gray-100 lg:hidden"
                                >
                                    <X className="h-5 w-5" />
                                </button>
                            </div>
                        </>
                    )}
                </div>

                <nav className={cn('flex-1 overflow-y-auto py-4', rail ? 'px-2' : 'px-3')}>
                    {rail ? (
                        navigation.map((item) => {
                            const Icon = item.icon;
                            if (!item.children) {
                                return (
                                    <NavLink
                                        key={item.to}
                                        to={item.to}
                                        title={item.label}
                                        className={({ isActive }) =>
                                            cn(
                                                'mb-1 flex items-center justify-center rounded-lg p-2.5 transition',
                                                isActive
                                                    ? 'bg-primary-50 text-primary-700'
                                                    : 'text-gray-500 hover:bg-gray-100 hover:text-gray-900',
                                            )
                                        }
                                    >
                                        <Icon className="h-5 w-5" />
                                    </NavLink>
                                );
                            }
                            // Grupo en modo rail: al hacer clic se despliega el sidebar completo.
                            return (
                                <button
                                    key={item.label}
                                    onClick={onToggleCollapse}
                                    title={item.label}
                                    className="mb-1 flex w-full items-center justify-center rounded-lg p-2.5 text-gray-500 transition hover:bg-gray-100 hover:text-gray-900"
                                >
                                    <Icon className="h-5 w-5" />
                                </button>
                            );
                        })
                    ) : (
                        <>
                            <div className="mb-1 px-3 text-[11px] font-semibold uppercase tracking-wider text-gray-400">
                                Principal
                            </div>
                            {navigation.map((item) => {
                                if (!item.children) {
                                    return (
                                        <NavLink
                                            key={item.to}
                                            to={item.to}
                                            onClick={() => setMobileOpen(false)}
                                            className={({ isActive }) =>
                                                cn(
                                                    'mb-1 flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition',
                                                    isActive
                                                        ? 'bg-primary-50 text-primary-700'
                                                        : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900',
                                                )
                                            }
                                        >
                                            <item.icon className="h-5 w-5 shrink-0" />
                                            {item.label}
                                        </NavLink>
                                    );
                                }

                                const open = !collapsedGroups[item.label];
                                return (
                                    <div key={item.label} className="mb-1">
                                        <button
                                            onClick={() => toggleGroup(item.label)}
                                            className="mb-1 flex w-full items-center gap-3 rounded-lg px-3 py-2 text-[11px] font-semibold uppercase tracking-wider text-gray-400 transition hover:bg-gray-100 hover:text-gray-600"
                                        >
                                            <item.icon className="h-4 w-4 shrink-0" />
                                            <span className="flex-1 text-left">{item.label}</span>
                                            <ChevronDown
                                                className={cn(
                                                    'h-4 w-4 transition-transform',
                                                    open && 'rotate-180',
                                                )}
                                            />
                                        </button>
                                        {open && (
                                            <div className="mb-1 ml-3 border-l border-edge pl-2">
                                                {item.children.map((child) => (
                                                    <NavLink
                                                        key={child.to}
                                                        to={child.to}
                                                        onClick={() => setMobileOpen(false)}
                                                        className={({ isActive }) =>
                                                            cn(
                                                                'mb-1 flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition',
                                                                isActive
                                                                    ? 'bg-primary-50 font-medium text-primary-700'
                                                                    : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900',
                                                            )
                                                        }
                                                    >
                                                        <child.icon className="h-4 w-4 shrink-0 text-gray-400" />
                                                        {child.label}
                                                    </NavLink>
                                                ))}
                                            </div>
                                        )}
                                    </div>
                                );
                            })}
                        </>
                    )}
                </nav>

                <div className={cn('border-t border-edge', rail ? 'p-2' : 'p-3')}>
                    <UserMenu compact={rail} />
                </div>
            </aside>
        </>
    );
}
