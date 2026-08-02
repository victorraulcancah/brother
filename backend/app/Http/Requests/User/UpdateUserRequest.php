<?php

namespace App\Http\Requests\User;

use Illuminate\Foundation\Http\FormRequest;

class UpdateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|max:255|unique:users,email,' . $this->route('user'),
            'password' => 'sometimes|string|min:6|confirmed',
            'empresa_id' => 'nullable|exists:empresas,id',
            'caja_id' => 'nullable|exists:cajas,id',
            'role' => 'sometimes|string|exists:roles,name',
        ];
    }

    public function messages(): array
    {
        return [
            'name.max' => 'El nombre no puede exceder 255 caracteres',
            'email.email' => 'El correo no es válido',
            'email.unique' => 'El correo ya está registrado',
            'password.min' => 'La contraseña debe tener al menos 6 caracteres',
            'password.confirmed' => 'Las contraseñas no coinciden',
            'empresa_id.exists' => 'La empresa no existe',
            'role.exists' => 'El rol no existe',
        ];
    }
}
