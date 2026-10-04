import { cn } from './cn';

/**
 * Líneas de un documento (ventas, compras, pedidos…) como tarjetas, para
 * celular. Una tabla de 8 o 10 columnas no cabe en 375px: se corta o obliga a
 * desplazarse de lado. En pantallas medianas en adelante se oculta y vuelve la
 * tabla de cada pantalla.
 *
 * items:  [{ key, title, subtitle?, fields: [{ label, value, className? }] }]
 * totals: [{ label, value, strong? }]   — filas de resumen debajo de las tarjetas
 * empty:  texto cuando no hay líneas
 */
export default function LineCards({ items, totals, empty, className }) {
    return (
        <div className={cn('space-y-3 md:hidden', className)}>
            {items.length === 0 && <p className="py-8 text-center text-sm text-warm-500">{empty}</p>}

            {items.map((it) => (
                <article key={it.key} className="rounded-xl border border-edge bg-white p-3">
                    <h3 className="text-sm font-semibold text-warm-900">{it.title}</h3>
                    {it.subtitle && <p className="mt-0.5 text-xs text-warm-500">{it.subtitle}</p>}
                    <dl className="mt-2 grid grid-cols-3 gap-x-2 gap-y-2 text-sm">
                        {it.fields.map((f) => (
                            <div key={f.label} className="min-w-0">
                                <dt className="text-xs text-warm-500">{f.label}</dt>
                                <dd className={cn('truncate font-semibold text-warm-900', f.className)}>{f.value}</dd>
                            </div>
                        ))}
                    </dl>
                </article>
            ))}

            {items.length > 0 && totals && (
                <div className="space-y-1 border-t border-edge px-1 pt-3">
                    {totals.map((t) => (
                        <div key={t.label} className="flex items-baseline justify-between text-sm">
                            <span className="text-warm-500">{t.label}</span>
                            <span className={cn('font-semibold text-warm-900', t.strong && 'text-lg font-extrabold text-primary-700')}>
                                {t.value}
                            </span>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}
