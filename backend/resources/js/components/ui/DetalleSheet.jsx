import { useEffect } from 'react';
import {
    Calendar,
    CalendarCheck,
    Car,
    CircleDot,
    FileText,
    Handshake,
    Lock,
    Package,
    PackageCheck,
    Phone,
    Scale,
    Store,
    StickyNote,
    Truck,
    User,
    UserCheck,
    Wallet,
} from 'lucide-react';
import Button from './Button';
import Modal from './Modal';

/** ¿La pantalla es de celular? Debe coincidir con el breakpoint `md` de Tailwind (768px). */
export const esMovil = () => typeof window !== 'undefined' && window.matchMedia('(max-width: 767px)').matches;

/** Ícono de cada dato de cabecera, según su etiqueta. Lo que no figura usa un ícono neutro. */
const ICONOS = {
    Cliente: User,
    Fecha: Calendar,
    Pago: Wallet,
    Entrega: Truck,
    Estado: CircleDot,
    'Almacén': Store,
    'Stock base': Package,
    Reservado: Lock,
    Disponible: PackageCheck,
    Motivo: FileText,
    Transporte: Truck,
    Placa: Car,
    Conductor: User,
    Bultos: Package,
    Peso: Scale,
    'Presté a': Handshake,
    'Me prestó': Handshake,
    'Doc.': FileText,
    'Tel.': Phone,
    'Registró': UserCheck,
    'Devuelto el': CalendarCheck,
    'Obs.': StickyNote,
};

/**
 * Detalle de un documento en celular. Las pantallas con lista + tabla de detalle
 * muestran la tabla solo desde `md`; en el celular, al tocar una tarjeta de la
 * lista, el detalle sube desde abajo como hoja inferior.
 *
 * icon:     ícono (lucide-react) del documento, en la cabecera
 * summary:  [{ label, value }] — datos de cabecera del documento (opcional)
 * children: normalmente un <LineCards /> con las líneas
 */
export default function DetalleSheet({ open, onClose, title, description, icon = FileText, summary, children }) {
    // Si la pantalla se agranda (girar el celular, redimensionar), la hoja se cierra:
    // desde `md` el detalle ya está visible en la tabla.
    useEffect(() => {
        if (!open) return;
        const mq = window.matchMedia('(min-width: 768px)');
        const alCambiar = (e) => {
            if (e.matches) onClose();
        };
        mq.addEventListener('change', alCambiar);
        return () => mq.removeEventListener('change', alCambiar);
    }, [open, onClose]);

    return (
        <Modal
            open={open}
            onClose={onClose}
            title={title}
            description={description}
            icon={icon}
            size="xl"
            footer={
                <Button variant="secondary" onClick={onClose}>
                    Cerrar
                </Button>
            }
        >
            {summary?.length > 0 && (
                <dl className="mb-4 divide-y divide-primary-100 rounded-xl border border-primary-100 bg-primary-50/60 px-3 text-sm">
                    {summary.map((s) => {
                        const Icono = ICONOS[s.label] ?? FileText;
                        return (
                            <div key={s.label} className="flex items-center gap-3 py-2">
                                <Icono className="h-4 w-4 shrink-0 text-primary-600" aria-hidden="true" />
                                <dt className="text-warm-500">{s.label}</dt>
                                <dd className="ml-auto text-right font-medium text-warm-900">{s.value ?? '—'}</dd>
                            </div>
                        );
                    })}
                </dl>
            )}
            {children}
        </Modal>
    );
}
