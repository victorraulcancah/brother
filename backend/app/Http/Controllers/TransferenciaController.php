<?php

namespace App\Http\Controllers;

use App\Models\Transferencia;
use Illuminate\Http\Request;

class TransferenciaController extends Controller
{
    public function __construct()
    {
    }

    public function index()
    {
        return response()->json(Transferencia::with('almacenOrigen', 'almacenDestino')->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'almacen_origen_id' => 'required|exists:almacenes,id',
            'almacen_destino_id' => 'required|exists:almacenes,id|different:almacen_origen_id',
            'observaciones' => 'nullable|string',
        ]);
        $data['estado'] = 'pendiente';
        $data['usuario_envio_id'] = auth()->id();
        return response()->json(Transferencia::create($data), 201);
    }

    public function show(Transferencia $transferencia)
    {
        return response()->json($transferencia->load('almacenOrigen', 'almacenDestino'));
    }

    public function update(Request $request, Transferencia $transferencia)
    {
        $data = $request->validate([
            'estado' => 'string|max:50',
            'observaciones' => 'nullable|string',
        ]);
        $transferencia->update($data);
        return response()->json($transferencia);
    }

    public function destroy(Transferencia $transferencia)
    {
        $transferencia->delete();
        return response()->json(['message' => 'Eliminado']);
    }
}
