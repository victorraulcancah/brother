import { useCallback, useEffect, useState } from 'react';
import { ArrowDownCircle, ArrowUpCircle } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal, Select } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const fecha = (v) => {
    if (!v) return '—';
    const s = String(v).slice(0, 10);
    if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return new Date(`${s}T00:00:00`).toLocaleDateString('es-PE');
    return new Date(v).toLocaleString('es-PE');
};

const emptyForm = (tipo) => ({
    tipo,
    motivo_movimiento_id: '',
    caja_id: '',
    metodo: '', // '' | 'efectivo' | 'transferencia:<id>' | 'billetera:<id>'
    numero_operacion: '',
    monto: '',
    fecha: new Date().toISOString().slice(0, 10),
    descripcion: '',
});

const metodoLabel = (row) => {
    if (row.cuenta_bancaria) return `Transf. · ${row.cuenta_bancaria.alias || row.cuenta_bancaria.numero_cuenta}`;
    if (row.billetera) return row.billetera.nombre;
    return 'Efectivo';
};

export default function MovimientosCaja() {
    const toast = useToast();
    const [rows, setRows] = useState([]);
    const [motivos, setMotivos] = useState([]);
    const [cajas, setCajas] = useState([]);
    const [miCajaId, setMiCajaId] = useState(null);
    const [esSuperAdmin, setEsSuperAdmin] = useState(false);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [fTipo, setFTipo] = useState('');

    const [modalOpen, setModalOpen] = useState(false);
    const [form, setForm] = useState(emptyForm('ingreso'));
    const [formErrors, setFormErrors] = useState({});
    const [saving, setSaving] = useState(false);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const [movRes, motivosRes, cajasRes, meRes] = await Promise.all([
                api.get('/movimientos-caja'),
                api.get('/motivos-movimiento?ambito=caja'),
                api.get('/cajas'),
                api.get('/me'),
            ]);
            setRows(asList(movRes));
            setMotivos(asList(motivosRes));
            setCajas(asList(cajasRes));
            const me = meRes.data ?? meRes;
            setMiCajaId(me.caja_id ?? null);
            const rolNombres = Array.isArray(me.roles) ? me.roles.map((r) => r.name) : [];
            setEsSuperAdmin(rolNombres.includes('super-admin'));
        } catch {
            setError('No se pudieron cargar los movimientos de caja.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    const openCreate = (tipo) => {
        setForm(emptyForm(tipo));
        setFormErrors({});
        setModalOpen(true);
    };

    const cajaActualId = esSuperAdmin ? form.caja_id : miCajaId;
    const caja = cajas.find((c) => String(c.id) === String(cajaActualId));

    // Opciones de método según lo que acepta la caja.
    const metodoOptions = [{ value: '', label: 'Selecciona un método' }];
    if (caja?.acepta_efectivo) metodoOptions.push({ value: 'efectivo', label: 'Efectivo' });
    (caja?.cuentas_bancarias ?? []).forEach((c) =>
        metodoOptions.push({ value: `transferencia:${c.id}`, label: `Transferencia · ${c.alias || c.numero_cuenta}` }),
    );
    (caja?.billeteras ?? []).forEach((b) => metodoOptions.push({ value: `billetera:${b.id}`, label: b.nombre }));

    const requiereOperacion = form.metodo.startsWith('transferencia:') || form.metodo.startsWith('billetera:');

    const motivosTipo = motivos.filter((m) => (form.tipo === 'ingreso' ? m.tipo === 'entrada' : m.tipo === 'salida'));

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSaving(true);
        setFormErrors({});

        let forma = 'efectivo';
        let cuenta_bancaria_id = null;
        let billetera_id = null;
        if (form.metodo.startsWith('transferencia:')) {
            forma = 'transferencia';
            cuenta_bancaria_id = Number(form.metodo.split(':')[1]);
        } else if (form.metodo.startsWith('billetera:')) {
            forma = 'billetera';
            billetera_id = Number(form.metodo.split(':')[1]);
        }

        const payload = {
            tipo: form.tipo,
            motivo_movimiento_id: form.motivo_movimiento_id,
            caja_id: esSuperAdmin ? form.caja_id : miCajaId,
            forma,
            cuenta_bancaria_id,
            billetera_id,
            numero_operacion: form.numero_operacion || null,
            monto: form.monto,
            fecha: form.fecha,
            descripcion: form.descripcion || null,
        };
        try {
            await api.post('/movimientos-caja', payload);
            toast.success(form.tipo === 'ingreso' ? 'Ingreso registrado.' : 'Egreso registrado.');
            setModalOpen(false);
            await load();
        } catch (err) {
            if (err.response?.status === 422) {
                const validation = err.response.data?.errors ?? {};
                setFormErrors(Object.fromEntries(Object.entries(validation).map(([k, v]) => [k, v[0]])));
                if (validation.forma || validation.caja_id) toast.error(validation.forma?.[0] ?? validation.caja_id?.[0]);
            } else {
                toast.error('No se pudo registrar el movimiento.');
            }
        } finally {
            setSaving(false);
        }
    };

    const columns = [
        { key: 'fecha', label: 'Fecha', render: (row) => fecha(row.fecha) },
        { key: 'apertura', label: 'Caja', render: (row) => row.apertura?.caja?.nombre ?? '—' },
        {
            key: 'tipo',
            label: 'Tipo',
            render: (row) => (
                <Badge variant={row.tipo === 'ingreso' ? 'green' : 'red'}>{row.tipo === 'ingreso' ? 'Ingreso' : 'Egreso'}</Badge>
            ),
        },
        {
            key: 'motivo',
            label: 'Motivo',
            render: (row) => (
                <span className="text-sm">
                    {row.motivo?.nombre ?? <span className="text-gray-400">—</span>}
                    {row.descripcion && <span className="block text-xs text-gray-400">{row.descripcion}</span>}
                </span>
            ),
        },
        { key: 'metodo', label: 'Método', render: (row) => metodoLabel(row) },
        { key: 'numero_operacion', label: 'N° Operación', render: (row) => row.numero_operacion || <span className="text-gray-400">—</span> },
        {
            key: 'monto',
            label: 'Monto',
            align: 'right',
            render: (row) => (
                <span className={row.tipo === 'ingreso' ? 'text-green-600' : 'text-red-600'}>
                    {row.tipo === 'ingreso' ? '+' : '-'} {money(row.monto)}
                </span>
            ),
        },
    ];

    return (
        <Layout>
            <PageHeader
                title="Movimientos de Caja"
                description="Historial de ingresos y egresos por caja"
                actions={
                    <>
                        <Button variant="success" onClick={() => openCreate('ingreso')}>
                            <ArrowUpCircle className="h-4 w-4" /> Nuevo ingreso
                        </Button>
                        <Button variant="danger" onClick={() => openCreate('egreso')}>
                            <ArrowDownCircle className="h-4 w-4" /> Nuevo egreso
                        </Button>
                    </>
                }
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            <DataTable
                columns={columns}
                rows={fTipo ? rows.filter((r) => r.tipo === fTipo) : rows}
                loading={loading}
                searchPlaceholder="Buscar movimientos..."
                emptyMessage="Aún no hay movimientos de caja registrados."
                filterable
                filterCount={fTipo ? 1 : 0}
                filters={
                    <div className="space-y-2">
                        <Select
                            label="Tipo"
                            value={fTipo}
                            onChange={(e) => setFTipo(e.target.value)}
                            options={[
                                { value: '', label: 'Todos' },
                                { value: 'ingreso', label: 'Ingresos' },
                                { value: 'egreso', label: 'Egresos' },
                            ]}
                        />
                        {fTipo && (
                            <button onClick={() => setFTipo('')} className="text-xs font-medium text-red-600 hover:text-red-700">
                                Limpiar filtros
                            </button>
                        )}
                    </div>
                }
            />

            <Modal
                open={modalOpen}
                onClose={() => setModalOpen(false)}
                title={form.tipo === 'ingreso' ? 'Nuevo ingreso' : 'Nuevo egreso'}
                description={form.tipo === 'ingreso' ? 'Registra un ingreso de dinero a la caja' : 'Registra un egreso de dinero de la caja'}
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>Cancelar</Button>
                        <Button type="submit" form="movimiento-form" loading={saving}>
                            {form.tipo === 'ingreso' ? 'Registrar ingreso' : 'Registrar egreso'}
                        </Button>
                    </>
                }
            >
                <form id="movimiento-form" onSubmit={handleSubmit} className="space-y-4" noValidate>
                    <div className="grid grid-cols-2 gap-3">
                        <Select
                            label="Motivo"
                            value={form.motivo_movimiento_id}
                            onChange={(e) => setForm((prev) => ({ ...prev, motivo_movimiento_id: e.target.value }))}
                            options={[{ value: '', label: 'Selecciona un motivo' }, ...motivosTipo.map((m) => ({ value: String(m.id), label: m.nombre }))]}
                            error={formErrors.motivo_movimiento_id}
                        />
                        {esSuperAdmin ? (
                            <Select
                                label="Caja"
                                value={form.caja_id}
                                onChange={(e) => setForm((prev) => ({ ...prev, caja_id: e.target.value, metodo: '' }))}
                                options={[{ value: '', label: 'Selecciona una caja' }, ...cajas.map((c) => ({ value: String(c.id), label: c.nombre }))]}
                                error={formErrors.caja_id}
                            />
                        ) : (
                            <div>
                                <label className="mb-1 block text-sm font-medium text-gray-700">Caja</label>
                                <p className="rounded-md bg-gray-50 px-3 py-2 text-sm text-gray-600 ring-1 ring-inset ring-gray-200">
                                    {caja?.nombre ?? 'Sin caja asignada'}
                                </p>
                            </div>
                        )}
                    </div>
                    <div className="grid grid-cols-2 gap-3">
                        <Select
                            label="Método"
                            value={form.metodo}
                            onChange={(e) => setForm((prev) => ({ ...prev, metodo: e.target.value }))}
                            options={metodoOptions}
                            error={formErrors.forma || formErrors.cuenta_bancaria_id || formErrors.billetera_id}
                        />
                        <Input
                            label="Monto"
                            type="number"
                            min="0.01"
                            step="0.01"
                            placeholder="0.00"
                            value={form.monto}
                            onChange={(e) => setForm((prev) => ({ ...prev, monto: e.target.value }))}
                            error={formErrors.monto}
                        />
                    </div>
                    {requiereOperacion && (
                        <Input
                            label="Número de operación (opcional)"
                            placeholder="Ej: 0045-885123"
                            value={form.numero_operacion}
                            onChange={(e) => setForm((prev) => ({ ...prev, numero_operacion: e.target.value }))}
                            error={formErrors.numero_operacion}
                        />
                    )}
                    <div className="grid grid-cols-2 gap-3">
                        <Input
                            label="Fecha"
                            type="date"
                            value={form.fecha}
                            onChange={(e) => setForm((prev) => ({ ...prev, fecha: e.target.value }))}
                            error={formErrors.fecha}
                        />
                        <Input
                            label="Descripción (opcional)"
                            placeholder="Ej: Recibo de luz de julio"
                            value={form.descripcion}
                            onChange={(e) => setForm((prev) => ({ ...prev, descripcion: e.target.value }))}
                            error={formErrors.descripcion}
                        />
                    </div>
                    {!caja && (
                        <Alert variant="warning">
                            {esSuperAdmin ? 'Selecciona una caja para ver sus métodos.' : 'No tienes una caja asignada. Pide al administrador que te asigne una.'}
                        </Alert>
                    )}
                </form>
            </Modal>
        </Layout>
    );
}
