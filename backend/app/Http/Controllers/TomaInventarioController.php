<?php

namespace App\Http\Controllers;

use App\Models\TomaInventario;
use Illuminate\Http\Request;

class TomaInventarioController extends Controller
{
    public function __construct()
    {
    }

    public function index()
    {
        return response()->json(TomaInventario::with('almacen')->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'almacen_id' => 'required|exists:almacenes,id',
            'observaciones' => 'nullable|string',
        ]);
        $data['fecha'] = now();
        $data['usuario_id'] = auth()->id();
        return response()->json(TomaInventario::create($data), 201);
    }

    public function show(TomaInventario $tomasInventario)
    {
        return response()->json($tomasInventario->load('almacen'));
    }

    public function update(Request $request, TomaInventario $tomasInventario)
    {
        $data = $request->validate([
            'estado' => 'string|max:50',
            'observaciones' => 'nullable|string',
        ]);
        $tomasInventario->update($data);
        return response()->json($tomasInventario);
    }

    public function destroy(TomaInventario $tomasInventario)
    {
        $tomasInventario->delete();
        return response()->json(['message' => 'Eliminado']);
    }
}
