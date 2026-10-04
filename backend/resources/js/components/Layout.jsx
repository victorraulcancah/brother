import { useState } from 'react';
import AlertsBell from './AlertsBell';
import Sidebar from './Sidebar';
import UserMenu from './UserMenu';
import { cn } from './ui';

const COLLAPSE_STORAGE = 'sidebar_collapsed';

export default function Layout({ children }) {
    const [collapsed, setCollapsed] = useState(() => {
        try {
            return localStorage.getItem(COLLAPSE_STORAGE) === '1';
        } catch {
            return false;
        }
    });

    const toggleCollapsed = () => {
        setCollapsed((prev) => {
            const next = !prev;
            try {
                localStorage.setItem(COLLAPSE_STORAGE, next ? '1' : '0');
            } catch {
                /* ignorar */
            }
            return next;
        });
    };

    return (
        <div className="min-h-screen bg-cream">
            <Sidebar collapsed={collapsed} onToggleCollapse={toggleCollapsed} />
            <div
                className={cn(
                    'flex min-h-screen flex-col transition-[padding]',
                    collapsed ? 'lg:pl-16' : 'lg:pl-64',
                )}
            >
                {/* Barra superior: alertas y usuario. Antes el usuario ocupaba el pie del menú lateral. */}
                <header className="flex h-16 shrink-0 items-center justify-end gap-2 px-4 sm:px-6 lg:h-14 lg:px-8">
                    <AlertsBell />
                    <UserMenu variant="topbar" />
                </header>
                <main className="flex-1 px-4 pb-6 pt-0 sm:px-6 lg:px-8 lg:pt-1">{children}</main>
            </div>
        </div>
    );
}
