<?php

namespace App\Http\Controllers;

use App\Models\SubCategoria;
use Illuminate\Http\Request;

class SubCategoriaController extends Controller
{
    public function index()
    {
        return response()->json(
            SubCategoria::with('categoria:id,nombre')->orderBy('nombre')->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'categoria_id' => 'required|exists:categorias,id',
            'nombre' => 'required|string|max:255',
            'activo' => 'boolean',
        ]);

        return response()->json(SubCategoria::create($data), 201);
    }

    public function show(int $id)
    {
        return response()->json(SubCategoria::with('categoria:id,nombre')->findOrFail($id));
    }

    public function update(Request $request, int $id)
    {
        $sub = SubCategoria::findOrFail($id);
        $data = $request->validate([
            'categoria_id' => 'required|exists:categorias,id',
            'nombre' => 'required|string|max:255',
            'activo' => 'boolean',
        ]);
        $sub->update($data);

        return response()->json($sub);
    }

    public function destroy(int $id)
    {
        SubCategoria::findOrFail($id)->delete();

        return response()->json(['message' => 'Sub-categoría eliminada']);
    }
}
