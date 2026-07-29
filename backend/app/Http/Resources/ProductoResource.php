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
            'unidad_compra' => new UnidadMedidaResource($this->whenLoaded('unidadCompra')),
            'unidad_base' => new UnidadMedidaResource($this->whenLoaded('unidadBase')),
            'factor_compra_base' => $this->factor_compra_base,
            'descripcion' => $this->descripcion,
            'imagen' => $this->imagen,
            'precio_base' => $this->precio_base,
            'afecto_igv' => $this->afecto_igv,
            'activo' => $this->activo,
            'presentaciones' => ProductoPresentacionResource::collection($this->whenLoaded('presentaciones')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
