import { useEffect } from 'react';
import { createPortal } from 'react-dom';
import { X } from 'lucide-react';
import { cn } from './cn';

const sizes = {
    sm: 'max-w-sm',
    md: 'max-w-md',
    lg: 'max-w-lg',
    xl: 'max-w-2xl',
};

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
        <div className="fixed inset-0 z-[100] overflow-y-auto">
            <div className="flex min-h-full items-center justify-center p-4">
                <div
                    className="fixed inset-0 bg-black/50"
                    onClick={onClose}
                    aria-hidden="true"
                />
                <div
                    role="dialog"
                    aria-modal="true"
                    aria-label={title}
                    className={cn(
                        'relative z-10 flex max-h-[90vh] w-full flex-col rounded-2xl bg-white shadow-2xl',
                        sizes[size],
                    )}
                >
                {(title || description) && (
                    <div className="flex items-start justify-between gap-4 border-b border-edge px-6 py-4">
                        <div>
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
                            className="rounded-md p-1 text-gray-400 transition hover:bg-gray-100 hover:text-gray-600"
                        >
                            <X className="h-5 w-5" />
                        </button>
                    </div>
                )}

                <div className="flex-1 overflow-y-auto px-6 py-4">{children}</div>

                {footer && (
                    <div className="flex items-center justify-end gap-2 border-t border-edge px-6 py-4">
                        {footer}
                    </div>
                )}
            </div>
            </div>
        </div>,
        document.body,
    );
}
