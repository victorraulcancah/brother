import { Button, Card, Badge } from '../components/ui';
import { useAuth } from '../lib/auth';

export default function Dashboard() {
    const { user, logout } = useAuth();

    return (
        <div className="min-h-screen bg-cream">
            <header className="border-b border-edge bg-white">
                <div className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3 sm:px-6 lg:px-8">
                    <img
                        src="/images/brava-horizontal.png"
                        alt="BRAVA"
                        className="h-10 w-auto"
                    />
                    <div className="flex items-center gap-4">
                        <div className="text-right">
                            <p className="text-sm font-medium text-warm-900">{user?.name}</p>
                            <p className="text-xs text-warm-500">{user?.email}</p>
                        </div>
                        <Button variant="secondary" size="sm" onClick={logout}>
                            Cerrar sesión
                        </Button>
                    </div>
                </div>
            </header>

            <main className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
                <Card title="Bienvenido" className="mb-6">
                    <p className="text-sm text-gray-600">
                        Sesión iniciada correctamente con JWT.
                    </p>
                </Card>
                <div className="grid gap-4 sm:grid-cols-3">
                    <Card className="text-center">
                        <p className="text-sm text-gray-500">Rol</p>
                        <div className="mt-2">
                            <Badge variant="blue">
                                {user?.roles?.[0]?.name ?? 'Sin rol'}
                            </Badge>
                        </div>
                    </Card>
                    <Card className="text-center">
                        <p className="text-sm text-gray-500">Empresa</p>
                        <p className="mt-2 text-sm font-medium text-warm-900">
                            {user?.empresa?.nombre ?? '—'}
                        </p>
                    </Card>
                    <Card className="text-center">
                        <p className="text-sm text-gray-500">Estado</p>
                        <p className="mt-2 text-sm font-medium text-warm-900">Activo</p>
                    </Card>
                </div>
            </main>
        </div>
    );
}
