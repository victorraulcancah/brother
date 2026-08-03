import { useCallback, useEffect, useState } from 'react';
import { ArrowDownCircle, ArrowUpCircle, Lock, LockOpen, PiggyBank, Wallet } from 'lucide-react';
import api from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader from '../components/PageHeader';
import MetodoCajaPicker from '../components/MetodoCajaPicker';
import { Alert, Badge, Button, Card, DataTable, Input, Modal, Select, Spinner } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const fechaHora = (v) => (v ? new Date(v).toLocaleString('es-PE') : '—');
const fechaCorta = (v) => {
    if (!v) return '—';
    const s = String(v).slice(0, 10);
    return /^\d{4}-\d{2}-\d{2}$/.test(s) ? new Date(`${s}T00:00:00`).toLocaleDateString('es-PE') : new Date(v).toLocaleDateString('es-PE');
};

const metodoLabel = (row) => {
    if (row.cuenta_bancaria) return `Transf. · ${row.cuenta_bancaria.alias || row.cuenta_bancaria.numero_cuenta}`;
    if (row.billetera) return row.billetera.nombre;
    return 'Efectivo';
};

const emptyMov = () => ({ motivo_movimiento_id: '', metodoTipo: '', cuentaId: '', billeteraId: '', numero_operacion: '', monto: '', descripcion: '' });

