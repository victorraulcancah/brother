<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductoVarianteResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'producto_id' => $this->producto_id,
            'sku_variante' => $this->sku_variante,
            'precio_diferencial' => $this->precio_diferencial,
            'stock' => $this->stock,
            'activo' => $this->activo,
            'atributo_valores' => AtributoValorResource::collection($this->whenLoaded('atributoValores')),
            'created_at' => $this->created_at,
        ];
    }
}
