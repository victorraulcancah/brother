<?php
namespace App\Http\Requests\Pedido;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class StorePedidoRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'cliente_id' => 'nullable|exists:clientes,id',
            'almacen_id' => 'required|exists:almacenes,id',
            'vendedor_id' => 'required|exists:users,id',
            'fecha_pedido' => 'required|date',
            'fecha_entrega' => 'nullable|date|after_or_equal:fecha_pedido',
            'moneda' => 'string|max:10|in:PEN,USD',
            'subtotal' => 'required|numeric|min:0',
            'descuento_total' => 'numeric|min:0',
            'total' => 'required|numeric|min:0',
            'observaciones' => 'nullable|string',
            'serie' => 'nullable|string|max:10',
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_presentacion_id' => 'required|exists:producto_presentaciones,id',
            'detalles.*.cantidad' => 'required|numeric|min:0.01',
            'detalles.*.precio_unitario' => 'required|numeric|min:0',
            'detalles.*.descuento' => 'numeric|min:0',
            'detalles.*.subtotal' => 'required|numeric|min:0',
        ];
    }

    public function messages(): array
    {
        return [
            'almacen_id.required' => 'El almacén es obligatorio',
            'almacen_id.exists' => 'El almacén seleccionado no existe',
            'vendedor_id.required' => 'El vendedor es obligatorio',
            'fecha_pedido.required' => 'La fecha del pedido es obligatoria',
            'fecha_pedido.date' => 'La fecha del pedido no es válida',
            'fecha_entrega.after_or_equal' => 'La fecha de entrega no puede ser anterior a la del pedido',
            'moneda.in' => 'La moneda debe ser PEN o USD',
            'subtotal.required' => 'El subtotal es obligatorio',
            'total.required' => 'El total es obligatorio',
            'detalles.required' => 'Debe incluir al menos un producto',
            'detalles.min' => 'Debe incluir al menos un producto',
            'detalles.*.producto_presentacion_id.required' => 'El producto es obligatorio en cada línea',
            'detalles.*.cantidad.required' => 'La cantidad es obligatoria en cada línea',
            'detalles.*.cantidad.min' => 'La cantidad debe ser mayor a 0',
            'detalles.*.precio_unitario.required' => 'El precio unitario es obligatorio',
            'detalles.*.subtotal.required' => 'El subtotal de la línea es obligatorio',
        ];
    }

    protected function failedValidation(Validator $validator): never
    {
        throw new HttpResponseException(
            response()->json([
                'res' => false,
                'message' => 'Error de validación.',
                'errors' => $validator->errors(),
            ], 422)
        );
    }
}
