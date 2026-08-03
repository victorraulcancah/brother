import { Select } from './ui';

const cuentaLabel = (c) => [c.banco?.nombre, c.alias, c.numero_cuenta].filter(Boolean).join(' · ');
const billeteraLabel = (b) => [b.nombre, b.titular, b.numero_asociado].filter(Boolean).join(' · ');

/**
 * Selector de método de pago de una caja, por tipo (Efectivo / Transferencia / Billetera).
 * Al elegir transferencia o billetera se despliega el detalle (banco+cuenta / titular+teléfono).
 *
 * value = { tipo, cuentaId, billeteraId }
 */
export default function MetodoCajaPicker({ caja, tipo, cuentaId, billeteraId, onChange, error }) {
    const tipos = [{ value: '', label: 'Selecciona un tipo' }];
    if (caja?.acepta_efectivo) tipos.push({ value: 'efectivo', label: 'Efectivo' });
    if ((caja?.cuentas_bancarias ?? []).length) tipos.push({ value: 'transferencia', label: 'Transferencia' });
    if ((caja?.billeteras ?? []).length) tipos.push({ value: 'billetera', label: 'Billetera digital' });

    return (
        <div className="space-y-2">
            <Select
                label="Tipo de método"
                value={tipo}
                onChange={(e) => onChange({ tipo: e.target.value, cuentaId: '', billeteraId: '' })}
                options={tipos}
                error={error}
            />
            {tipo === 'transferencia' && (
                <Select
                    label="Cuenta bancaria"
                    value={cuentaId}
                    onChange={(e) => onChange({ tipo, cuentaId: e.target.value, billeteraId: '' })}
                    options={[
                        { value: '', label: 'Selecciona la cuenta' },
                        ...(caja?.cuentas_bancarias ?? []).map((c) => ({ value: String(c.id), label: cuentaLabel(c) })),
                    ]}
                />
            )}
            {tipo === 'billetera' && (
                <Select
                    label="Billetera"
                    value={billeteraId}
                    onChange={(e) => onChange({ tipo, cuentaId: '', billeteraId: e.target.value })}
                    options={[
                        { value: '', label: 'Selecciona la billetera' },
                        ...(caja?.billeteras ?? []).map((b) => ({ value: String(b.id), label: billeteraLabel(b) })),
                    ]}
                />
            )}
        </div>
    );
}
