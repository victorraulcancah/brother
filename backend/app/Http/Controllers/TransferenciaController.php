<?php

namespace App\Http\Controllers;

use App\Models\Almacen;
use App\Models\ProductoPresentacion;
use App\Models\Transferencia;
use App\Services\StockService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TransferenciaController extends Controller
{
    public function index()
    {
        return response()->json(
            Transferencia::with('almacenOrigen', 'almacenDestino')
                ->withCount('detalles')
                ->latest('id')
                ->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'almacen_origen_id' => 'required|exists:almacenes,id',
            'almacen_destino_id' => 'required|exists:almacenes,id|different:almacen_origen_id',
            'observaciones' => 'nullable|string',
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_presentacion_id' => 'required|exists:producto_presentaciones,id',
            'detalles.*.cantidad_enviada' => 'required|numeric|min:0.01',
        ]);

        $transferencia = DB::transaction(function () use ($data) {
            $transferencia = Transferencia::create([
                'almacen_origen_id' => $data['almacen_origen_id'],
                'almacen_destino_id' => $data['almacen_destino_id'],
                'observaciones' => $data['observaciones'] ?? null,
                'estado' => 'pendiente',
                'usuario_envio_id' => auth()->id(),
            ]);

            foreach ($data['detalles'] as $detalle) {
                $transferencia->detalles()->create([
                    'producto_presentacion_id' => $detalle['producto_presentacion_id'],
                    'cantidad_enviada' => $detalle['cantidad_enviada'],
                ]);
            }

            return $transferencia;
        });

        return response()->json($transferencia->load(['almacenOrigen', 'almacenDestino', 'detalles.presentacion.producto']), 201);
    }

    public function show(Transferencia $transferencia)
    {
        return response()->json(
            $transferencia->load(['almacenOrigen', 'almacenDestino', 'detalles.presentacion.producto'])
        );
    }

    public function update(Request $request, Transferencia $transferencia)
    {
        $data = $request->validate(['observaciones' => 'nullable|string']);
        $transferencia->update($data);
        return response()->json($transferencia);
    }

    public function destroy(Transferencia $transferencia)
    {
        if ($transferencia->estado !== 'pendiente') {
            return response()->json(['message' => 'Solo se pueden eliminar traslados pendientes.'], 422);
        }
        $transferencia->delete();
        return response()->json(['message' => 'Eliminado']);
    }

    /** Enviar: descuenta el stock del almacén de origen y pasa a "en tránsito". */
    public function enviar(Transferencia $transferencia)
    {
        if ($transferencia->estado !== 'pendiente') {
            return response()->json(['message' => 'El traslado ya fue enviado o cancelado.'], 422);
        }

        try {
            DB::transaction(function () use ($transferencia) {
                $transferencia->loadMissing('detalles.presentacion');
                $origen = Almacen::findOrFail($transferencia->almacen_origen_id);
                $stock = app(StockService::class);

                foreach ($transferencia->detalles as $detalle) {
                    if (! $detalle->presentacion) {
                        continue;
                    }
                    $stock->salida(
                        $detalle->presentacion,
                        $origen,
                        (float) $detalle->cantidad_enviada,
                        0,
                        'transferencia',
                        'transferencia',
                        $transferencia->id,
                        auth()->id(),
                    );
                }

                $transferencia->update([
                    'estado' => 'en_transito',
                    'fecha_envio' => now(),
                    'usuario_envio_id' => auth()->id(),
                ]);
            });
        } catch (\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json($transferencia->fresh());
    }

    /** Recibir: ingresa el stock al almacén de destino y pasa a "recibida". */
    public function recibir(Transferencia $transferencia)
    {
        if ($transferencia->estado !== 'en_transito') {
            return response()->json(['message' => 'Solo se pueden recibir traslados en tránsito.'], 422);
        }

        DB::transaction(function () use ($transferencia) {
            $transferencia->loadMissing('detalles.presentacion');
            $destino = Almacen::findOrFail($transferencia->almacen_destino_id);
            $stock = app(StockService::class);

            foreach ($transferencia->detalles as $detalle) {
                if (! $detalle->presentacion) {
                    continue;
                }
                $cantidad = (float) $detalle->cantidad_enviada;
                $detalle->update(['cantidad_recibida' => $cantidad]);
                $stock->entrada(
                    $detalle->presentacion,
                    $destino,
                    $cantidad,
                    0,
                    'transferencia',
                    'transferencia',
                    $transferencia->id,
                    auth()->id(),
                );
            }

            $transferencia->update([
                'estado' => 'recibida',
                'fecha_recepcion' => now(),
                'usuario_recepcion_id' => auth()->id(),
            ]);
        });

        return response()->json($transferencia->fresh());
    }

    /** Anular un traslado pendiente (aún no envía stock). */
    public function anular(Transferencia $transferencia)
    {
        if ($transferencia->estado !== 'pendiente') {
            return response()->json(['message' => 'Solo se pueden anular traslados pendientes.'], 422);
        }
        $transferencia->update(['estado' => 'cancelada']);
        return response()->json($transferencia->fresh());
    }
}
