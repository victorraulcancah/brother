import { useState } from 'react';
import {
    ClipboardList,
    Package,
    Pause,
    Play,
    ReceiptText,
    ShoppingBag,
    Wallet,
} from 'lucide-react';
import { cn } from './ui';

/** Color del estado de cada fila, pensado para el fondo azul profundo del panel. */
const TONO = {
    ok: 'text-emerald-300',
    aviso: 'text-amber-300',
    info: 'text-sky-300',
    malo: 'text-rose-300',
};

/**
 * Los módulos del sistema, con datos de ejemplo (no son datos reales: la tarjeta lo dice).
 * Cada uno resume qué resuelve y muestra tres registros tal como se ven dentro.
 */
const MODULOS = [
    {
        id: 'ventas',
        tab: 'Ventas',
        icon: ReceiptText,
        titulo: 'Cada venta queda registrada una sola vez',
        texto: 'Notas de venta con serie y número, cobro en caja y cuentas por cobrar, todo desde el mismo registro.',
        filas: [
            { icon: ReceiptText, titulo: 'Nota de venta NV01-12', detalle: 'Bodega El Ahorro · S/ 1,240.00', estado: 'Emitida', tono: 'ok' },
            { icon: ReceiptText, titulo: 'Nota de venta NV01-11', detalle: 'Minimarket Lucero · S/ 486.50', estado: 'Emitida', tono: 'ok' },
            { icon: ReceiptText, titulo: 'Nota de venta NV01-10', detalle: 'Cliente Público General · S/ 226.70', estado: 'Crédito', tono: 'aviso' },
        ],
        resumen: 'Ventas de hoy · 3 notas · S/ 1,953.20',
    },
    {
        id: 'pedidos',
        tab: 'Pedidos',
        icon: ClipboardList,
        titulo: 'Reserva el stock antes de despachar',
        texto: 'Cada pedido aparta la mercadería sin descontarla. Al cobrarlo pasa a venta; si se cancela, el stock se libera.',
        filas: [
            { icon: ClipboardList, titulo: 'Pedido PE01-07', detalle: 'Bodega San Martín · S/ 2,100.00', estado: 'Pendiente', tono: 'aviso' },
            { icon: ClipboardList, titulo: 'Pedido PE01-06', detalle: 'Minimarket Lucero · S/ 840.00', estado: 'Convertido', tono: 'ok' },
            { icon: ClipboardList, titulo: 'Pedido PE01-05', detalle: 'Tienda Rosita · S/ 315.00', estado: 'Cancelado', tono: 'malo' },
        ],
        resumen: 'Pendientes · 1 pedido · S/ 2,100.00 por vender',
    },
    {
        id: 'inventario',
        tab: 'Inventario',
        icon: Package,
        titulo: 'Sabe qué hay y qué puedes vender',
        texto: 'Existencias por almacén con stock físico, reservado y disponible, en sacos, kilos o la unidad que uses.',
        filas: [
            { icon: Package, titulo: 'Arroz extra · Saco 50 kg', detalle: 'Físico 150 · Reservado 30', estado: 'Disp. 120', tono: 'ok' },
            { icon: Package, titulo: 'Arroz superior · Saco 50 kg', detalle: 'Físico 160 · Reservado 40', estado: 'Disp. 120', tono: 'ok' },
            { icon: Package, titulo: 'Azúcar rubia · Saco 50 kg', detalle: 'Físico 100 · Reservado 15', estado: 'Disp. 85', tono: 'ok' },
        ],
        resumen: 'Físico 410 · Reservado 85 · Disponible 325',
    },
    {
        id: 'compras',
        tab: 'Compras',
        icon: ShoppingBag,
        titulo: 'Del pedido al proveedor a tu almacén',
        texto: 'Órdenes de compra, compras y recepciones: lo que pediste, lo que llegó y lo que todavía falta.',
        filas: [
            { icon: ShoppingBag, titulo: 'Orden de compra OC0001-14', detalle: 'Molino Norteño · S/ 12,600.00', estado: 'Enviada', tono: 'info' },
            { icon: ShoppingBag, titulo: 'Compra C001-09', detalle: 'Molino Norteño · S/ 6,300.00', estado: 'Recibida', tono: 'ok' },
            { icon: ShoppingBag, titulo: 'Recepción RC01-08', detalle: 'Compra C001-08 · 20 de 40 sacos', estado: 'Parcial', tono: 'aviso' },
        ],
        resumen: 'Pendiente de recibir · 2 documentos',
    },
    {
        id: 'caja',
        tab: 'Caja',
        icon: Wallet,
        titulo: 'La caja cuadra al cierre',
        texto: 'Apertura, ingresos, egresos y cierre por caja, más las cuentas por cobrar y por pagar al día.',
        filas: [
            { icon: Wallet, titulo: 'Apertura de caja', detalle: 'Caja principal · Efectivo', estado: 'S/ 300.00', tono: 'info' },
            { icon: Wallet, titulo: 'Ingreso por venta', detalle: 'NV01-12 · Efectivo', estado: 'S/ 1,240.00', tono: 'ok' },
            { icon: Wallet, titulo: 'Cuenta por cobrar', detalle: 'María Quispe Huamán · NV01-04', estado: 'Pendiente', tono: 'aviso' },
        ],
        resumen: 'Saldo de caja · S/ 1,540.00',
    },
];

