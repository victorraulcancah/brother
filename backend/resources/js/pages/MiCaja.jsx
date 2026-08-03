import { useCallback, useEffect, useState } from 'react';
import { ArrowDownCircle, ArrowUpCircle, Lock, LockOpen, PiggyBank, Wallet } from 'lucide-react';
import api from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader from '../components/PageHeader';
import { Alert, Badge, Button, Card, Input, Modal, Spinner } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const fechaHora = (v) => (v ? new Date(v).toLocaleString('es-PE') : '—');

function Stat({ icon: Icon, label, value, accent = 'text-warm-900', bg = 'bg-gray-100' }) {
    return (
        <Card className="flex items-center gap-3">
            <div className={`flex h-11 w-11 items-center justify-center rounded-xl ${bg} ${accent}`}>
                <Icon className="h-5 w-5" />
            </div>
            <div>
                <p className="text-xs uppercase tracking-wide text-warm-500">{label}</p>
                <p className={`text-lg font-extrabold ${accent}`}>{value}</p>
            </div>
        </Card>
    );
}

export default function MiCaja() {
    const toast = useToast();
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);

    const [abrirOpen, setAbrirOpen] = useState(false);
    const [montoInicial, setMontoInicial] = useState('');
    const [cerrarOpen, setCerrarOpen] = useState(false);
    const [montoContado, setMontoContado] = useState('');
    const [saving, setSaving] = useState(false);

    const load = useCallback(async () => {
        setLoading(true);
        try {
            const res = await api.get('/mi-caja');
            setData(res.data);
        } catch {
            toast.error('No se pudo cargar tu caja.');
        } finally {
            setLoading(false);
        }
    }, [toast]);

    useEffect(() => {
        load();
    }, [load]);

    const abrir = async () => {
        setSaving(true);
        try {
            const res = await api.post('/mi-caja/abrir', { monto_inicial: Number(montoInicial) || 0 });
            setData(res.data);
            setAbrirOpen(false);
            setMontoInicial('');
            toast.success('Caja abierta.');
        } catch (err) {
            toast.error(err.response?.data?.message ?? 'No se pudo abrir la caja.');
        } finally {
            setSaving(false);
        }
    };

    const cerrar = async () => {
        setSaving(true);
        try {
            const res = await api.post('/mi-caja/cerrar', { monto_contado: Number(montoContado) || 0 });
            setData(res.data);
            setCerrarOpen(false);
            setMontoContado('');
            toast.success('Caja cerrada. Arqueo registrado.');
        } catch (err) {
            toast.error(err.response?.data?.message ?? 'No se pudo cerrar la caja.');
        } finally {
            setSaving(false);
        }
    };

    if (loading) {
        return (
            <Layout>
                <div className="flex items-center justify-center py-24">
                    <Spinner size="lg" className="text-primary-600" />
                </div>
            </Layout>
        );
    }

    const caja = data?.caja;
    const apertura = data?.apertura;
    const resumen = data?.resumen;
    const esperado = resumen?.esperado ?? 0;
    const diferencia = (Number(montoContado) || 0) - esperado;

    return (
        <Layout>
            <PageHeader title="Mi Caja" description="Abre y cierra la caja asignada a tu usuario" />

            {!caja ? (
                <Alert variant="warning">
                    No tienes una caja asignada. Pide a un administrador que te asigne una en <strong>Tesorería → Cajas</strong>.
                </Alert>
            ) : (
                <>
                    {/* Encabezado de la caja */}
                    <Card className="mb-6 flex flex-wrap items-center justify-between gap-4">
                        <div className="flex items-center gap-3">
                            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary-50 text-primary-600">
                                <Wallet className="h-6 w-6" />
                            </div>
                            <div>
                                <h2 className="text-lg font-bold text-warm-900">{caja.nombre}</h2>
                            </div>
                        </div>
                        {apertura ? (
                            <Badge variant="green">Abierta</Badge>
                        ) : (
                            <Badge variant="gray">Cerrada</Badge>
                        )}
                    </Card>

                    {apertura ? (
                        <>
                            <p className="mb-3 text-sm text-warm-500">
                                Abierta desde el <strong>{fechaHora(apertura.fecha_apertura)}</strong>
                            </p>
                            <div className="mb-6 grid grid-cols-2 gap-3 lg:grid-cols-4">
                                <Stat icon={PiggyBank} label="Monto inicial" value={money(resumen?.monto_inicial)} />
                                <Stat icon={ArrowUpCircle} label="Ingresos" value={money(resumen?.ingresos)} accent="text-green-600" bg="bg-green-50" />
                                <Stat icon={ArrowDownCircle} label="Egresos" value={money(resumen?.egresos)} accent="text-red-600" bg="bg-red-50" />
                                <Stat icon={Wallet} label="Esperado en caja" value={money(esperado)} accent="text-primary-600" bg="bg-primary-50" />
                            </div>
                            <Button variant="danger" onClick={() => { setCerrarOpen(true); setMontoContado(''); }}>
                                <Lock className="h-4 w-4" /> Cerrar caja (arqueo)
                            </Button>
                        </>
                    ) : (
                        <Card className="flex flex-col items-center gap-3 py-10 text-center">
                            <div className="flex h-14 w-14 items-center justify-center rounded-full bg-gray-100 text-warm-500">
                                <Lock className="h-7 w-7" />
                            </div>
                            <p className="text-warm-600">Tu caja está cerrada. Ábrela para registrar movimientos.</p>
                            <Button onClick={() => { setAbrirOpen(true); setMontoInicial(''); }}>
                                <LockOpen className="h-4 w-4" /> Abrir caja
                            </Button>
                        </Card>
                    )}
                </>
            )}

            {/* Modal abrir */}
            <Modal
                open={abrirOpen}
                onClose={() => setAbrirOpen(false)}
                title="Abrir caja"
                description="Ingresa el monto en efectivo con el que inicias."
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setAbrirOpen(false)}>Cancelar</Button>
                        <Button loading={saving} onClick={abrir}>Abrir caja</Button>
                    </>
                }
            >
                <Input
                    label="Monto inicial (S/)"
                    type="number"
                    min="0"
                    step="0.01"
                    placeholder="0.00"
                    value={montoInicial}
                    onChange={(e) => setMontoInicial(e.target.value)}
                />
            </Modal>

            {/* Modal cerrar */}
            <Modal
                open={cerrarOpen}
                onClose={() => setCerrarOpen(false)}
                title="Cerrar caja (arqueo)"
                description="Cuenta el efectivo físico y regístralo."
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setCerrarOpen(false)}>Cancelar</Button>
                        <Button variant="danger" loading={saving} onClick={cerrar}>Cerrar caja</Button>
                    </>
                }
            >
                <div className="space-y-3">
                    <div className="flex justify-between rounded-lg bg-gray-50 px-3 py-2 text-sm">
                        <span className="text-warm-500">Esperado en caja</span>
                        <span className="font-semibold text-warm-900">{money(esperado)}</span>
                    </div>
                    <Input
                        label="Monto contado (S/)"
                        type="number"
                        min="0"
                        step="0.01"
                        placeholder="0.00"
                        value={montoContado}
                        onChange={(e) => setMontoContado(e.target.value)}
                    />
                    {montoContado !== '' && Math.abs(diferencia) > 0.001 && (
                        <div className={`rounded-lg px-3 py-2 text-sm font-medium ${diferencia < 0 ? 'bg-red-50 text-red-700' : 'bg-amber-50 text-amber-700'}`}>
                            {diferencia < 0 ? 'Faltante' : 'Sobrante'}: {money(Math.abs(diferencia))}
                        </div>
                    )}
                </div>
            </Modal>
        </Layout>
    );
}
