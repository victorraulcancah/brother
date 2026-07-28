<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductoResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'codigo' => $this->codigo,
            'nombre' => $this->nombre,
            'marca' => new MarcaResource($this->whenLoaded('marca')),
            'sub_marca' => new SubMarcaResource($this->whenLoaded('subMarca')),
            'categoria' => new CategoriaResource($this->whenLoaded('categoria')),
            'unidad_medida' => new UnidadMedidaResource($this->whenLoaded('unidadMedida')),
            'descripcion' => $this->descripcion,
            'precio_base' => $this->precio_base,
            'afecto_igv' => $this->afecto_igv,
            'activo' => $this->activo,
            'variantes' => ProductoVarianteResource::collection($this->whenLoaded('variantes')),
            'imagenes' => ProductoImagenResource::collection($this->whenLoaded('imagenes')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
