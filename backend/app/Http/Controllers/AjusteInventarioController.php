<?php

namespace App\Http\Controllers;

use App\Models\AjusteInventario;
use App\Models\Almacen;
use App\Models\ProductoPresentacion;
use App\Services\StockService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AjusteInventarioController extends Controller
{
    public function index()
    {
        return response()->json(
            AjusteInventario::with('almacen')->withCount('detalles')->latest('id')->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'almacen_id' => 'required|exists:almacenes,id',
            'tipo' => 'required|in:entrada,salida',
            'motivo' => 'required|string',
            'observaciones' => 'nullable|string',
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_presentacion_id' => 'required|exists:producto_presentaciones,id',
            'detalles.*.cantidad' => 'required|numeric|min:0.01',
        ]);

        try {
            $ajuste = DB::transaction(function () use ($data) {
                $ajuste = AjusteInventario::create([
                    'almacen_id' => $data['almacen_id'],
                    'tipo' => $data['tipo'],
                    'motivo' => $data['motivo'],
                    'observaciones' => $data['observaciones'] ?? null,
                    'estado' => 'aprobado',
                    'usuario_solicita_id' => auth()->id(),
                    'usuario_aprueba_id' => auth()->id(),
                    'fecha' => now(),
                ]);

                $almacen = Almacen::findOrFail($data['almacen_id']);
                $stock = app(StockService::class);

                foreach ($data['detalles'] as $detalle) {
                    $presentacion = ProductoPresentacion::findOrFail($detalle['producto_presentacion_id']);
                    $cantidad = (float) $detalle['cantidad'];

                    $ajuste->detalles()->create([
                        'producto_presentacion_id' => $presentacion->id,
                        'cantidad' => $cantidad,
                    ]);

                    // "entrada" suma stock; "salida" lo resta.
                    $args = [$presentacion, $almacen, $cantidad, 0, 'ajuste_manual', 'ajuste_inventario', $ajuste->id, auth()->id()];
                    $data['tipo'] === 'salida' ? $stock->salida(...$args) : $stock->entrada(...$args);
                }

                return $ajuste;
            });
        } catch (\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json(
            $ajuste->load(['almacen', 'detalles.presentacion.producto']),
            201
        );
    }

    public function show(AjusteInventario $ajuste)
    {
        return response()->json($ajuste->load(['almacen', 'detalles.presentacion.producto']));
    }

    public function update(Request $request, AjusteInventario $ajuste)
    {
        $data = $request->validate([
            'observaciones' => 'nullable|string',
        ]);
        $ajuste->update($data);
        return response()->json($ajuste);
    }

    public function destroy(AjusteInventario $ajuste)
    {
        $ajuste->delete();
        return response()->json(['message' => 'Eliminado']);
    }
}
