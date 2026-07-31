<?php

namespace App\Http\Controllers;

use App\Models\MotivoMovimiento;
use Illuminate\Http\Request;

class MotivoMovimientoController extends Controller
{
    public function index()
    {
        return response()->json(MotivoMovimiento::orderBy('id')->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'nombre' => 'required|string|max:255',
            'tipo' => 'required|string|in:entrada,salida',
            'activo' => 'boolean',
        ]);
        return response()->json(MotivoMovimiento::create($data), 201);
    }

    public function show(MotivoMovimiento $motivosMovimiento)
    {
        return response()->json($motivosMovimiento);
    }

    public function update(Request $request, MotivoMovimiento $motivosMovimiento)
    {
        if ($motivosMovimiento->es_sistema) {
            return response()->json(['message' => 'Los motivos del sistema no se pueden editar.'], 422);
        }

        $data = $request->validate([
            'nombre' => 'required|string|max:255',
            'tipo' => 'required|string|in:entrada,salida',
            'activo' => 'boolean',
        ]);
        $motivosMovimiento->update($data);
        return response()->json($motivosMovimiento);
    }

    public function destroy(MotivoMovimiento $motivosMovimiento)
    {
        if ($motivosMovimiento->es_sistema) {
            return response()->json(['message' => 'Los motivos del sistema no se pueden eliminar.'], 422);
        }

        $motivosMovimiento->delete();
        return response()->json(['message' => 'Eliminado']);
    }
}
