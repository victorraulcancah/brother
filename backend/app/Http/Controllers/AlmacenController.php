<?php

namespace App\Http\Controllers;

use App\Models\Almacen;
use Illuminate\Http\Request;

class AlmacenController extends Controller
{
    public function __construct()
    {
    }

    public function index()
    {
        return response()->json(Almacen::all());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'nombre' => 'required|string|max:255',
            'codigo' => 'required|string|max:50|unique:almacenes,codigo',
            'tipo' => 'required|string|max:50',
            'direccion' => 'nullable|string|max:500',
            'activo' => 'boolean',
        ]);
        return response()->json(Almacen::create($data), 201);
    }

    public function show(Almacen $almacene)
    {
        return response()->json($almacene);
    }

    public function update(Request $request, Almacen $almacene)
    {
        $data = $request->validate([
            'nombre' => 'required|string|max:255',
            'codigo' => 'required|string|max:50|unique:almacenes,codigo,' . $almacene->id,
            'tipo' => 'required|string|max:50',
            'direccion' => 'nullable|string|max:500',
            'activo' => 'boolean',
        ]);
        $almacene->update($data);
        return response()->json($almacene);
    }

    public function destroy(Almacen $almacene)
    {
        $almacene->delete();
        return response()->json(['message' => 'Eliminado']);
    }
}