function Stat({ icon: Icon, label, value, accent = 'text-warm-900', bg = 'bg-gray-100' }) {
    return (
        <Card className="flex items-center gap-3">
            <div className={`flex h-11 w-11 items-center justify-center rounded-xl ${bg} ${accent}`}><Icon className="h-5 w-5" /></div>
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
    const [motivos, setMotivos] = useState([]);
    const [loading, setLoading] = useState(true);

    const [abrirOpen, setAbrirOpen] = useState(false);
    const [montoInicial, setMontoInicial] = useState('');
    const [cerrarOpen, setCerrarOpen] = useState(false);
    const [montoContado, setMontoContado] = useState('');

    const [regTipo, setRegTipo] = useState(null); // 'ingreso' | 'egreso'
    const [mov, setMov] = useState(emptyMov());
    const [saving, setSaving] = useState(false);

    const load = useCallback(async () => {
        setLoading(true);
        try {
            const [miRes, motRes] = await Promise.all([api.get('/mi-caja'), api.get('/motivos-movimiento?ambito=caja')]);
            setData(miRes.data);
            setMotivos(Array.isArray(motRes.data) ? motRes.data : (motRes.data?.data ?? []));
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

    const registrar = async () => {
        setSaving(true);
        try {
            await api.post('/movimientos-caja', {
                tipo: regTipo,
                motivo_movimiento_id: mov.motivo_movimiento_id,
                forma: mov.metodoTipo,
                cuenta_bancaria_id: mov.cuentaId || null,
                billetera_id: mov.billeteraId || null,
                numero_operacion: mov.numero_operacion || null,
                monto: mov.monto,
                descripcion: mov.descripcion || null,
            });
            setRegTipo(null);
            toast.success(regTipo === 'ingreso' ? 'Ingreso registrado.' : 'Gasto registrado.');
            await load();
        } catch (err) {
            const v = err.response?.data?.errors ?? {};
            toast.error(Object.values(v)[0]?.[0] ?? err.response?.data?.message ?? 'No se pudo registrar.');
        } finally {
            setSaving(false);
        }
    };

    if (loading) {
        return (
            <Layout>
                <div className="flex items-center justify-center py-24"><Spinner size="lg" className="text-primary-600" /></div>
            </Layout>
        );
    }

    const caja = data?.caja;
    const apertura = data?.apertura;
    const resumen = data?.resumen;
    const movimientos = data?.movimientos ?? [];
    const esperado = resumen?.esperado ?? 0;
    const diferencia = (Number(montoContado) || 0) - esperado;

    // Opciones de método según lo que acepta la caja.
    const motivosTipo = motivos.filter(
        (m) => !m.es_sistema && (regTipo === 'ingreso' ? m.tipo === 'entrada' : m.tipo === 'salida'),
    );
    const requiereOperacion = mov.metodoTipo === 'transferencia' || mov.metodoTipo === 'billetera';

    const columns = [
        { key: 'fecha', label: 'Fecha', render: (r) => fechaCorta(r.fecha) },
        { key: 'tipo', label: 'Tipo', render: (r) => <Badge variant={r.tipo === 'ingreso' ? 'green' : 'red'}>{r.tipo === 'ingreso' ? 'Ingreso' : 'Gasto'}</Badge> },
        { key: 'motivo', label: 'Motivo', render: (r) => r.motivo?.nombre ?? '—' },
        { key: 'metodo', label: 'Método', render: (r) => metodoLabel(r) },
        { key: 'monto', label: 'Monto', align: 'right', render: (r) => <span className={r.tipo === 'ingreso' ? 'text-green-600' : 'text-red-600'}>{r.tipo === 'ingreso' ? '+' : '-'} {money(r.monto)}</span> },
    ];

    const openReg = (tipo) => {
        setRegTipo(tipo);
        setMov(emptyMov());
    };

    return (
        <Layout>
            <PageHeader title="Mi Caja" description="Abre tu caja, registra ingresos y gastos, y ciérrala con arqueo" />

            {!caja ? (
                <Alert variant="warning">
                    No tienes una caja asignada. Pide a un administrador que te asigne una en <strong>Tesorería → Cajas</strong>.
                </Alert>
            ) : (
                <>
                    <Card className="mb-6 flex flex-wrap items-center justify-between gap-4">
                        <div className="flex items-center gap-3">
                            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary-50 text-primary-600"><Wallet className="h-6 w-6" /></div>
                            <div>
                                <h2 className="text-lg font-bold text-warm-900">{caja.nombre}</h2>
                                {apertura && <p className="text-sm text-warm-500">Abierta desde {fechaHora(apertura.fecha_apertura)}</p>}
                            </div>
                        </div>
                        {apertura ? <Badge variant="green">Abierta</Badge> : <Badge variant="gray">Cerrada</Badge>}
                    </Card>

                    {apertura ? (
                        <>
                            <div className="mb-4 flex flex-wrap gap-2">
                                <Button variant="success" onClick={() => openReg('ingreso')}><ArrowUpCircle className="h-4 w-4" /> Nuevo ingreso</Button>
                                <Button variant="danger" onClick={() => openReg('egreso')}><ArrowDownCircle className="h-4 w-4" /> Nuevo gasto</Button>
                                <Button variant="secondary" onClick={() => { setCerrarOpen(true); setMontoContado(''); }}><Lock className="h-4 w-4" /> Cerrar caja</Button>
                            </div>

                            <div className="mb-6 grid grid-cols-2 gap-3 lg:grid-cols-4">
                                <Stat icon={PiggyBank} label="Monto inicial" value={money(resumen?.monto_inicial)} />
                                <Stat icon={ArrowUpCircle} label="Ingresos" value={money(resumen?.ingresos)} accent="text-green-600" bg="bg-green-50" />
                                <Stat icon={ArrowDownCircle} label="Gastos" value={money(resumen?.egresos)} accent="text-red-600" bg="bg-red-50" />
                                <Stat icon={Wallet} label="Esperado en caja" value={money(esperado)} accent="text-primary-600" bg="bg-primary-50" />
                            </div>

                            <h3 className="mb-2 text-sm font-bold text-warm-900">Movimientos de esta apertura</h3>
                            <DataTable columns={columns} rows={movimientos} searchable={false} toggleableColumns={false} emptyMessage="Aún no hay movimientos. Registra un ingreso o gasto." maxHeight="50vh" />
                        </>
                    ) : (
                        <Card className="flex flex-col items-center gap-3 py-10 text-center">
                            <div className="flex h-14 w-14 items-center justify-center rounded-full bg-gray-100 text-warm-500"><Lock className="h-7 w-7" /></div>
                            <p className="text-warm-600">Tu caja está cerrada. Ábrela para registrar movimientos.</p>
                            <Button onClick={() => { setAbrirOpen(true); setMontoInicial(''); }}><LockOpen className="h-4 w-4" /> Abrir caja</Button>
                        </Card>
                    )}
                </>
            )}

            {/* Modal abrir */}
            <Modal open={abrirOpen} onClose={() => setAbrirOpen(false)} title="Abrir caja" description="Ingresa el monto en efectivo con el que inicias." size="sm"
                footer={<><Button variant="secondary" onClick={() => setAbrirOpen(false)}>Cancelar</Button><Button loading={saving} onClick={abrir}>Abrir caja</Button></>}>
                <Input label="Monto inicial (S/)" type="number" min="0" step="0.01" placeholder="0.00" value={montoInicial} onChange={(e) => setMontoInicial(e.target.value)} />
            </Modal>

            {/* Modal cerrar */}
            <Modal open={cerrarOpen} onClose={() => setCerrarOpen(false)} title="Cerrar caja (arqueo)" description="Cuenta el efectivo físico y regístralo." size="sm"
                footer={<><Button variant="secondary" onClick={() => setCerrarOpen(false)}>Cancelar</Button><Button variant="danger" loading={saving} onClick={cerrar}>Cerrar caja</Button></>}>
                <div className="space-y-3">
                    <div className="flex justify-between rounded-lg bg-gray-50 px-3 py-2 text-sm">
                        <span className="text-warm-500">Esperado en caja</span>
                        <span className="font-semibold text-warm-900">{money(esperado)}</span>
                    </div>
                    <Input label="Monto contado (S/)" type="number" min="0" step="0.01" placeholder="0.00" value={montoContado} onChange={(e) => setMontoContado(e.target.value)} />
                    {montoContado !== '' && Math.abs(diferencia) > 0.001 && (
                        <div className={`rounded-lg px-3 py-2 text-sm font-medium ${diferencia < 0 ? 'bg-red-50 text-red-700' : 'bg-amber-50 text-amber-700'}`}>
                            {diferencia < 0 ? 'Faltante' : 'Sobrante'}: {money(Math.abs(diferencia))}
                        </div>
                    )}
                </div>
            </Modal>

            {/* Modal registrar ingreso/gasto */}
            <Modal
                open={Boolean(regTipo)}
                onClose={() => setRegTipo(null)}
                title={regTipo === 'ingreso' ? 'Nuevo ingreso' : 'Nuevo gasto'}
                footer={<><Button variant="secondary" onClick={() => setRegTipo(null)}>Cancelar</Button><Button loading={saving} onClick={registrar}>{regTipo === 'ingreso' ? 'Registrar ingreso' : 'Registrar gasto'}</Button></>}>
                <div className="space-y-4">
                    <Select label="Motivo" value={mov.motivo_movimiento_id} onChange={(e) => setMov((p) => ({ ...p, motivo_movimiento_id: e.target.value }))}
                        options={[{ value: '', label: 'Selecciona un motivo' }, ...motivosTipo.map((m) => ({ value: String(m.id), label: m.nombre }))]} />
                    <MetodoCajaPicker
                        cuentas={caja?.cuentas_bancarias ?? []}
                        billeteras={caja?.billeteras ?? []}
                        aceptaEfectivo={caja?.acepta_efectivo}
                        tipo={mov.metodoTipo}
                        cuentaId={mov.cuentaId}
                        billeteraId={mov.billeteraId}
                        onChange={({ tipo, cuentaId, billeteraId }) => setMov((p) => ({ ...p, metodoTipo: tipo, cuentaId, billeteraId }))}
                    />
                    {requiereOperacion && (
                        <Input label="N° de operación (opcional)" placeholder="Ej: 0045-885123" value={mov.numero_operacion} onChange={(e) => setMov((p) => ({ ...p, numero_operacion: e.target.value }))} />
                    )}
                    <Input label="Monto (S/)" type="number" min="0.01" step="0.01" placeholder="0.00" value={mov.monto} onChange={(e) => setMov((p) => ({ ...p, monto: e.target.value }))} />
                    <Input label="Descripción (opcional)" placeholder="Ej: recibo de luz" value={mov.descripcion} onChange={(e) => setMov((p) => ({ ...p, descripcion: e.target.value }))} />
                </div>
            </Modal>
        </Layout>
    );
}
