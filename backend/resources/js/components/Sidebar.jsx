import { useState } from 'react';
import { NavLink } from 'react-router-dom';
import { ChevronDown, Menu, X } from 'lucide-react';
import { navigation } from '../config/navigation';
import { cn } from './ui';
import UserMenu from './UserMenu';

export default function Sidebar() {
    const [collapsedGroups, setCollapsedGroups] = useState({});
    const [mobileOpen, setMobileOpen] = useState(false);

    const toggleGroup = (label) => {
        setCollapsedGroups((prev) => ({ ...prev, [label]: !prev[label] }));
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
                    'fixed inset-y-0 left-0 z-50 flex w-64 flex-col border-r border-edge bg-white transition-transform lg:translate-x-0',
                    mobileOpen ? 'translate-x-0' : '-translate-x-full',
                )}
            >
                <div className="flex h-16 items-center justify-between border-b border-edge px-4">
                    <img
                        src="/images/brava-monograma.png"
                        alt="BRAVA"
                        className="h-9 w-auto"
                    />
                    <button
                        onClick={() => setMobileOpen(false)}
                        aria-label="Cerrar menú"
                        className="rounded-md p-1.5 text-gray-500 hover:bg-gray-100 lg:hidden"
                    >
                        <X className="h-5 w-5" />
                    </button>
                </div>

                <nav className="flex-1 overflow-y-auto px-3 py-4">
                    <div className="mb-1 px-3 text-[11px] font-semibold uppercase tracking-wider text-gray-400">
                        Principal
                    </div>
                    {navigation.map((item) => {
                        if (!item.children) {
                            return (
                                <NavLink
                                    key={item.to}
                                    to={item.to}
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
                </nav>

                <div className="border-t border-edge p-3">
                    <UserMenu />
                </div>
            </aside>
        </>
    );
}
