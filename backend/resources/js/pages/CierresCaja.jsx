import { useCallback, useEffect, useState } from 'react';
import { Coins } from 'lucide-react';
import api, { asList } from '../lib/api';
import Layout from '../components/Layout';
import PageHeader from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Select, Spinner } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const fechaHora = (v) => (v ? new Date(v).toLocaleString('es-PE') : '—');
const fechaCorta = (v) => (v ? new Date(v).toLocaleDateString('es-PE') : '—');

const metodoLabel = (m) => {
    if (m.cuenta_bancaria) return `Transf. · ${m.cuenta_bancaria.alias || m.cuenta_bancaria.numero_cuenta}`;
    if (m.billetera) return m.billetera.nombre;
    return 'Efectivo';
};

export default function CierresCaja() {
    const [cierres, setCierres] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    /** Cierre cuyos movimientos se muestran abajo. */
    const [seleccionado, setSeleccionado] = useState(null);
    const [movimientos, setMovimientos] = useState([]);
    const [cargandoDetalle, setCargandoDetalle] = useState(false);

    const [filtroCaja, setFiltroCaja] = useState('');
    const [filtroDiferencia, setFiltroDiferencia] = useState('');
    const [filtrosActivos, setFiltrosActivos] = useState({});

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const lista = asList(await api.get('/cierres-caja'));
            setCierres(lista);
            setSeleccionado((prev) => lista.find((c) => c.id === prev?.id) ?? lista[0] ?? null);
        } catch {
            setError('No se pudieron cargar los cierres de caja.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    // Los movimientos se piden solo del cierre que se está viendo.
    useEffect(() => {
        if (!seleccionado) {
            setMovimientos([]);
            return;
        }
        let vivo = true;
        setCargandoDetalle(true);
        api.get(`/cierres-caja/${seleccionado.id}`)
            .then((res) => vivo && setMovimientos(res.data?.movimientos ?? []))
            .catch(() => vivo && setMovimientos([]))
            .finally(() => vivo && setCargandoDetalle(false));
        return () => {
            vivo = false;
        };
    }, [seleccionado]);

    const aplicarFiltros = () => {
        const next = {};
        if (filtroCaja) next.caja = filtroCaja;
        if (filtroDiferencia) next.diferencia = filtroDiferencia;
        setFiltrosActivos(next);
    };

    const limpiarFiltros = () => {
        setFiltroCaja('');
        setFiltroDiferencia('');
        setFiltrosActivos({});
    };

    const visibles = cierres.filter((c) => {
        if (filtrosActivos.caja && String(c.apertura?.caja?.id) !== filtrosActivos.caja) return false;
        const dif = Number(c.diferencia) || 0;
        if (filtrosActivos.diferencia === 'cuadra' && Math.abs(dif) > 0.001) return false;
        if (filtrosActivos.diferencia === 'falta' && dif >= -0.001) return false;
        if (filtrosActivos.diferencia === 'sobra' && dif <= 0.001) return false;
        return true;
    });

    const cajasPresentes = [
        ...new Map(
            cierres.filter((c) => c.apertura?.caja?.id).map((c) => [String(c.apertura.caja.id), c.apertura.caja.nombre]),
        ).entries(),
    ].map(([value, label]) => ({ value, label }));

    const filtrosCount = Object.keys(filtrosActivos).length;

    const filtros = (
        <div className="flex flex-wrap items-end gap-3">
            <Select
                label="Caja"
                value={filtroCaja}
                onChange={(e) => setFiltroCaja(e.target.value)}
                options={[{ value: '', label: 'Todas' }, ...cajasPresentes]}
                className="w-52"
            />
            <Select
                label="Diferencia"
                value={filtroDiferencia}
                onChange={(e) => setFiltroDiferencia(e.target.value)}
                options={[
                    { value: '', label: 'Todas' },
                    { value: 'cuadra', label: 'Cuadró' },
                    { value: 'falta', label: 'Faltó dinero' },
                    { value: 'sobra', label: 'Sobró dinero' },
                ]}
                className="w-48"
            />
            <Button variant="primary" size="sm" onClick={aplicarFiltros}>
                Aplicar
            </Button>
            {filtrosCount > 0 && (
                <Button variant="ghost" size="sm" onClick={limpiarFiltros}>
                    Limpiar
                </Button>
            )}
        </div>
    );

    const diferenciaBadge = (row) => {
        const dif = Number(row.diferencia) || 0;
        if (Math.abs(dif) < 0.001) return <Badge variant="green">Cuadró</Badge>;
        return (
            <Badge variant={dif < 0 ? 'red' : 'amber'}>
                {dif < 0 ? 'Faltó ' : 'Sobró '}
                {money(Math.abs(dif))}
            </Badge>
        );
    };

    const columns = [
        {
            key: 'idx',
            label: '#',
            width: '56px',
            render: (row) => <span className="text-warm-500">{cierres.indexOf(row) + 1}</span>,
        },
        {
            key: 'caja',
            label: 'Caja',
            width: '150px',
            getSearchValue: (row) => row.apertura?.caja?.nombre,
            render: (row) => (
                <span className="flex items-center gap-2 font-medium text-warm-900">
                    <Coins className="h-4 w-4 shrink-0 text-primary-600" />
                    <span className="truncate">{row.apertura?.caja?.nombre ?? '—'}</span>
                </span>
            ),
        },
        {
            key: 'usuario',
            label: 'Cajero',
            width: '140px',
            getSearchValue: (row) => row.apertura?.usuario?.name,
            render: (row) => <span className="block truncate">{row.apertura?.usuario?.name ?? '—'}</span>,
        },
        {
            key: 'apertura',
            label: 'Apertura',
            width: '150px',
            getSearchValue: (row) => fechaCorta(row.apertura?.fecha_apertura),
            render: (row) => (
                <span className="whitespace-nowrap text-warm-500">{fechaHora(row.apertura?.fecha_apertura)}</span>
            ),
        },
        {
            key: 'fecha_cierre',
            label: 'Cierre',
            width: '150px',
            getSearchValue: (row) => fechaCorta(row.fecha_cierre),
            render: (row) => <span className="whitespace-nowrap text-warm-900">{fechaHora(row.fecha_cierre)}</span>,
        },
        {
            key: 'monto_inicial',
            label: 'Inicial',
            width: '105px',
            align: 'right',
            searchable: false,
            render: (row) => <span className="text-warm-500">{money(row.apertura?.monto_inicial)}</span>,
        },
        {
            key: 'ingresos',
            label: 'Ingresos',
            width: '110px',
            align: 'right',
            searchable: false,
            render: (row) => <span className="text-green-600">{money(row.ingresos)}</span>,
        },
        {
            key: 'egresos',
            label: 'Gastos',
            width: '110px',
            align: 'right',
            searchable: false,
            render: (row) => <span className="text-red-600">{money(row.egresos)}</span>,
        },
        {
            key: 'monto_sistema',
            label: 'Esperado',
            width: '115px',
            align: 'right',
            searchable: false,
            render: (row) => <span className="text-warm-900">{money(row.monto_sistema)}</span>,
        },
        {
            key: 'monto_contado',
            label: 'Contado',
            width: '115px',
            align: 'right',
            searchable: false,
            render: (row) => <span className="font-semibold text-warm-900">{money(row.monto_contado)}</span>,
        },
        {
            key: 'diferencia',
            label: 'Diferencia',
            width: '150px',
            searchable: false,
            render: diferenciaBadge,
        },
        {
            key: 'movimientos_count',
            label: 'Movs.',
            width: '80px',
            align: 'right',
            searchable: false,
            render: (row) => <Badge variant="gray">{row.movimientos_count ?? 0}</Badge>,
        },
    ];

    return (
        <Layout>
            <PageHeader
                title="Cierres de Caja"
                description="Registro de arqueos: lo esperado, lo contado y los movimientos de cada apertura"
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable
                columns={columns}
                rows={visibles}
                loading={loading}
                searchPlaceholder="Buscar cierres..."
                filterable
                filters={filtros}
                filterCount={filtrosCount}
                emptyMessage="Todavía no hay cierres de caja registrados."
                height="350px"
                onRowClick={(row) => setSeleccionado(row)}
                rowClassName={(row) => (row.id === seleccionado?.id ? 'bg-primary-50' : undefined)}
            />

            {/* Movimientos entre la apertura y el cierre seleccionado */}
            <div className="mt-6 rounded-xl border border-edge bg-white shadow-sm">
                <div className="flex flex-wrap items-center justify-between gap-2 border-b border-edge px-5 py-3">
                    <h2 className="text-sm font-semibold text-warm-900">
                        Movimientos
                        {seleccionado?.apertura?.caja?.nombre ? ` · ${seleccionado.apertura.caja.nombre}` : ''}
                        {seleccionado ? ` · ${fechaCorta(seleccionado.fecha_cierre)}` : ''}
                    </h2>
                    {seleccionado && (
                        <span className="flex flex-wrap items-center gap-3 text-xs text-warm-500">
                            <span>
                                {movimientos.length}{' '}
                                {movimientos.length === 1 ? 'movimiento' : 'movimientos'}
                            </span>
                            <span>
                                Efectivo: <strong className="text-warm-900">
                                    {money(
                                        Number(seleccionado.apertura?.monto_inicial ?? 0) +
                                            Number(seleccionado.efectivo_ingresos ?? 0) -
                                            Number(seleccionado.efectivo_egresos ?? 0),
                                    )}
                                </strong>
                            </span>
                            <span>
                                Transferencias:{' '}
                                <strong className="text-warm-900">{money(seleccionado.transferencias)}</strong>
                            </span>
                            <span>
                                Billeteras: <strong className="text-warm-900">{money(seleccionado.billeteras)}</strong>
                            </span>
                        </span>
                    )}
                </div>

                {cargandoDetalle ? (
                    <div className="flex items-center justify-center py-12">
                        <Spinner size="lg" className="text-primary-600" />
                    </div>
                ) : (
                    // Tope de alto: una jornada puede tener decenas de movimientos.
                    <div className="h-[350px] overflow-auto">
                        <table className="w-full min-w-[820px] text-sm">
                            <thead className="sticky top-0 z-10">
                                <tr className="bg-primary-600 text-left text-xs font-semibold uppercase tracking-wide text-white">
                                    <th className="w-14 px-3 py-2.5 text-center">#</th>
                                    <th className="w-44 px-3 py-2.5">Fecha</th>
                                    <th className="w-28 px-3 py-2.5">Tipo</th>
                                    <th className="px-3 py-2.5">Motivo</th>
                                    <th className="w-48 px-3 py-2.5">Método</th>
                                    <th className="w-36 px-3 py-2.5 text-right">Monto</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100">
                                {movimientos.length === 0 && (
                                    <tr>
                                        <td colSpan={6} className="px-3 py-10 text-center text-sm text-warm-500">
                                            {seleccionado
                                                ? 'Esta apertura no tuvo movimientos.'
                                                : 'Selecciona un cierre arriba para ver sus movimientos.'}
                                        </td>
                                    </tr>
                                )}

                                {movimientos.map((m, i) => (
                                    <tr key={m.id}>
                                        <td className="px-3 py-2 text-center text-warm-500">{i + 1}</td>
                                        <td className="px-3 py-2 whitespace-nowrap text-warm-500">
                                            {fechaHora(m.fecha)}
                                        </td>
                                        <td className="px-3 py-2">
                                            <Badge variant={m.tipo === 'ingreso' ? 'green' : 'red'}>
                                                {m.tipo === 'ingreso' ? 'Ingreso' : 'Gasto'}
                                            </Badge>
                                        </td>
                                        <td className="px-3 py-2">
                                            <div className="leading-tight">
                                                <div className="text-warm-900">{m.motivo?.nombre ?? '—'}</div>
                                                {m.descripcion && (
                                                    <div className="text-xs text-warm-500">{m.descripcion}</div>
                                                )}
                                            </div>
                                        </td>
                                        <td className="px-3 py-2 text-warm-500">{metodoLabel(m)}</td>
                                        <td
                                            className={`px-3 py-2 text-right font-semibold ${
                                                m.tipo === 'ingreso' ? 'text-green-600' : 'text-red-600'
                                            }`}
                                        >
                                            {m.tipo === 'ingreso' ? '+' : '-'} {money(m.monto)}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        </Layout>
    );
}
