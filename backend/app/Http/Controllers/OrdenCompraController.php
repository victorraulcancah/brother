<?php

namespace App\Http\Controllers;

use App\Models\OrdenCompra;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrdenCompraController extends Controller
{
    public function index()
    {
        return response()->json(
            OrdenCompra::with('proveedor:id,nombre')->withCount('detalles')->latest('id')->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'codigo' => 'required|string|max:50|unique:ordenes_compra,codigo',
            'proveedor_id' => 'required|exists:proveedores,id',
            'fecha_emision' => 'required|date',
            'fecha_entrega_estimada' => 'nullable|date',
            'moneda' => 'nullable|string|max:10',
            'observaciones' => 'nullable|string',
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_presentacion_id' => 'required|exists:producto_presentaciones,id',
            'detalles.*.cantidad' => 'required|numeric|min:0.01',
            'detalles.*.precio_unitario' => 'required|numeric|min:0',
        ]);

        $orden = DB::transaction(function () use ($data) {
            $orden = OrdenCompra::create([
                'codigo' => $data['codigo'],
                'proveedor_id' => $data['proveedor_id'],
                'fecha_emision' => $data['fecha_emision'],
                'fecha_entrega_estimada' => $data['fecha_entrega_estimada'] ?? null,
                'moneda' => $data['moneda'] ?? 'PEN',
                'observaciones' => $data['observaciones'] ?? null,
                'estado' => 'pendiente',
                'usuario_crea_id' => auth()->id(),
            ]);

            foreach ($data['detalles'] as $detalle) {
                $cantidad = (float) $detalle['cantidad'];
                $precio = (float) $detalle['precio_unitario'];
                $orden->detalles()->create([
                    'producto_presentacion_id' => $detalle['producto_presentacion_id'],
                    'cantidad' => $cantidad,
                    'precio_unitario' => $precio,
                    'descuento' => 0,
                    'subtotal' => round($cantidad * $precio, 2),
                ]);
            }

            return $orden;
        });

        return response()->json($orden->load(['proveedor:id,nombre', 'detalles.presentacion.producto']), 201);
    }

    public function show(OrdenCompra $ordenesCompra)
    {
        return response()->json($ordenesCompra->load(['proveedor:id,nombre', 'detalles.presentacion.producto']));
    }

    public function update(Request $request, OrdenCompra $ordenesCompra)
    {
        $data = $request->validate([
            'estado' => 'nullable|string|max:50',
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
