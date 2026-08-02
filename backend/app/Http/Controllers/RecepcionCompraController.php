<?php

namespace App\Http\Controllers;

use App\Models\Almacen;
use App\Models\ProductoPresentacion;
use App\Models\RecepcionCompra;
use App\Models\SerieDocumento;
use App\Services\StockService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RecepcionCompraController extends Controller
{
    public function index()
    {
        return response()->json(
            RecepcionCompra::with(['proveedor:id,nombre', 'almacen:id,nombre', 'ordenCompra:id,codigo'])
                ->withCount('detalles')
                ->latest('id')
                ->get()
        );
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
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_presentacion_id' => 'required|exists:producto_presentaciones,id',
            'detalles.*.cantidad_recibida' => 'required|numeric|min:0.01',
            'detalles.*.costo_unitario' => 'required|numeric|min:0',
        ]);

        try {
            $recepcion = DB::transaction(function () use ($data) {
                // Correlativo formal del documento de recepción (ej. RA0001-00000019).
                $serie = 'RA0001';
                $serieDoc = SerieDocumento::where('tipo_documento', 'recepcion_almacen')
                    ->where('serie', $serie)
                    ->lockForUpdate()
                    ->firstOrCreate(
                        ['tipo_documento' => 'recepcion_almacen', 'serie' => $serie],
                        ['numero_actual' => 0, 'activo' => true]
                    );
                $serieDoc->increment('numero_actual');
                $numero = str_pad($serieDoc->numero_actual, 8, '0', STR_PAD_LEFT);

                $recepcion = RecepcionCompra::create([
                    'orden_compra_id' => $data['orden_compra_id'] ?? null,
                    'proveedor_id' => $data['proveedor_id'] ?? null,
                    'almacen_id' => $data['almacen_id'],
                    'serie' => $serie,
                    'numero' => $numero,
                    'numero_documento' => $data['numero_documento'] ?? null,
                    'tipo_documento' => $data['tipo_documento'] ?? null,
                    'fecha_recepcion' => $data['fecha_recepcion'],
                    'observaciones' => $data['observaciones'] ?? null,
                    'estado' => 'completa',
                    'stock_aplicado' => true,
                    'usuario_recibe_id' => auth()->id(),
                ]);

                $almacen = Almacen::findOrFail($data['almacen_id']);
                $stock = app(StockService::class);

                foreach ($data['detalles'] as $detalle) {
                    $presentacion = ProductoPresentacion::findOrFail($detalle['producto_presentacion_id']);
                    $cantidad = (float) $detalle['cantidad_recibida'];
                    $costoPresentacion = (float) $detalle['costo_unitario'];

                    $recepcion->detalles()->create([
                        'producto_presentacion_id' => $presentacion->id,
                        'cantidad_ordenada' => $cantidad,
                        'cantidad_recibida' => $cantidad,
                        'cantidad_conforme' => $cantidad,
                        'cantidad_rechazada' => 0,
                        'costo_unitario' => $costoPresentacion,
                    ]);

                    // StockService valoriza en unidad base; el costo ingresado es por
                    // presentación (ej. por caja), así que lo convertimos a costo por unidad base.
                    $factor = (float) $presentacion->factor_conversion ?: 1;
                    $costoBase = $factor > 0 ? $costoPresentacion / $factor : $costoPresentacion;

                    $stock->entrada(
                        $presentacion,
                        $almacen,
                        $cantidad,
                        $costoBase,
                        'compra',
                        'recepcion_compra',
                        $recepcion->id,
                        auth()->id(),
                    );
                }

                // Si viene de una orden, la marcamos como completada.
                if ($recepcion->orden_compra_id) {
                    $recepcion->ordenCompra?->update(['estado' => 'completada']);
                }

                return $recepcion;
            });
        } catch (\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json(
            $recepcion->load(['proveedor:id,nombre', 'almacen:id,nombre', 'detalles.presentacion.producto']),
            201
        );
    }

    public function show(RecepcionCompra $recepcionesCompra)
    {
        return response()->json(
            $recepcionesCompra->load(['proveedor:id,nombre', 'almacen:id,nombre', 'ordenCompra:id,codigo', 'detalles.presentacion.producto'])
        );
    }

    public function update(Request $request, RecepcionCompra $recepcionesCompra)
    {
        $data = $request->validate(['observaciones' => 'nullable|string']);
        $recepcionesCompra->update($data);
        return response()->json($recepcionesCompra);
    }

    public function destroy(RecepcionCompra $recepcionesCompra)
    {
        if ($recepcionesCompra->stock_aplicado) {
            return response()->json([
                'message' => 'No se puede eliminar una recepción que ya ingresó stock. Usa un ajuste para corregir.',
            ], 422);
        }
        $recepcionesCompra->delete();
        return response()->json(['message' => 'Eliminado']);
    }
}
