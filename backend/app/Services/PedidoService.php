<?php
namespace App\Services;

use App\Models\NotaVenta;
use App\Models\Pedido;
use App\Models\SerieDocumento;
use Illuminate\Support\Facades\DB;

/**
 * Pedidos de clientes: reservan stock sin descontarlo.
 *
 * Al guardar un pedido, la mercadería queda apartada (stock_reservado) y deja de
 * estar disponible para otras ventas, pero sigue contando como stock físico.
 * El pedido termina de una de dos formas: se convierte en nota de venta (la
 * reserva se libera y la venta descuenta el stock real) o se cancela (la reserva
 * se libera). Todo va en una transacción: si algo falla no queda stock apartado
 * a medias.
 */
class PedidoService
{
    public function __construct(
        protected StockService $stockService,
        protected NotaVentaService $notaVentaService
    ) {}

    public function crear(array $data): Pedido
    {
        return DB::transaction(function () use ($data) {
            $serie = $data['serie'] ?? 'PE01';
            $serieDoc = SerieDocumento::where('tipo_documento', 'pedido')
                ->where('serie', $serie)
                ->lockForUpdate()
                ->firstOrCreate(
                    ['tipo_documento' => 'pedido', 'serie' => $serie],
                    ['numero_actual' => 0, 'activo' => true]
                );
            $serieDoc->increment('numero_actual');
            $numero = str_pad($serieDoc->numero_actual, 3, '0', STR_PAD_LEFT);

            $pedido = Pedido::create($this->cabecera($data) + [
                'serie' => $serie,
                'numero' => $numero,
                'estado' => 'pendiente',
            ]);

            $this->aplicar($pedido, $data);

            return $this->conRelaciones($pedido);
        });
    }

    /** Edita un pedido pendiente: libera lo reservado y vuelve a reservar con los datos nuevos. */
    public function actualizar(Pedido $pedido, array $data): Pedido
    {
        $this->exigirPendiente($pedido, 'editar');

        return DB::transaction(function () use ($pedido, $data) {
            $this->liberar($pedido);

            $pedido->detalles()->delete();
            $pedido->update($this->cabecera($data));

            $this->aplicar($pedido->fresh(), $data);

            return $this->conRelaciones($pedido->fresh());
        });
    }

    public function cancelar(Pedido $pedido, string $motivo): Pedido
    {
        $this->exigirPendiente($pedido, 'cancelar');

        return DB::transaction(function () use ($pedido, $motivo) {
            $this->liberar($pedido);

            $pedido->update([
                'estado' => 'cancelado',
                'motivo_cancelacion' => $motivo,
                'usuario_cancela_id' => auth()->id(),
                'fecha_cancelacion' => now(),
            ]);

            return $this->conRelaciones($pedido);
        });
    }

    /**
     * Convierte el pedido en nota de venta. Primero se libera la reserva y luego
     * se emite la venta, que descuenta el stock real. Si la venta falla (por
     * ejemplo el stock cambió), la transacción deshace también la liberación y el
     * pedido sigue reservado.
     *
     * $ventaData es el mismo payload que una nota de venta normal: así el
     * vendedor puede ajustar cantidades o precios antes de cobrar.
     */
    public function convertir(Pedido $pedido, array $ventaData): NotaVenta
    {
        $this->exigirPendiente($pedido, 'convertir');

        return DB::transaction(function () use ($pedido, $ventaData) {
            $this->liberar($pedido);

            $nota = $this->notaVentaService->crear($ventaData);

            $pedido->update([
                'estado' => 'convertido',
                'nota_venta_id' => $nota->id,
            ]);

            return $nota;
        });
    }

    /* ------------------------------------------------------------------ */

    private function exigirPendiente(Pedido $pedido, string $accion): void
    {
        if ($pedido->estado !== 'pendiente') {
            throw new \InvalidArgumentException("Solo se pueden {$accion} pedidos pendientes.");
        }
    }

    private function cabecera(array $data): array
    {
        return [
            'cliente_id' => $data['cliente_id'] ?? null,
            'almacen_id' => $data['almacen_id'],
            'vendedor_id' => $data['vendedor_id'],
            'fecha_pedido' => $data['fecha_pedido'],
            'fecha_entrega' => $data['fecha_entrega'] ?? null,
            'moneda' => $data['moneda'] ?? 'PEN',
            'subtotal' => $data['subtotal'],
            'descuento_total' => $data['descuento_total'] ?? 0,
            'total' => $data['total'],
            'observaciones' => $data['observaciones'] ?? null,
        ];
    }

    /** Crea las líneas y reserva el stock de cada una. */
    private function aplicar(Pedido $pedido, array $data): void
    {
        $pedido->detalles()->createMany($data['detalles']);
        $pedido->load(['detalles.presentacion.producto.unidadMedida', 'almacen']);

        foreach ($pedido->detalles as $detalle) {
            $this->stockService->reservar(
                $detalle->presentacion,
                $pedido->almacen,
                (float) $detalle->cantidad
            );
        }
    }

    /** Devuelve a disponible lo que este pedido tenía reservado. */
    private function liberar(Pedido $pedido): void
    {
        $pedido->load(['detalles.presentacion', 'almacen']);

        foreach ($pedido->detalles as $detalle) {
            $this->stockService->liberarReserva(
                $detalle->presentacion,
                $pedido->almacen,
                (float) $detalle->cantidad
            );
        }
    }

    private function conRelaciones(Pedido $pedido): Pedido
    {
        return $pedido->load([
            'cliente', 'almacen', 'vendedor', 'notaVenta',
            'detalles.presentacion.producto.marca',
        ]);
    }
}
