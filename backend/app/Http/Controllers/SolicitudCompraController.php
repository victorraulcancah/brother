<?php

namespace App\Http\Controllers;

use App\Models\SolicitudCompra;
use Illuminate\Http\Request;

class SolicitudCompraController extends Controller
{
    public function __construct()
    {
    }

    public function index()
    {
        return response()->json(SolicitudCompra::all());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'codigo' => 'required|string|max:50|unique:solicitudes_compra,codigo',
            'observaciones' => 'nullable|string',
        ]);
        $data['fecha_solicitud'] = now();
        $data['usuario_solicita_id'] = auth()->id();
        return response()->json(SolicitudCompra::create($data), 201);
    }

    public function show(SolicitudCompra $solicitudesCompra)
    {
        // route key name is 'codigo' so we may need to find differently
        return response()->json($solicitudesCompra);
    }

    public function update(Request $request, SolicitudCompra $solicitudesCompra)
    {
        $data = $request->validate([
            'estado' => 'string|max:50',
            'observaciones' => 'nullable|string',
        ]);
        $solicitudesCompra->update($data);
        return response()->json($solicitudesCompra);
    }

    public function destroy(SolicitudCompra $solicitudesCompra)
    {
        $solicitudesCompra->delete();
        return response()->json(['message' => 'Eliminado']);
    }
}
