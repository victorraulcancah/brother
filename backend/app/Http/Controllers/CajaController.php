<?php

namespace App\Http\Controllers;

use App\Models\Caja;
use Illuminate\Http\Request;

class CajaController extends Controller
{
    public function index()
    {
        return response()->json(Caja::with('almacen:id,nombre')->orderBy('nombre')->get());
    }

    public function store(Request $request)
    {
        return response()->json(Caja::create($this->validated($request))->load('almacen:id,nombre'), 201);
    }

    public function show(Caja $caja)
    {
        return response()->json($caja->load('almacen:id,nombre'));
    }

    public function update(Request $request, Caja $caja)
    {
        $caja->update($this->validated($request));
        return response()->json($caja->load('almacen:id,nombre'));
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
        ]);
    }
}
