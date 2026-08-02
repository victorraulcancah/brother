import { useEffect, useMemo, useState } from 'react';
import { Check, Pencil, Plus, Trash2, Wallet, X } from 'lucide-react';
import api from '../lib/api';
import { useToast } from '../lib/toast';
import { Alert, Badge, Button, Input, Modal, Select } from './ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const hoy = () => new Date().toISOString().slice(0, 10);

const FORMAS_PAGO = [
    { value: 'efectivo', label: 'Efectivo' },
    { value: 'transferencia', label: 'Transferencia' },
    { value: 'tarjeta', label: 'Tarjeta' },
    { value: 'yape', label: 'Yape' },
    { value: 'plin', label: 'Plin' },
    { value: 'otro', label: 'Otro' },
];

const formaLabel = (v) => FORMAS_PAGO.find((f) => f.value === v)?.label ?? v;

const estadoBadge = (estado) => {
    const map = { pendiente: 'red', parcial: 'amber', pagado: 'green', anulado: 'gray' };
    return <Badge variant={map[estado] ?? 'gray'}>{estado ?? '—'}</Badge>;
};

const emptyLinea = () => ({ forma_pago: 'efectivo', monto: '', referencia: '' });

/**
 * Modal reutilizable para gestionar los pagos de una cuenta por cobrar o pagar.
 * Soporta registrar pagos mixtos (varias formas en una operación), editar y anular.
 *
 * @param {'cobrar'|'pagar'} tipo
 */
