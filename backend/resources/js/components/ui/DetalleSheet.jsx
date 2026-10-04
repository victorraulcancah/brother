import { useEffect } from 'react';
import Button from './Button';
import Modal from './Modal';

/** ¿La pantalla es de celular? Debe coincidir con el breakpoint `md` de Tailwind (768px). */
export const esMovil = () => typeof window !== 'undefined' && window.matchMedia('(max-width: 767px)').matches;

/**
 * Detalle de un documento en celular. Las pantallas con lista + tabla de detalle
 * muestran la tabla solo desde `md`; en el celular, al tocar una tarjeta de la
 * lista, el detalle sube desde abajo como hoja inferior.
 *
 * summary: [{ label, value }] — datos de cabecera del documento (opcional)
 * children: normalmente un <LineCards /> con las líneas
 */
export default function DetalleSheet({ open, onClose, title, description, summary, children }) {
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
            size="xl"
            footer={
                <Button variant="secondary" onClick={onClose}>
                    Cerrar
                </Button>
            }
        >
            {summary?.length > 0 && (
                <dl className="mb-4 space-y-1.5 rounded-xl bg-gray-50 p-3 text-sm">
                    {summary.map((s) => (
                        <div key={s.label} className="flex items-baseline justify-between gap-3">
                            <dt className="text-warm-500">{s.label}</dt>
                            <dd className="text-right font-medium text-warm-900">{s.value ?? '—'}</dd>
                        </div>
                    ))}
                </dl>
            )}
            {children}
        </Modal>
    );
}
