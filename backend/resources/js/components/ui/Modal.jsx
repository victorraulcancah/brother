import { useEffect } from 'react';
import { createPortal } from 'react-dom';
import { X } from 'lucide-react';
import { cn } from './cn';

/** El ancho máximo solo aplica desde `sm`: en el celular el modal ocupa todo el ancho. */
const sizes = {
    sm: 'sm:max-w-sm',
    md: 'sm:max-w-md',
    lg: 'sm:max-w-lg',
    xl: 'sm:max-w-2xl',
    '2xl': 'sm:max-w-4xl',
    '3xl': 'sm:max-w-6xl',
};

/**
 * Ventana modal. En pantallas chicas se comporta como una hoja inferior: sube
 * desde abajo, ocupa todo el ancho y se desplaza por dentro (el pulgar llega
 * mejor abajo que al centro). Desde `sm` es el diálogo centrado de siempre.
 */
export default function Modal({
    open,
    onClose,
    title,
    description,
    footer,
    size = 'md',
    children,
}) {
    useEffect(() => {
        if (!open) return;

        const handler = (e) => {
            if (e.key === 'Escape') onClose();
        };
        document.addEventListener('keydown', handler);
        document.body.style.overflow = 'hidden';

        return () => {
            document.removeEventListener('keydown', handler);
            document.body.style.overflow = '';
        };
    }, [open, onClose]);

    if (!open) return null;

    return createPortal(
        <div className="fixed inset-0 z-[100] flex items-end justify-center sm:items-center sm:p-4">
            <div
                className="fixed inset-0 animate-[fade-in_0.2s_ease-out] bg-black/50 motion-reduce:animate-none"
                onClick={onClose}
                aria-hidden="true"
            />
            <div
                role="dialog"
                aria-modal="true"
                aria-label={title}
                className={cn(
                    'relative z-10 flex max-h-[92dvh] w-full animate-[sheet-in_0.28s_cubic-bezier(0.22,1,0.36,1)] flex-col',
                    'rounded-t-3xl bg-white shadow-2xl',
                    'sm:max-h-[90vh] sm:animate-none sm:rounded-2xl',
                    'motion-reduce:animate-none',
                    sizes[size],
                )}
            >
                {/* Asa de la hoja inferior: avisa que se cierra tocando fuera o con la X. */}
                <div className="mx-auto mt-2.5 h-1 w-10 shrink-0 rounded-full bg-gray-300 sm:hidden" aria-hidden="true" />

                {(title || description) && (
                    <div className="flex items-start gap-3 px-5 pt-3 sm:px-6 sm:pt-5">
                        <div className="min-w-0 flex-1">
                            {title && (
                                <h2 className="text-lg font-semibold text-warm-900">
                                    {title}
                                </h2>
                            )}
                            {description && (
                                <p className="mt-0.5 text-sm text-warm-500">
                                    {description}
                                </p>
                            )}
                        </div>
                        <button
                            type="button"
                            onClick={onClose}
                            aria-label="Cerrar"
                            className="-mr-1 flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-gray-500 transition hover:bg-gray-100 sm:hidden"
                        >
                            <X className="h-5 w-5" />
                        </button>
                    </div>
                )}

                <div className="flex-1 overflow-y-auto overscroll-contain px-5 py-4 sm:px-6">{children}</div>

                {footer && (
                    <div className="flex flex-wrap items-center justify-end gap-2 border-t border-edge px-5 pb-[max(1rem,env(safe-area-inset-bottom))] pt-3 max-sm:[&>*]:flex-1 sm:border-0 sm:px-6 sm:pb-5 sm:pt-0">
                        {footer}
                    </div>
                )}
            </div>
        </div>,
        document.body,
    );
}
