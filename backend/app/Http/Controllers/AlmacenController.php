<?php

namespace App\Http\Controllers;

use App\Models\Almacen;
use App\Models\ProductoAlmacenStock;
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

    /**
     * Existencias (stock de productos) por almacén.
     * Si viene `almacen_id`, filtra; si no, devuelve todas ("Todos").
     */
    public function existencias(Request $request)
    {
        $query = ProductoAlmacenStock::with([
            'producto:id,codigo,nombre,categoria_id,precio_base,unidad_base_id',
            'producto.categoria:id,nombre',
            'producto.unidadBase:id,nombre,abreviatura',
            'almacen:id,nombre',
        ]);

        if ($request->filled('almacen_id')) {
            $query->where('almacen_id', $request->integer('almacen_id'));
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'nombre' => 'required|string|max:255',
            'codigo' => 'required|string|max:50|unique:almacenes,codigo',
            'tipo' => 'nullable|string|max:50',
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
            'tipo' => 'nullable|string|max:50',
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
