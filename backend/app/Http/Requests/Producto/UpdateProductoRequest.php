<?php

namespace App\Http\Requests\Producto;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProductoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'codigo' => ['required', 'string', 'max:255', Rule::unique('productos', 'codigo')->ignore($this->route('producto'))],
            'nombre' => 'required|string|max:255',
            'marca_id' => 'required|exists:marcas,id',
            'sub_marca_id' => 'nullable|exists:sub_marcas,id',
            'categoria_id' => 'nullable|exists:categorias,id',
            'unidad_medida_id' => 'required|exists:unidades_medida,id',
            'descripcion' => 'nullable|string|max:5000',
            'precio_base' => 'required|numeric|min:0',
            'afecto_igv' => 'boolean',
            'activo' => 'boolean',
        ];
    }

    public function messages(): array
    {
        return [
            'codigo.required' => 'El código del producto es obligatorio',
            'codigo.unique' => 'El código ya está registrado',
            'nombre.required' => 'El nombre del producto es obligatorio',
            'marca_id.required' => 'La marca es obligatoria',
            'marca_id.exists' => 'La marca seleccionada no existe',
            'unidad_medida_id.required' => 'La unidad de medida es obligatoria',
            'precio_base.required' => 'El precio base es obligatorio',
            'precio_base.min' => 'El precio base debe ser mayor o igual a 0',
        ];
    }
}
