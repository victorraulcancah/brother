<?php

namespace App\Http\Controllers;

use App\Models\AjusteInventario;
use Illuminate\Http\Request;

class AjusteInventarioController extends Controller
{
    public function __construct()
    {
    }

    public function index()
    {
        return response()->json(AjusteInventario::with('almacen')->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'almacen_id' => 'required|exists:almacenes,id',
            'tipo' => 'required|string|max:50',
            'motivo' => 'required|string',
            'observaciones' => 'nullable|string',
        ]);
        $data['usuario_solicita_id'] = auth()->id();
        return response()->json(AjusteInventario::create($data), 201);
    }

    public function show(AjusteInventario $ajuste)
    {
        return response()->json($ajuste->load('almacen'));
    }

    public function update(Request $request, AjusteInventario $ajuste)
    {
        $data = $request->validate([
            'estado' => 'string|max:50',
            'observaciones' => 'nullable|string',
        ]);
        $ajuste->update($data);
        return response()->json($ajuste);
    }

    public function destroy(AjusteInventario $ajuste)
    {
        $ajuste->delete();
        return response()->json(['message' => 'Eliminado']);
    }
}
