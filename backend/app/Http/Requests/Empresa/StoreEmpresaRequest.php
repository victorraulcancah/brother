<?php

namespace App\Http\Requests\Empresa;

use Illuminate\Foundation\Http\FormRequest;

class StoreEmpresaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'ruc' => 'required|string|size:11|unique:empresas,ruc',
            'razon_social' => 'required|string|max:255',
            'nombre_comercial' => 'required|string|max:255',
            'direccion' => 'nullable|string|max:500',
            'telefono' => 'nullable|string|max:20',
            'email' => 'nullable|email|max:255',
        ];
    }

    public function messages(): array
    {
        return [
            'ruc.required' => 'El RUC es obligatorio',
            'ruc.size' => 'El RUC debe tener 11 dígitos',
            'ruc.unique' => 'El RUC ya está registrado',
            'razon_social.required' => 'La razón social es obligatoria',
            'nombre_comercial.required' => 'El nombre comercial es obligatorio',
        ];
    }
}
