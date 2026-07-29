<?php

namespace App\Http\Controllers;

use App\Models\AtributoValor;
use Illuminate\Http\Request;

class AtributoValorController extends Controller
{
    public function index()
    {
        return response()->json(
            AtributoValor::with('atributo:id,nombre')->orderBy('valor')->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'atributo_id' => 'required|exists:atributos,id',
            'valor' => 'required|string|max:255',
        ]);

        return response()->json(AtributoValor::create($data), 201);
    }

    public function show(int $id)
    {
        return response()->json(AtributoValor::with('atributo:id,nombre')->findOrFail($id));
    }

    public function update(Request $request, int $id)
    {
        $valor = AtributoValor::findOrFail($id);
        $data = $request->validate([
            'atributo_id' => 'required|exists:atributos,id',
            'valor' => 'required|string|max:255',
        ]);
        $valor->update($data);

        return response()->json($valor);
    }

    public function destroy(int $id)
    {
        AtributoValor::findOrFail($id)->delete();

        return response()->json(['message' => 'Valor eliminado']);
    }
}
