import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Ban, Edit, Receipt, User } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, DetalleSheet, esMovil, Input, LineCards, Modal, Select } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const num = (n) => new Intl.NumberFormat('es-PE', { maximumFractionDigits: 2 }).format(Number(n) || 0);

const fecha = (v) => (v ? new Date(v).toLocaleDateString('es-PE') : '—');

const ESTADOS = {
    pendiente: { label: 'Pendiente', variant: 'amber' },
    convertido: { label: 'Convertido', variant: 'green' },
    cancelado: { label: 'Cancelado', variant: 'red' },
};

function EstadoBadge({ estado }) {
    const e = ESTADOS[estado] ?? { label: estado, variant: 'gray' };
    return <Badge variant={e.variant}>{e.label}</Badge>;
}

export default function Pedidos() {
    const toast = useToast();
    const navigate = useNavigate();

    const [pedidos, setPedidos] = useState([]);
    const [seleccionado, setSeleccionado] = useState(null);
    const [detalleMovil, setDetalleMovil] = useState(false);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [fEstado, setFEstado] = useState('');

    const [cancelTarget, setCancelTarget] = useState(null);
    const [motivo, setMotivo] = useState('');
    const [cancelando, setCancelando] = useState(false);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const lista = asList(await api.get('/pedidos', { params: { per_page: 100 } }));
            setPedidos(lista);
            // Se conserva la selección tras recargar (el pedido pudo cambiar de estado).
            setSeleccionado((prev) => lista.find((p) => p.id === prev?.id) ?? null);
        } catch {
            setError('No se pudieron cargar los pedidos.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    const handleCancelar = async () => {
        if (!motivo.trim()) {
            toast.error('Escribe el motivo de la cancelación.');
            return;
        }
        setCancelando(true);
        try {
            await api.post(`/pedidos/${cancelTarget.id}/cancelar`, { motivo_cancelacion: motivo });
            toast.success('Pedido cancelado. El stock reservado volvió a estar disponible.');
            setCancelTarget(null);
            setMotivo('');
            await load();
        } catch (err) {
            toast.error(err.response?.data?.message ?? 'No se pudo cancelar el pedido.');
        } finally {
            setCancelando(false);
        }
    };

    const columns = [
        {
            key: 'documento',
            label: 'Documento',
            getSearchValue: (row) => `${row.serie}-${row.numero}`,
            render: (row) => (
                <Badge variant="gray">
                    {row.serie}-{row.numero}
                </Badge>
            ),
        },
        {
            key: 'cliente',
            label: 'Cliente',
            getSearchValue: (row) => row.cliente?.nombre ?? 'Clientes varios',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <User className="h-4 w-4 text-primary-600" />
                    {row.cliente?.nombre ?? 'Clientes varios'}
                </span>
            ),
        },
        { key: 'fecha_pedido', label: 'Fecha', searchable: false, render: (row) => fecha(row.fecha_pedido) },
        { key: 'fecha_entrega', label: 'Entrega', searchable: false, render: (row) => fecha(row.fecha_entrega) },
        {
            key: 'total',
            label: 'Total',
            align: 'right',
            searchable: false,
            render: (row) => <span className="font-semibold text-warm-900">{money(row.total)}</span>,
        },
        {
            key: 'estado',
            label: 'Estado',
            searchable: false,
            render: (row) => (
                <span className="inline-flex flex-col items-start gap-0.5">
                    <EstadoBadge estado={row.estado} />
                    {row.estado === 'convertido' && row.nota_venta && (
                        <span className="text-xs text-warm-500">
                            Venta {row.nota_venta.serie}-{row.nota_venta.numero}
                        </span>
                    )}
                </span>
            ),
        },
        {
            type: 'actions',
            key: 'actions',
            label: 'Acciones',
            width: '130px',
            actions: (row) =>
                row.estado === 'pendiente' ? (
                    <>
                        <button
                            aria-label="Convertir en venta"
                            title="Convertir en venta"
                            onClick={() => navigate(`/notas-venta/nueva?pedido=${row.id}`)}
                            className="rounded-md p-1.5 text-green-600 transition hover:bg-green-50 hover:text-green-700"
                        >
                            <Receipt className="h-4 w-4" />
                        </button>
                        <button
                            aria-label="Editar"
                            title="Editar pedido"
                            onClick={() => navigate(`/pedidos/${row.id}/editar`)}
                            className="rounded-md p-1.5 text-amber-600 transition hover:bg-amber-50 hover:text-amber-700"
                        >
                            <Edit className="h-4 w-4" />
                        </button>
                        <button
                            aria-label="Cancelar"
                            title="Cancelar pedido"
                            onClick={() => {
                                setCancelTarget(row);
                                setMotivo('');
                            }}
                            className="rounded-md p-1.5 text-red-600 transition hover:bg-red-50 hover:text-red-700"
                        >
                            <Ban className="h-4 w-4" />
                        </button>
                    </>
                ) : null,
        },
    ];

    const detalles = seleccionado?.detalles ?? [];
    const totalCantidad = detalles.reduce((acc, d) => acc + (Number(d.cantidad) || 0), 0);

    const pendientes = pedidos.filter((p) => p.estado === 'pendiente');
    const totalPendiente = pendientes.reduce((acc, p) => acc + (Number(p.total) || 0), 0);

    return (
        <Layout>
            <PageHeader
                title="Pedidos"
                description="Pedidos de clientes. Reservan el stock hasta que se vendan o se cancelen"
                actions={<CreateButton onClick={() => navigate('/pedidos/nuevo')}>Nuevo pedido</CreateButton>}
            />

            {error && (
                <Alert variant="error" className="mb-4">
                    {error}
                </Alert>
            )}

            <div className="mb-4 grid grid-cols-2 gap-3 lg:grid-cols-4">
                {[
                    { label: 'Pedidos', valor: pedidos.length, tono: 'text-warm-900' },
                    { label: 'Pendientes', valor: pendientes.length, tono: 'text-amber-600' },
                    { label: 'Por vender', valor: money(totalPendiente), tono: 'text-primary-600' },
                    {
                        label: 'Convertidos',
                        valor: pedidos.filter((p) => p.estado === 'convertido').length,
                        tono: 'text-green-600',
                    },
                ].map((c) => (
                    <div key={c.label} className="rounded-xl border border-edge bg-white p-4 shadow-sm">
                        <p className="text-xs font-semibold uppercase tracking-wide text-warm-500">{c.label}</p>
                        <p className={`mt-1 text-xl font-bold ${c.tono}`}>{c.valor}</p>
                    </div>
                ))}
            </div>

            <DataTable
                columns={columns}
                rows={pedidos.filter((p) => !fEstado || p.estado === fEstado)}
                loading={loading}
                onRowClick={(row) => {
                    setSeleccionado(row);
                    if (esMovil()) setDetalleMovil(true);
                }}
                rowClassName={(row) => (row.id === seleccionado?.id ? 'bg-primary-50' : undefined)}
                searchPlaceholder="Buscar pedidos..."
                emptyMessage="Aún no hay pedidos"
                filterable
                filterCount={fEstado ? 1 : 0}
                filters={
                    <div className="space-y-2">
                        <Select
                            label="Estado"
                            value={fEstado}
                            onChange={(e) => setFEstado(e.target.value)}
                            options={[
                                { value: '', label: 'Todos' },
                                { value: 'pendiente', label: 'Pendiente' },
                                { value: 'convertido', label: 'Convertido' },
                                { value: 'cancelado', label: 'Cancelado' },
                            ]}
                        />
                        {fEstado && (
                            <button
                                onClick={() => setFEstado('')}
                                className="text-xs font-medium text-red-600 hover:text-red-700"
                            >
                                Limpiar filtros
                            </button>
                        )}
                    </div>
                }
            />

            {/* Detalle del pedido seleccionado */}
            <div className="hidden md:block mt-6 rounded-xl border border-edge bg-white shadow-sm">
                <div className="flex items-center justify-between border-b border-edge px-5 py-3">
                    <h2 className="text-sm font-semibold text-warm-900">
                        Detalle {seleccionado ? `de ${seleccionado.serie}-${seleccionado.numero}` : ''}
                    </h2>
                    <span className="text-xs text-warm-500">
                        {detalles.length} {detalles.length === 1 ? 'producto' : 'productos'}
                        {seleccionado?.almacen?.nombre ? ` · ${seleccionado.almacen.nombre}` : ''}
                    </span>
                </div>
                <div className="overflow-auto md:max-h-[32vh]">
                    <table className="w-full min-w-[720px] text-sm">
                        <thead className="sticky top-0 z-10">
                            <tr className="bg-primary-600 text-left text-xs font-semibold uppercase tracking-wide text-white">
                                <th className="w-12 px-3 py-1.5 text-center">#</th>
                                <th className="w-28 px-3 py-1.5">Código</th>
                                <th className="px-3 py-1.5">Producto</th>
                                <th className="w-28 px-3 py-1.5">Unidad</th>
                                <th className="w-20 px-3 py-1.5 text-right">Cant.</th>
                                <th className="w-24 px-3 py-1.5 text-right">Precio</th>
                                <th className="w-28 px-3 py-1.5 text-right">Subtotal</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {detalles.length === 0 && (
                                <tr>
                                    <td colSpan={7} className="px-3 py-10 text-center text-sm text-warm-500">
                                        {seleccionado
                                            ? 'Este pedido no tiene productos.'
                                            : 'Selecciona un pedido arriba para ver su detalle.'}
                                    </td>
                                </tr>
                            )}

                            {detalles.map((d, i) => {
                                const producto = d.presentacion?.producto;
                                return (
                                    <tr key={d.id}>
                                        <td className="px-3 py-2 text-center text-warm-500">{i + 1}</td>
                                        <td className="px-3 py-2 text-warm-500">{producto?.codigo ?? '—'}</td>
                                        <td className="px-3 py-2 font-semibold text-warm-900">
                                            {producto?.nombre ?? d.producto_nombre ?? '—'}
                                        </td>
                                        <td className="px-3 py-2 text-warm-500">{d.presentacion?.nombre ?? '—'}</td>
                                        <td className="px-3 py-2 text-right text-warm-900">{num(d.cantidad)}</td>
                                        <td className="px-3 py-2 text-right text-warm-900">{money(d.precio_unitario)}</td>
                                        <td className="px-3 py-2 text-right font-semibold text-primary-600">
                                            {money(d.subtotal)}
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                        {detalles.length > 0 && (
                            <tfoot className="sticky bottom-0">
                                <tr className="border-t-2 border-edge bg-gray-50 text-sm font-bold text-warm-900">
                                    <td className="px-3 py-2" colSpan={4}>
                                        Total
                                    </td>
                                    <td className="px-3 py-2 text-right">{num(totalCantidad)}</td>
                                    <td className="px-3 py-2" />
                                    <td className="px-3 py-2 text-right text-primary-700">
                                        {money(seleccionado?.total)}
                                    </td>
                                </tr>
                            </tfoot>
                        )}
                    </table>
                </div>
                {seleccionado?.observaciones && (
                    <p className="border-t border-edge px-5 py-3 text-sm text-warm-500">
                        <span className="font-medium text-warm-900">Observaciones:</span> {seleccionado.observaciones}
                    </p>
                )}
                {seleccionado?.estado === 'cancelado' && seleccionado.motivo_cancelacion && (
                    <div className="border-t border-edge px-5 py-3">
                        <Alert variant="warning">Cancelado: {seleccionado.motivo_cancelacion}</Alert>
                    </div>
                )}
            </div>

            <Modal
                open={Boolean(cancelTarget)}
                onClose={() => setCancelTarget(null)}
                title="Cancelar pedido"
                description={`Pedido ${cancelTarget?.serie}-${cancelTarget?.numero}. El stock reservado volverá a estar disponible.`}
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setCancelTarget(null)}>
                            Volver
                        </Button>
                        <Button variant="danger" loading={cancelando} onClick={handleCancelar}>
                            Cancelar pedido
                        </Button>
                    </>
                }
            >
                <Input
                    label="Motivo"
                    placeholder="Ej: el cliente ya no lo necesita"
                    value={motivo}
                    onChange={(e) => setMotivo(e.target.value)}
                />
            </Modal>
            <DetalleSheet
                open={detalleMovil && Boolean(seleccionado)}
                onClose={() => setDetalleMovil(false)}
                title={`Pedido ${seleccionado?.serie}-${seleccionado?.numero}`}
                description={`${detalles.length} ${detalles.length === 1 ? 'producto' : 'productos'}`}
                summary={[
                    { label: 'Cliente', value: seleccionado?.cliente?.nombre ?? 'Clientes varios' },
                    { label: 'Fecha', value: fecha(seleccionado?.fecha_pedido) },
                    { label: 'Entrega', value: fecha(seleccionado?.fecha_entrega) },
                    { label: 'Estado', value: ESTADOS[seleccionado?.estado]?.label ?? seleccionado?.estado },
                ]}
            >
                <LineCards
                    empty={seleccionado ? 'Este pedido no tiene productos.' : 'Selecciona un pedido arriba para ver su detalle.'}
                    items={detalles.map((d) => ({
                        key: d.id,
                        title: d.presentacion?.producto?.nombre ?? d.producto_nombre ?? '—',
                        subtitle: [d.presentacion?.producto?.codigo, d.presentacion?.nombre].filter(Boolean).join(' \u00b7 '),
                        fields: [
                            { label: 'Cant.', value: num(d.cantidad) },
                            { label: 'Precio', value: money(d.precio_unitario) },
                            { label: 'Subtotal', value: money(d.subtotal), className: 'text-primary-600' },
                        ],
                    }))}
                    totals={[{ label: 'Total', value: money(seleccionado?.total), strong: true }]}
                />
            </DetalleSheet>

        </Layout>
    );
}
