<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductoPresentacionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'producto_id' => $this->producto_id,
            'nombre' => $this->nombre,
            'codigo_barras' => $this->codigo_barras,
            'precio_venta' => $this->precio_venta,
            'factor_conversion' => $this->factor_conversion,
            'unidad_base' => new UnidadMedidaResource($this->whenLoaded('unidadBase')),
            'activo' => $this->activo,
            'created_at' => $this->created_at,
        ];
    }
}
