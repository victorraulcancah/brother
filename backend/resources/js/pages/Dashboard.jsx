import { LayoutDashboard } from 'lucide-react';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Card, Badge } from '../components/ui';
import { useAuth } from '../lib/auth';

export default function Dashboard() {
    const { user } = useAuth();

    return (
        <Layout>
            <PageHeader
                title="Escritorio"
                description="Resumen general del sistema"
                actions={<CreateButton variant="primary">Nueva acción</CreateButton>}
            />

            <div className="grid gap-4 sm:grid-cols-3">
                <Card className="text-center">
                    <p className="text-sm text-gray-500">Rol</p>
                    <div className="mt-2">
                        <Badge variant="blue">{user?.roles?.[0]?.name ?? 'Sin rol'}</Badge>
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

            <Card className="mt-6">
                <div className="flex items-center gap-3 text-gray-500">
                    <LayoutDashboard className="h-5 w-5" />
                    <p className="text-sm">
                        Sesión iniciada correctamente con JWT. Las estadísticas llegarán aquí.
                    </p>
                </div>
            </Card>
        </Layout>
    );
}
