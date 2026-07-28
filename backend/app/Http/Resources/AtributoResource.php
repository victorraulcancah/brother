<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AtributoResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'nombre' => $this->nombre,
            'valores' => AtributoValorResource::collection($this->whenLoaded('valores')),
            'created_at' => $this->created_at,
        ];
    }
}
