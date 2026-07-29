<?php

namespace App\Http\Controllers;

use App\Models\Atributo;
use Illuminate\Http\Request;

class AtributoController extends Controller
{
    public function index()
    {
        return response()->json(Atributo::orderBy('nombre')->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'nombre' => 'required|string|max:255',
        ]);

        return response()->json(Atributo::create($data), 201);
    }

    public function show(int $id)
    {
        return response()->json(Atributo::with('valores')->findOrFail($id));
    }

    public function update(Request $request, int $id)
    {
        $atributo = Atributo::findOrFail($id);
        $data = $request->validate([
            'nombre' => 'required|string|max:255',
        ]);
        $atributo->update($data);

        return response()->json($atributo);
    }

    public function destroy(int $id)
    {
        Atributo::findOrFail($id)->delete();

        return response()->json(['message' => 'Atributo eliminado']);
    }
}
