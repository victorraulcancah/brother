<?php

namespace App\Http\Controllers;

use App\Models\Caja;
use Illuminate\Http\Request;

class CajaController extends Controller
{
    public function index()
    {
        return response()->json(
            Caja::with('almacen:id,nombre', 'metodosPago:id,nombre,tipo,es_sistema')
                ->orderBy('nombre')
                ->get()
        );
    }

    public function store(Request $request)
    {
        $data = $this->validated($request);
        $metodos = $data['metodos_pago'] ?? [];
        unset($data['metodos_pago']);

        $caja = Caja::create($data);
        $caja->metodosPago()->sync($metodos);

        return response()->json(
            $caja->load('almacen:id,nombre', 'metodosPago:id,nombre,tipo,es_sistema'),
            201
        );
    }

    public function show(Caja $caja)
    {
        return response()->json($caja->load('almacen:id,nombre', 'metodosPago:id,nombre,tipo,es_sistema'));
    }

    public function update(Request $request, Caja $caja)
    {
        $data = $this->validated($request);
        $metodos = $data['metodos_pago'] ?? [];
        unset($data['metodos_pago']);

        $caja->update($data);
        $caja->metodosPago()->sync($metodos);

        return response()->json($caja->load('almacen:id,nombre', 'metodosPago:id,nombre,tipo,es_sistema'));
    }

    public function destroy(Caja $caja)
    {
        $caja->delete();
        return response()->json(['message' => 'Eliminado']);
    }

    private function validated(Request $request): array
    {
        return $request->validate([
            'nombre' => 'required|string|max:255',
            'almacen_id' => 'nullable|exists:almacenes,id',
            'activo' => 'boolean',
            'metodos_pago' => 'nullable|array',
            'metodos_pago.*' => 'exists:metodos_pago,id',
        ]);
    }
}
