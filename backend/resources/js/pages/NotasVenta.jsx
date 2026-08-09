import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Ban, Eye, User } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal, Select, Spinner } from '../components/ui';

const fecha = (v) => (v ? new Date(v).toLocaleDateString('es-PE') : '—');
const formaLabel = { efectivo: 'Efectivo', transferencia: 'Transferencia', tarjeta: 'Tarjeta', yape: 'Yape', plin: 'Plin', credito: 'Crédito', otro: 'Otro' };

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

export default function NotasVenta() {
    const toast = useToast();
    const navigate = useNavigate();
    const [notas, setNotas] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [fEstado, setFEstado] = useState('');
    const [fPago, setFPago] = useState('');

    const [anularTarget, setAnularTarget] = useState(null);
    const [motivo, setMotivo] = useState('');
    const [anulando, setAnulando] = useState(false);

    const [verOpen, setVerOpen] = useState(false);
    const [detalle, setDetalle] = useState(null);
    const [detalleLoading, setDetalleLoading] = useState(false);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            setNotas(asList(await api.get('/notas-venta')));
        } catch {
            setError('No se pudieron cargar las ventas.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    const verDetalle = async (row) => {
        setVerOpen(true);
        setDetalle(null);
        setDetalleLoading(true);
        try {
            const res = await api.get(`/notas-venta/${row.id}`);
            setDetalle(res.data?.data ?? res.data);
        } catch {
            toast.error('No se pudo cargar el detalle de la venta.');
            setVerOpen(false);
        } finally {
            setDetalleLoading(false);
        }
    };

    const handleAnular = async () => {
        if (!motivo.trim()) {
            toast.error('Escribe el motivo de anulación.');
            return;
        }
        setAnulando(true);
        try {
            await api.post(`/notas-venta/${anularTarget.id}/anular`, { motivo_anulacion: motivo });
            toast.success('Venta anulada. Stock devuelto al almacén.');
            setAnularTarget(null);
            setMotivo('');
            await load();
        } catch (err) {
            toast.error(err.response?.data?.message ?? 'No se pudo anular la venta.');
        } finally {
            setAnulando(false);
        }
    };

    const columns = [
        {
            key: 'documento',
            label: 'Documento',
            render: (row) => <Badge variant="gray">{row.serie}-{row.numero}</Badge>,
        },
        {
            key: 'cliente',
            label: 'Cliente',
            render: (row) => (
                <span className="inline-flex items-center gap-2 font-medium text-warm-900">
                    <User className="h-4 w-4 text-primary-600" />
                    {row.cliente?.nombre ?? 'Clientes varios'}
                </span>
            ),
        },
        { key: 'fecha_emision', label: 'Fecha', render: (row) => (row.fecha_emision ? new Date(row.fecha_emision).toLocaleDateString('es-PE') : '—') },
        {
            key: 'tipo_pago',
            label: 'Pago',
            render: (row) => (
                <Badge variant={row.tipo_pago === 'contado' ? 'green' : 'amber'}>
                    {row.tipo_pago === 'contado' ? 'Contado' : 'Crédito'}
                </Badge>
            ),
        },
        { key: 'total', label: 'Total', align: 'right', render: (row) => <span className="font-semibold text-warm-900">{money(row.total)}</span> },
        {
            key: 'estado',
            label: 'Estado',
            render: (row) =>
                row.estado === 'anulada' ? <Badge variant="red">Anulada</Badge> : <Badge variant="green">Emitida</Badge>,
        },
        {
            type: 'actions',
            key: 'actions',
            label: 'Acciones',
            actions: (row) => (
                <>
                    <button
                        aria-label="Ver detalle"
                        title="Ver detalle"
                        onClick={() => verDetalle(row)}
                        className="rounded-md p-1.5 text-primary-600 transition hover:bg-primary-50 hover:text-primary-700"
                    >
                        <Eye className="h-4 w-4" />
                    </button>
                    {row.estado !== 'anulada' && (
                        <button
                            aria-label="Anular"
                            title="Anular venta"
                            onClick={() => { setAnularTarget(row); setMotivo(''); }}
                            className="rounded-md p-1.5 text-red-600 transition hover:bg-red-50 hover:text-red-700"
                        >
                            <Ban className="h-4 w-4" />
                        </button>
                    )}
                </>
            ),
        },
    ];

    return (
        <Layout>
            <PageHeader
                title="Notas de Venta"
                description="Ventas emitidas a clientes"
                actions={
                    <CreateButton onClick={() => navigate('/notas-venta/nueva')}>Nueva venta</CreateButton>
                }
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable
                columns={columns}
                rows={notas.filter(
                    (n) =>
                        (!fEstado || n.estado === fEstado) &&
                        (!fPago || n.tipo_pago === fPago),
                )}
                loading={loading}
                searchPlaceholder="Buscar ventas..."
                filterable
                filterCount={(fEstado ? 1 : 0) + (fPago ? 1 : 0)}
                filters={
                    <div className="space-y-2">
                        <Select
                            label="Estado"
                            value={fEstado}
                            onChange={(e) => setFEstado(e.target.value)}
                            options={[
                                { value: '', label: 'Todos' },
                                { value: 'emitida', label: 'Emitida' },
                                { value: 'anulada', label: 'Anulada' },
                            ]}
                        />
                        <Select
                            label="Forma de pago"
                            value={fPago}
                            onChange={(e) => setFPago(e.target.value)}
                            options={[
                                { value: '', label: 'Todas' },
                                { value: 'contado', label: 'Contado' },
                                { value: 'credito', label: 'Crédito' },
                            ]}
                        />
                        {(fEstado || fPago) && (
                            <button
                                onClick={() => {
                                    setFEstado('');
                                    setFPago('');
                                }}
                                className="text-xs font-medium text-red-600 hover:text-red-700"
                            >
                                Limpiar filtros
                            </button>
                        )}
                    </div>
                }
            />

            <Modal
                open={Boolean(anularTarget)}
                onClose={() => setAnularTarget(null)}
                title="Anular venta"
                description={`Venta ${anularTarget?.serie}-${anularTarget?.numero}. El stock volverá al almacén.`}
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setAnularTarget(null)}>Cancelar</Button>
                        <Button variant="danger" loading={anulando} onClick={handleAnular}>Anular venta</Button>
                    </>
                }
            >
                <Input
                    label="Motivo de anulación"
                    placeholder="Ej: error en el registro"
                    value={motivo}
                    onChange={(e) => setMotivo(e.target.value)}
                />
            </Modal>

            <Modal
                open={verOpen}
                onClose={() => setVerOpen(false)}
                title={detalle ? `Venta ${detalle.serie}-${detalle.numero}` : 'Detalle de venta'}
                size="xl"
                footer={<Button variant="secondary" onClick={() => setVerOpen(false)}>Cerrar</Button>}
            >
                {detalleLoading || !detalle ? (
                    <div className="flex items-center justify-center py-12">
                        <Spinner size="lg" className="text-primary-600" />
                    </div>
                ) : (
                    <div className="space-y-4">
                        {/* Cabecera */}
                        <div className="grid grid-cols-2 gap-3 rounded-xl border border-edge bg-gray-50 p-4 text-sm sm:grid-cols-4">
                            <div>
                                <p className="text-xs uppercase tracking-wide text-warm-500">Cliente</p>
                                <p className="font-medium text-warm-900">{detalle.cliente?.nombre ?? 'Clientes varios'}</p>
                            </div>
                            <div>
                                <p className="text-xs uppercase tracking-wide text-warm-500">Fecha</p>
                                <p className="font-medium text-warm-900">{fecha(detalle.fecha_emision)}</p>
                            </div>
                            <div>
                                <p className="text-xs uppercase tracking-wide text-warm-500">Vendedor</p>
                                <p className="font-medium text-warm-900">{detalle.vendedor?.name ?? '—'}</p>
                            </div>
                            <div>
                                <p className="text-xs uppercase tracking-wide text-warm-500">Estado</p>
                                <div className="mt-0.5">
                                    {detalle.estado === 'anulada' ? <Badge variant="red">Anulada</Badge> : <Badge variant="green">Emitida</Badge>}
                                    {' '}
                                    <Badge variant={detalle.tipo_pago === 'contado' ? 'green' : 'amber'}>
                                        {detalle.tipo_pago === 'contado' ? 'Contado' : 'Crédito'}
                                    </Badge>
                                </div>
                            </div>
                        </div>

                        {/* Productos */}
                        <div>
                            <h3 className="mb-2 text-xs font-bold uppercase tracking-wide text-warm-500">Productos</h3>
                            <div className="overflow-hidden rounded-xl border border-edge">
                                <table className="w-full text-sm">
                                    <thead>
                                        <tr className="bg-gray-50 text-left text-xs uppercase tracking-wide text-warm-500">
                                            <th className="px-3 py-2">Producto</th>
                                            <th className="px-3 py-2 text-right">Cant.</th>
                                            <th className="px-3 py-2 text-right">Precio</th>
                                            <th className="px-3 py-2 text-right">Subtotal</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-gray-100">
                                        {(detalle.detalles ?? []).map((d) => (
                                            <tr key={d.id}>
                                                <td className="px-3 py-2">
                                                    <span className="font-medium text-warm-900">{d.producto_nombre ?? 'Producto'}</span>
                                                    {d.presentacion?.nombre && <span className="text-warm-400"> · {d.presentacion.nombre}</span>}
                                                </td>
                                                <td className="px-3 py-2 text-right">{Number(d.cantidad)}</td>
                                                <td className="px-3 py-2 text-right">{money(d.precio_unitario)}</td>
                                                <td className="px-3 py-2 text-right font-medium text-warm-900">{money(d.subtotal)}</td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        {/* Pagos + Total */}
                        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                            <div>
                                <h3 className="mb-2 text-xs font-bold uppercase tracking-wide text-warm-500">Pagos</h3>
                                {(detalle.pagos ?? []).length === 0 ? (
                                    <p className="text-sm text-warm-400">Sin pagos registrados.</p>
                                ) : (
                                    <ul className="space-y-1 text-sm">
                                        {detalle.pagos.map((p) => (
                                            <li key={p.id} className="flex justify-between">
                                                <span className="text-warm-600">{formaLabel[p.forma_pago] ?? p.metodo_pago?.nombre ?? p.forma_pago}</span>
                                                <span className="font-medium text-warm-900">{money(p.monto)}</span>
                                            </li>
                                        ))}
                                    </ul>
                                )}
                            </div>
                            <div className="rounded-xl border border-edge p-4">
                                <div className="flex justify-between text-sm text-warm-600">
                                    <span>Subtotal</span><span>{money(detalle.subtotal)}</span>
                                </div>
                                {Number(detalle.descuento_total) > 0 && (
                                    <div className="flex justify-between text-sm text-warm-600">
                                        <span>Descuento</span><span>- {money(detalle.descuento_total)}</span>
                                    </div>
                                )}
                                <div className="mt-2 flex justify-between border-t border-edge pt-2 text-base font-extrabold text-warm-900">
                                    <span>Total</span><span>{money(detalle.total)}</span>
                                </div>
                            </div>
                        </div>

                        {detalle.observaciones && (
                            <p className="text-sm text-warm-500"><span className="font-medium text-warm-700">Observaciones:</span> {detalle.observaciones}</p>
                        )}
                        {detalle.estado === 'anulada' && detalle.motivo_anulacion && (
                            <Alert variant="warning">Anulada: {detalle.motivo_anulacion}</Alert>
                        )}
                    </div>
                )}
            </Modal>
        </Layout>
    );
}