export default function PagosCuentaModal({ open, onClose, cuenta, tipo, onSaved }) {
    const toast = useToast();
    const basePath = tipo === 'cobrar' ? '/cuentas-por-cobrar' : '/cuentas-por-pagar';
    const esCobrar = tipo === 'cobrar';

    const [state, setState] = useState(cuenta);
    const [lineas, setLineas] = useState([emptyLinea()]);
    const [editId, setEditId] = useState(null);
    const [editForm, setEditForm] = useState(emptyLinea());
    const [saving, setSaving] = useState(false);

    useEffect(() => {
        setState(cuenta);
        setLineas([emptyLinea()]);
        setEditId(null);
    }, [cuenta]);

    const pagos = useMemo(() => (Array.isArray(state?.pagos) ? state.pagos : []), [state]);
    const nombre = esCobrar ? state?.cliente?.nombre : state?.proveedor?.nombre;
    const anulada = state?.estado === 'anulado';
    const saldo = Number(state?.saldo) || 0;
    const puedePagar = !anulada && saldo > 0.005;

    const nuevoTotal = lineas.reduce((acc, l) => acc + (Number(l.monto) || 0), 0);

    const setLinea = (i, patch) => setLineas((p) => p.map((l, idx) => (idx === i ? { ...l, ...patch } : l)));
    const addLinea = () => setLineas((p) => [...p, emptyLinea()]);
    const removeLinea = (i) => setLineas((p) => (p.length === 1 ? p : p.filter((_, idx) => idx !== i)));

    const apiError = (err, fallback) => {
        const msg = err.response?.data?.message;
        const first = err.response?.data?.errors ? Object.values(err.response.data.errors)[0]?.[0] : null;
        toast.error(first ?? msg ?? fallback);
    };

    const registrar = async () => {
        const validos = lineas
            .filter((l) => Number(l.monto) > 0)
            .map((l) => ({ forma_pago: l.forma_pago, monto: Number(l.monto), referencia: l.referencia || null }));
        if (validos.length === 0) {
            toast.error('Agrega al menos un pago con monto.');
            return;
        }
        if (nuevoTotal > saldo + 0.01) {
            toast.error('El pago excede el saldo pendiente.');
            return;
        }
        setSaving(true);
        try {
            const res = await api.post(`${basePath}/${state.id}/pagos`, { fecha: hoy(), pagos: validos });
            setState(res.data);
            setLineas([emptyLinea()]);
            toast.success('Pago registrado.');
            onSaved?.(res.data);
        } catch (err) {
            apiError(err, 'No se pudo registrar el pago.');
        } finally {
            setSaving(false);
        }
    };

    const startEdit = (p) => {
        setEditId(p.id);
        setEditForm({ forma_pago: p.forma_pago, monto: String(p.monto), referencia: p.referencia ?? '' });
    };

    const guardarEdit = async () => {
        if (!(Number(editForm.monto) > 0)) {
            toast.error('El monto debe ser mayor a 0.');
            return;
        }
        setSaving(true);
        try {
            const res = await api.put(`${basePath}/pagos/${editId}`, {
                forma_pago: editForm.forma_pago,
                monto: Number(editForm.monto),
                referencia: editForm.referencia || null,
            });
            setState(res.data);
            setEditId(null);
            toast.success('Pago actualizado.');
            onSaved?.(res.data);
        } catch (err) {
            apiError(err, 'No se pudo actualizar el pago.');
        } finally {
            setSaving(false);
        }
    };

    const anular = async (p) => {
        if (!window.confirm(`¿Anular este pago de ${money(p.monto)}? Se revertirá el movimiento de caja.`)) return;
        setSaving(true);
        try {
            const res = await api.delete(`${basePath}/pagos/${p.id}`);
            setState(res.data);
            toast.success('Pago anulado.');
            onSaved?.(res.data);
        } catch (err) {
            apiError(err, 'No se pudo anular el pago.');
        } finally {
            setSaving(false);
        }
    };

    if (!state) return null;

    return (
        <Modal
            open={open}
            onClose={onClose}
            size="xl"
            title={`Pagos — ${nombre ?? (esCobrar ? 'Cliente' : 'Proveedor')}`}
            description={esCobrar ? 'Cobros del cliente' : 'Pagos al proveedor'}
            footer={<Button variant="secondary" onClick={onClose}>Cerrar</Button>}
        >
            {/* Resumen */}
            <div className="mb-4 grid grid-cols-2 gap-3 rounded-xl border border-edge bg-gray-50 p-4 sm:grid-cols-4">
                <div>
                    <p className="text-xs uppercase tracking-wide text-warm-500">Total</p>
                    <p className="font-semibold text-warm-900">{money(state.monto_total)}</p>
                </div>
                <div>
                    <p className="text-xs uppercase tracking-wide text-warm-500">Pagado</p>
                    <p className="font-semibold text-green-600">{money(state.monto_pagado)}</p>
                </div>
                <div>
                    <p className="text-xs uppercase tracking-wide text-warm-500">Saldo</p>
                    <p className="font-semibold text-red-600">{money(state.saldo)}</p>
                </div>
                <div>
                    <p className="text-xs uppercase tracking-wide text-warm-500">Estado</p>
                    <div className="mt-0.5">{estadoBadge(state.estado)}</div>
                </div>
            </div>

            {/* Pagos registrados */}
            <h3 className="mb-2 text-xs font-bold uppercase tracking-wide text-warm-500">Pagos registrados</h3>
            {pagos.length === 0 ? (
                <p className="mb-4 rounded-lg border border-dashed border-edge px-3 py-4 text-center text-sm text-warm-500">
                    Aún no hay pagos registrados.
                </p>
            ) : (
                <div className="mb-5 divide-y divide-gray-100 rounded-xl border border-edge">
                    {pagos.map((p) =>
                        editId === p.id ? (
                            <div key={p.id} className="flex flex-wrap items-center gap-2 bg-amber-50 p-2">
                                <Select
                                    value={editForm.forma_pago}
                                    onChange={(e) => setEditForm((f) => ({ ...f, forma_pago: e.target.value }))}
                                    options={FORMAS_PAGO}
                                    className="min-w-[130px] flex-1"
                                />
                                <Input
                                    type="number" min="0" step="any" placeholder="Monto"
                                    value={editForm.monto}
                                    onChange={(e) => setEditForm((f) => ({ ...f, monto: e.target.value }))}
                                    className="w-28 text-right"
                                />
                                <Input
                                    placeholder="Referencia"
                                    value={editForm.referencia}
                                    onChange={(e) => setEditForm((f) => ({ ...f, referencia: e.target.value }))}
                                    className="w-32"
                                />
                                <button type="button" onClick={guardarEdit} disabled={saving}
                                    className="rounded-md p-2 text-green-600 transition hover:bg-green-100" aria-label="Guardar">
                                    <Check className="h-4 w-4" />
                                </button>
                                <button type="button" onClick={() => setEditId(null)}
                                    className="rounded-md p-2 text-gray-500 transition hover:bg-gray-100" aria-label="Cancelar">
                                    <X className="h-4 w-4" />
                                </button>
                            </div>
                        ) : (
                            <div key={p.id} className="flex items-center gap-3 px-3 py-2 text-sm">
                                <Badge variant="blue">{formaLabel(p.forma_pago)}</Badge>
                                <span className="font-medium text-warm-900">{money(p.monto)}</span>
                                <span className="text-warm-500">{p.fecha}</span>
                                {p.referencia && <span className="text-warm-400">· {p.referencia}</span>}
                                <div className="ml-auto flex items-center gap-1">
                                    <button type="button" onClick={() => startEdit(p)} disabled={anulada || saving}
                                        className="rounded-md p-1.5 text-blue-600 transition hover:bg-blue-50 disabled:opacity-40" aria-label="Editar">
                                        <Pencil className="h-4 w-4" />
                                    </button>
                                    <button type="button" onClick={() => anular(p)} disabled={anulada || saving}
                                        className="rounded-md p-1.5 text-red-600 transition hover:bg-red-50 disabled:opacity-40" aria-label="Anular">
                                        <Trash2 className="h-4 w-4" />
                                    </button>
                                </div>
                            </div>
                        ),
                    )}
                </div>
            )}

            {/* Registrar nuevo pago (mixto) */}
            {anulada ? (
                <Alert variant="warning">Esta cuenta está anulada.</Alert>
            ) : !puedePagar ? (
                <Alert variant="success">Cuenta saldada. No hay saldo pendiente.</Alert>
            ) : (
                <div className="rounded-xl border border-edge p-4">
                    <div className="mb-3 flex items-center justify-between">
                        <h3 className="inline-flex items-center gap-2 text-xs font-bold uppercase tracking-wide text-warm-500">
                            <Wallet className="h-4 w-4" /> Registrar pago (mixto)
                        </h3>
                        <Button type="button" variant="ghost" size="sm" onClick={addLinea}>
                            <Plus className="h-4 w-4" /> Agregar forma
                        </Button>
                    </div>
                    <div className="space-y-2">
                        {lineas.map((l, i) => (
                            <div key={i} className="flex flex-wrap items-center gap-2">
                                <Select
                                    value={l.forma_pago}
                                    onChange={(e) => setLinea(i, { forma_pago: e.target.value })}
                                    options={FORMAS_PAGO}
                                    className="min-w-[130px] flex-1"
                                />
                                <Input
                                    type="number" min="0" step="any" placeholder="Monto"
                                    value={l.monto}
                                    onChange={(e) => setLinea(i, { monto: e.target.value })}
                                    className="w-28 text-right"
                                />
                                <Input
                                    placeholder="Referencia (opc.)"
                                    value={l.referencia}
                                    onChange={(e) => setLinea(i, { referencia: e.target.value })}
                                    className="w-36"
                                />
                                <button type="button" onClick={() => removeLinea(i)} disabled={lineas.length === 1}
                                    className="rounded-md p-2 text-red-600 transition hover:bg-red-50 disabled:opacity-40" aria-label="Quitar">
                                    <Trash2 className="h-4 w-4" />
                                </button>
                            </div>
                        ))}
                    </div>
                    <div className="mt-3 flex items-center justify-between border-t border-dashed border-edge pt-3">
                        <div className="text-sm">
                            <span className="text-warm-500">A pagar: </span>
                            <span className="font-semibold text-warm-900">{money(nuevoTotal)}</span>
                            {nuevoTotal > saldo + 0.01 && (
                                <span className="ml-2 text-red-600">excede el saldo ({money(saldo)})</span>
                            )}
                        </div>
                        <Button onClick={registrar} loading={saving} disabled={nuevoTotal <= 0}>
                            Registrar pago
                        </Button>
                    </div>
                </div>
            )}
        </Modal>
    );
}
