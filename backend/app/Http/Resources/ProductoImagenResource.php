<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductoImagenResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'producto_id' => $this->producto_id,
            'url' => $this->url,
            'orden' => $this->orden,
            'es_principal' => $this->es_principal,
            'created_at' => $this->created_at,
        ];
    }
}