/**
 * Carrusel informativo del panel de marca. Avanza solo (cada barra de progreso se llena
 * y pasa al siguiente módulo), se detiene al pasar el mouse o con el botón de pausa, y
 * no se mueve si el usuario pidió menos movimiento.
 */
export default function ModulosCarrusel({ className }) {
    const [activo, setActivo] = useState(0);
    const [pausado, setPausado] = useState(false);
    const [encima, setEncima] = useState(false);

    const modulo = MODULOS[activo];
    const detenido = pausado || encima;
    const siguiente = () => setActivo((i) => (i + 1) % MODULOS.length);

    return (
        <div
            className={className}
            onMouseEnter={() => setEncima(true)}
            onMouseLeave={() => setEncima(false)}
            onFocus={() => setEncima(true)}
            onBlur={() => setEncima(false)}
        >
            <div role="tablist" aria-label="Módulos del sistema" className="flex flex-wrap gap-2">
                {MODULOS.map((m, i) => {
                    const Icono = m.icon;
                    const seleccionado = i === activo;
                    return (
                        <button
                            key={m.id}
                            type="button"
                            role="tab"
                            id={`modulo-tab-${m.id}`}
                            aria-selected={seleccionado}
                            aria-controls="modulo-panel"
                            onClick={() => setActivo(i)}
                            className={cn(
                                'inline-flex h-10 items-center gap-1.5 rounded-full border px-3.5 text-[13px] font-semibold transition focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white',
                                seleccionado
                                    ? 'border-white bg-white text-deep-800'
                                    : 'border-white/20 bg-white/[0.05] text-blue-100 hover:border-white/40 hover:bg-white/10',
                            )}
                        >
                            <Icono className="h-4 w-4" aria-hidden="true" />
                            {m.tab}
                        </button>
                    );
                })}
            </div>

            <div
                key={modulo.id}
                id="modulo-panel"
                role="tabpanel"
                aria-labelledby={`modulo-tab-${modulo.id}`}
                className="mt-9 animate-[login-in_0.5s_cubic-bezier(0.16,1,0.3,1)] motion-reduce:animate-none"
            >
                <h2 className="max-w-[30rem] text-[clamp(1.9rem,2.7vw,2.6rem)] font-extrabold leading-[1.1] tracking-[-0.015em] text-white">
                    {modulo.titulo}
                </h2>
                <p className="mt-4 max-w-[28rem] text-[15px] leading-relaxed text-blue-100/85">{modulo.texto}</p>

                <div className="mt-7 overflow-hidden rounded-2xl border border-white/10 bg-white/[0.07] shadow-[0_24px_48px_-24px_rgba(0,0,0,0.55)]">
                    <ul>
                        {modulo.filas.map((f) => {
                            const Icono = f.icon;
                            return (
                                <li key={f.titulo} className="flex items-center gap-4 border-b border-white/10 px-5 py-4">
                                    <span className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-white/10 text-blue-100">
                                        <Icono className="h-5 w-5" aria-hidden="true" />
                                    </span>
                                    <span className="min-w-0 flex-1">
                                        <span className="block truncate text-[15px] font-semibold text-white">{f.titulo}</span>
                                        <span className="mt-0.5 block truncate text-[13px] text-blue-200/85">{f.detalle}</span>
                                    </span>
                                    <span className={cn('shrink-0 text-[13px] font-semibold', TONO[f.tono])}>{f.estado}</span>
                                </li>
                            );
                        })}
                    </ul>
                    <div className="flex items-center justify-between gap-4 bg-black/15 px-5 py-3 text-[13px] text-blue-100/90">
                        <span className="flex min-w-0 items-center gap-2.5">
                            <span className="h-2 w-2 shrink-0 rounded-full bg-primary-400" aria-hidden="true" />
                            <span className="truncate font-medium">{modulo.resumen}</span>
                        </span>
                        <span className="shrink-0 text-[11px] text-blue-200/80">Datos de ejemplo</span>
                    </div>
                </div>
            </div>

            <div className="mt-6 flex items-center gap-3">
                <div className="flex flex-1 gap-2" role="group" aria-label="Avance del carrusel">
                    {MODULOS.map((m, i) => (
                        <button
                            key={m.id}
                            type="button"
                            onClick={() => setActivo(i)}
                            aria-label={`Ir a ${m.tab}`}
                            className="group flex h-6 flex-1 items-center focus-visible:outline-none"
                        >
                            <span className="block h-1 w-full overflow-hidden rounded-full bg-white/20 group-focus-visible:ring-2 group-focus-visible:ring-white">
                                {i < activo && <span className="block h-full w-full bg-white/70" />}
                                {i === activo && (
                                    <span
                                        key={`${modulo.id}-${activo}`}
                                        onAnimationEnd={siguiente}
                                        style={{ animationPlayState: detenido ? 'paused' : 'running' }}
                                        className="block h-full origin-left animate-[login-progress_7s_linear_forwards] rounded-full bg-white motion-reduce:animate-none"
                                    />
                                )}
                            </span>
                        </button>
                    ))}
                </div>
                <button
                    type="button"
                    onClick={() => setPausado((v) => !v)}
                    aria-pressed={pausado}
                    aria-label={pausado ? 'Reanudar el carrusel' : 'Pausar el carrusel'}
                    className="grid h-8 w-8 place-items-center rounded-full border border-white/20 text-blue-100 transition hover:bg-white/10 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
                >
                    {pausado ? <Play className="h-3.5 w-3.5" /> : <Pause className="h-3.5 w-3.5" />}
                </button>
            </div>
        </div>
    );
}
