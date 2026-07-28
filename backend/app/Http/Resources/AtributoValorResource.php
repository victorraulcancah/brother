<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AtributoValorResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'atributo_id' => $this->atributo_id,
            'valor' => $this->valor,
            'atributo' => new AtributoResource($this->whenLoaded('atributo')),
            'created_at' => $this->created_at,
        ];
    }
}
