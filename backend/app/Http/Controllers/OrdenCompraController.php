<?php

namespace App\Http\Controllers;

use App\Models\OrdenCompra;
use Illuminate\Http\Request;

class OrdenCompraController extends Controller
{
    public function __construct()
    {
    }

    public function index()
    {
        return response()->json(OrdenCompra::with('proveedor')->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'codigo' => 'required|string|max:50|unique:ordenes_compra,codigo',
            'proveedor_id' => 'required|exists:proveedores,id',
            'fecha_emision' => 'required|date',
            'fecha_entrega_estimada' => 'nullable|date',
            'moneda' => 'string|max:10',
            'observaciones' => 'nullable|string',
        ]);
        $data['usuario_crea_id'] = auth()->id();
        return response()->json(OrdenCompra::create($data), 201);
    }

    public function show(OrdenCompra $ordenesCompra)
    {
        return response()->json($ordenesCompra->load('proveedor'));
    }

    public function update(Request $request, OrdenCompra $ordenesCompra)
    {
        $data = $request->validate([
            'estado' => 'string|max:50',
            'fecha_entrega_estimada' => 'nullable|date',
            'observaciones' => 'nullable|string',
        ]);
        $ordenesCompra->update($data);
        return response()->json($ordenesCompra);
    }

    public function destroy(OrdenCompra $ordenesCompra)
    {
        $ordenesCompra->delete();
        return response()->json(['message' => 'Eliminado']);
    }
}
