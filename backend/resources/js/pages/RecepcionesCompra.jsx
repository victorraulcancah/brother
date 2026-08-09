import { useCallback, useEffect, useState } from 'react';
import { CheckCircle2, Truck, Undo2 } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal } from '../components/ui';

const num = (n) => new Intl.NumberFormat('es-PE', { maximumFractionDigits: 2 }).format(Number(n) || 0);

const fecha = (f) => (f ? new Date(f).toLocaleDateString('es-PE') : '—');

const estadoInfo = {
    parcial: { label: 'Parcial', variant: 'amber' },
    completa: { label: 'Completa', variant: 'green' },
    deshecha: { label: 'Deshecha', variant: 'red' },
};

export default function RecepcionesCompra() {
    const toast = useToast();
    const [recepciones, setRecepciones] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    /** Recepción cuyo detalle se muestra en la segunda tabla. */
    const [seleccionada, setSeleccionada] = useState(null);

    const [finalizarTarget, setFinalizarTarget] = useState(null);
    const [motivo, setMotivo] = useState('');
    const [deshacerTarget, setDeshacerTarget] = useState(null);
    const [procesando, setProcesando] = useState(false);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const lista = asList(await api.get('/recepciones-compra'));
            setRecepciones(lista);
            // Se mantiene la selección tras recargar; si no hay, se toma la primera.
            setSeleccionada((prev) => lista.find((r) => r.id === prev?.id) ?? lista[0] ?? null);
        } catch {
            setError('No se pudieron cargar las recepciones.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    const finalizar = async () => {
        if (!motivo.trim()) return toast.error('Indica el motivo de finalización.');

        setProcesando(true);
        try {
            await api.post(`/recepciones-compra/${finalizarTarget.id}/finalizar`, { motivo });
            toast.success('Recepción finalizada: se cerró el pendiente.');
            setFinalizarTarget(null);
            setMotivo('');
            await load();
        } catch (err) {
            toast.error(err.response?.data?.message ?? 'No se pudo finalizar.');
        } finally {
            setProcesando(false);
        }
    };

    const deshacer = async () => {
        setProcesando(true);
        try {
            await api.post(`/recepciones-compra/${deshacerTarget.id}/deshacer`);
            toast.success('Recepción deshecha: el stock fue revertido.');
            setDeshacerTarget(null);
            await load();
        } catch (err) {
            toast.error(err.response?.data?.message ?? 'No se pudo deshacer.');
        } finally {
            setProcesando(false);
        }
    };

    const columnasRecepcion = [
        { key: 'idx', label: '#', render: (row) => <span className="text-warm-500">{recepciones.indexOf(row) + 1}</span> },
        {
            key: 'documento',
            label: 'N° Documento',
            render: (row) => <span className="font-semibold text-warm-900">{row.documento ?? '—'}</span>,
        },
        { key: 'fecha_recepcion', label: 'Fecha', render: (row) => fecha(row.fecha_recepcion) },
        { key: 'registrador', label: 'Registrador', render: (row) => row.usuario_recibe?.name ?? '—' },
        {
            key: 'proveedor',
            label: 'Proveedor',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <Truck className="h-4 w-4 text-primary-600" />
                    {row.proveedor?.nombre ?? '—'}
                </span>
            ),
        },
        { key: 'almacen', label: 'Almacén Receptor', render: (row) => row.almacen?.nombre ?? '—' },
        {
            key: 'compra',
            label: 'Compra',
            render: (row) => (row.compra ? <Badge variant="gray">{row.compra.numero_compra}</Badge> : '—'),
        },
        {
            key: 'estado',
            label: 'Estado',
            render: (row) => {
                if (!row.activo) return <Badge variant="red">Inactiva</Badge>;
                const info = estadoInfo[row.estado] ?? { label: row.estado ?? '—', variant: 'gray' };
                return <Badge variant={info.variant}>{info.label}</Badge>;
            },
        },
        {
            key: 'finalizado',
            label: 'Finalización',
            render: (row) =>
                row.finalizado ? <Badge variant="blue">Finalizada</Badge> : <Badge variant="gray">Abierta</Badge>,
        },
        {
            key: 'motivo_finalizacion',
            label: 'Motivo de Finalización',
            render: (row) => <span className="text-warm-500">{row.motivo_finalizacion ?? '—'}</span>,
        },
        { key: 'fecha_finalizacion', label: 'Fecha Finalización', render: (row) => fecha(row.fecha_finalizacion) },
        {
            type: 'actions',
            key: 'actions',
            label: 'Acciones',
            actions: (row) => (
                <>
                    <button
                        aria-label="Finalizar"
                        title={
                            !row.activo
                                ? 'Está deshecha'
                                : row.finalizado
                                  ? 'Ya está finalizada'
                                  : 'Finalizar: cerrar lo que ya no va a llegar'
                        }
                        disabled={!row.activo || row.finalizado}
                        onClick={() => setFinalizarTarget(row)}
                        className="rounded-md p-1.5 text-green-600 transition hover:bg-green-50 disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-transparent"
                    >
                        <CheckCircle2 className="h-4 w-4" />
                    </button>
                    <button
                        aria-label="Deshacer"
                        title={row.activo ? 'Deshacer: revierte el stock ingresado' : 'Ya está deshecha'}
                        disabled={!row.activo}
                        onClick={() => setDeshacerTarget(row)}
                        className="rounded-md p-1.5 text-red-600 transition hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-transparent"
                    >
                        <Undo2 className="h-4 w-4" />
                    </button>
                </>
            ),
        },
    ];

    const detalles = seleccionada?.detalles ?? [];

    return (
        <Layout>
            <PageHeader
                title="Recepciones de Compra"
                description="Registro formal del ingreso de mercadería. Se generan desde cada compra."
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable
                columns={columnasRecepcion}
                rows={recepciones}
                loading={loading}
                searchPlaceholder="Buscar recepciones..."
                onRowClick={(row) => setSeleccionada(row)}
                rowClassName={(row) => (row.id === seleccionada?.id ? 'bg-primary-50' : undefined)}
            />

            {/* Detalle de la recepción seleccionada */}
            <div className="mt-6 rounded-xl border border-edge bg-white shadow-sm">
                <div className="flex items-center justify-between border-b border-edge px-5 py-3">
                    <h2 className="text-sm font-semibold text-warm-900">
                        Detalle {seleccionada?.documento ? `de ${seleccionada.documento}` : ''}
                    </h2>
                    <span className="text-xs text-warm-500">
                        {detalles.length} {detalles.length === 1 ? 'línea' : 'líneas'}
                    </span>
                </div>
                <div className="overflow-x-auto">
                    <table className="w-full min-w-[1080px] text-sm">
                        <thead>
                            <tr className="bg-primary-600 text-left text-xs font-semibold uppercase tracking-wide text-white">
                                <th className="px-3 py-2.5 text-center">#</th>
                                <th className="px-3 py-2.5">Cod. Producto</th>
                                <th className="px-3 py-2.5">Producto</th>
                                <th className="px-3 py-2.5">Marca</th>
                                <th className="px-3 py-2.5">Unidad Derivada</th>
                                <th className="px-3 py-2.5 text-right">Cantidad</th>
                                <th className="px-3 py-2.5 text-right">Cant. Pedida</th>
                                <th className="px-3 py-2.5 text-right">Cant. Total Recepcionada</th>
                                <th className="px-3 py-2.5 text-right">Cant. Finalizada</th>
                                <th className="px-3 py-2.5 text-right">Stock Anterior</th>
                                <th className="px-3 py-2.5 text-right">Stock Nuevo</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {detalles.length === 0 && (
                                <tr>
                                    <td colSpan={11} className="px-3 py-10 text-center text-sm text-warm-500">
                                        {seleccionada
                                            ? 'Esta recepción no tiene líneas.'
                                            : 'Selecciona una recepción arriba para ver su detalle.'}
                                    </td>
                                </tr>
                            )}

                            {detalles.map((d, i) => {
                                const producto = d.presentacion?.producto;
                                return (
                                    <tr key={d.id}>
                                        <td className="px-3 py-2 text-center text-warm-500">{i + 1}</td>
                                        <td className="px-3 py-2 text-warm-500">{producto?.codigo ?? '—'}</td>
                                        <td className="px-3 py-2 font-semibold text-warm-900">{producto?.nombre ?? '—'}</td>
                                        <td className="px-3 py-2 text-warm-500">{producto?.marca?.nombre ?? '—'}</td>
                                        <td className="px-3 py-2 text-warm-500">{d.presentacion?.nombre ?? '—'}</td>
                                        <td className="px-3 py-2 text-right font-semibold text-primary-600">{num(d.cantidad_recibida)}</td>
                                        <td className="px-3 py-2 text-right text-warm-900">{num(d.cantidad_pedida)}</td>
                                        <td className="px-3 py-2 text-right text-warm-900">{num(d.cantidad_recibida)}</td>
                                        <td className="px-3 py-2 text-right text-amber-600">{num(d.cantidad_finalizada)}</td>
                                        <td className="px-3 py-2 text-right text-warm-500">{num(d.stock_anterior)}</td>
                                        <td className="px-3 py-2 text-right font-medium text-warm-900">{num(d.stock_nuevo)}</td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Finalizar */}
            <Modal
                open={Boolean(finalizarTarget)}
                onClose={() => setFinalizarTarget(null)}
                title={`Finalizar ${finalizarTarget?.documento ?? ''}`}
                description="Cierra lo que falta por recibir. La compra queda dada por concluida."
                size="md"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setFinalizarTarget(null)}>Cancelar</Button>
                        <Button loading={procesando} onClick={finalizar}>Finalizar</Button>
                    </>
                }
            >
                <Alert variant="warning" className="mb-3">
                    Lo pendiente se registrará como cantidad finalizada y no se podrá recibir después.
                </Alert>
                <Input
                    label="Motivo de finalización"
                    placeholder="Ej. el proveedor no tenía stock del resto"
                    value={motivo}
                    onChange={(e) => setMotivo(e.target.value)}
                />
            </Modal>

            {/* Deshacer */}
            <Modal
                open={Boolean(deshacerTarget)}
                onClose={() => setDeshacerTarget(null)}
                title={`Deshacer ${deshacerTarget?.documento ?? ''}`}
                description="La recepción quedará inactiva."
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setDeshacerTarget(null)}>Cancelar</Button>
                        <Button variant="danger" loading={procesando} onClick={deshacer}>Deshacer</Button>
                    </>
                }
            >
                <Alert variant="warning">
                    Se dará salida del stock que esta recepción ingresó al almacén, y sus cantidades volverán a
                    quedar pendientes en la compra.
                </Alert>
            </Modal>
        </Layout>
    );
}
