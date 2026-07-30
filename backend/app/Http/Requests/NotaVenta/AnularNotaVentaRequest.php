<?php
namespace App\Http\Requests\NotaVenta;

use Illuminate\Foundation\Http\FormRequest;

class AnularNotaVentaRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'motivo_anulacion' => 'required|string|max:500',
        ];
    }

    public function messages(): array
    {
        return [
            'motivo_anulacion.required' => 'El motivo de anulación es obligatorio',
            'motivo_anulacion.max' => 'El motivo de anulación no debe exceder 500 caracteres',
        ];
    }
}
