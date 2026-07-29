<?php

namespace App\Http\Controllers;

use App\Models\RecepcionCompra;
use Illuminate\Http\Request;

class RecepcionCompraController extends Controller
{
    public function __construct()
    {
    }

    public function index()
    {
        return response()->json(RecepcionCompra::with('ordenCompra', 'proveedor', 'almacen')->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'orden_compra_id' => 'nullable|exists:ordenes_compra,id',
            'proveedor_id' => 'nullable|exists:proveedores,id',
            'almacen_id' => 'required|exists:almacenes,id',
            'numero_documento' => 'nullable|string|max:255',
            'tipo_documento' => 'nullable|string|max:50',
            'fecha_recepcion' => 'required|date',
            'observaciones' => 'nullable|string',
        ]);
        $data['usuario_recibe_id'] = auth()->id();
        return response()->json(RecepcionCompra::create($data), 201);
    }

    public function show(RecepcionCompra $recepcionesCompra)
    {
        return response()->json($recepcionesCompra->load('ordenCompra', 'proveedor', 'almacen'));
    }

    public function update(Request $request, RecepcionCompra $recepcionesCompra)
    {
        $data = $request->validate([
            'estado' => 'string|max:50',
            'observaciones' => 'nullable|string',
        ]);
        $recepcionesCompra->update($data);
        return response()->json($recepcionesCompra);
    }

    public function destroy(RecepcionCompra $recepcionesCompra)
    {
        $recepcionesCompra->delete();
        return response()->json(['message' => 'Eliminado']);
    }
}
