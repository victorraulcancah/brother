<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PedidoResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'serie' => $this->serie,
            'numero' => $this->numero,
            'cliente_id' => $this->cliente_id,
            'almacen_id' => $this->almacen_id,
            'vendedor_id' => $this->vendedor_id,
            'fecha_pedido' => $this->fecha_pedido,
            'fecha_entrega' => $this->fecha_entrega,
            'moneda' => $this->moneda,
            'subtotal' => $this->subtotal,
            'descuento_total' => $this->descuento_total,
            'total' => $this->total,
            'estado' => $this->estado,
            'nota_venta_id' => $this->nota_venta_id,
            'motivo_cancelacion' => $this->motivo_cancelacion,
            'fecha_cancelacion' => $this->fecha_cancelacion,
            'observaciones' => $this->observaciones,
            'cliente' => $this->whenLoaded('cliente'),
            'almacen' => $this->whenLoaded('almacen'),
            'vendedor' => UserResource::make($this->whenLoaded('vendedor')),
            'nota_venta' => $this->whenLoaded('notaVenta', fn () => $this->notaVenta ? [
                'id' => $this->notaVenta->id,
                'serie' => $this->notaVenta->serie,
                'numero' => $this->notaVenta->numero,
            ] : null),
            'detalles' => PedidoDetalleResource::collection($this->whenLoaded('detalles')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
