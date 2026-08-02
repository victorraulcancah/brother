<?php

namespace App\Http\Controllers;

use App\Models\Compra;
use App\Models\SerieDocumento;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CompraController extends Controller
{
    public function index()
    {
        return response()->json(
            Compra::with('proveedor:id,nombre')->withCount('detalles')->latest('id')->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'proveedor_id' => 'nullable|exists:proveedores,id',
            'orden_compra_id' => 'nullable|exists:ordenes_compra,id',
            'tipo_documento' => 'required|string|max:30',
            'serie' => 'nullable|string|max:20',
            'numero' => 'nullable|string|max:30',
            'guia' => 'nullable|string|max:30',
            'fecha' => 'required|date',
            'forma_pago' => 'required|in:contado,credito',
            'dias_credito' => 'nullable|integer|min:0',
            'fecha_vencimiento' => 'nullable|date',
            'flete' => 'nullable|numeric|min:0',
            'observaciones' => 'nullable|string',
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_presentacion_id' => 'required|exists:producto_presentaciones,id',
            'detalles.*.cantidad' => 'required|numeric|min:0.01',
            'detalles.*.costo_unitario' => 'required|numeric|min:0',
            'pagos' => 'nullable|array',
            'pagos.*.metodo' => 'required_with:pagos|string|max:40',
            'pagos.*.monto' => 'required_with:pagos|numeric|min:0',
        ]);

        $compra = DB::transaction(function () use ($data) {
            $subtotal = 0;
            foreach ($data['detalles'] as $d) {
                $subtotal += round((float) $d['cantidad'] * (float) $d['costo_unitario'], 2);
            }
            $flete = (float) ($data['flete'] ?? 0);

            // Correlativo interno propio de la compra (automático, desde 1). El usuario no lo ingresa.
            $serieDoc = SerieDocumento::where('tipo_documento', 'compra')
                ->where('serie', 'C001')
                ->lockForUpdate()
                ->firstOrCreate(
                    ['tipo_documento' => 'compra', 'serie' => 'C001'],
                    ['numero_actual' => 0, 'activo' => true]
                );
            $serieDoc->increment('numero_actual');
            $correlativo = $serieDoc->numero_actual;

            $compra = Compra::create([
                'correlativo' => $correlativo,
                'proveedor_id' => $data['proveedor_id'] ?? null,
                'orden_compra_id' => $data['orden_compra_id'] ?? null,
                'tipo_documento' => $data['tipo_documento'],
                'serie' => $data['serie'] ?? null,
                'numero' => $data['numero'] ?? null,
                'guia' => $data['guia'] ?? null,
                'fecha' => $data['fecha'],
                'forma_pago' => $data['forma_pago'],
                'dias_credito' => $data['dias_credito'] ?? 0,
                'fecha_vencimiento' => $data['fecha_vencimiento'] ?? null,
                'flete' => $flete,
                'subtotal' => $subtotal,
                'total' => round($subtotal + $flete, 2),
                'estado' => 'registrada',
                'observaciones' => $data['observaciones'] ?? null,
                'usuario_id' => auth()->id(),
            ]);

            foreach ($data['detalles'] as $d) {
                $cantidad = (float) $d['cantidad'];
                $costo = (float) $d['costo_unitario'];
                $compra->detalles()->create([
                    'producto_presentacion_id' => $d['producto_presentacion_id'],
                    'cantidad' => $cantidad,
                    'costo_unitario' => $costo,
                    'subtotal' => round($cantidad * $costo, 2),
                ]);
            }

            foreach ($data['pagos'] ?? [] as $pago) {
                if ((float) $pago['monto'] <= 0) {
                    continue;
                }
                $compra->pagos()->create([
                    'metodo' => $pago['metodo'],
                    'monto' => (float) $pago['monto'],
                ]);
            }

            return $compra;
        });

        return response()->json(
            $compra->load(['proveedor:id,nombre', 'detalles.presentacion.producto', 'pagos']),
            201
        );
    }

    public function show(Compra $compra)
    {
        return response()->json(
            $compra->load(['proveedor:id,nombre', 'ordenCompra:id,codigo', 'detalles.presentacion.producto', 'pagos'])
        );
    }

    public function update(Request $request, Compra $compra)
    {
        $data = $request->validate(['observaciones' => 'nullable|string']);
        $compra->update($data);
        return response()->json($compra);
    }

    public function anular(Compra $compra)
    {
        $compra->update(['estado' => 'anulada']);
        return response()->json($compra->fresh());
    }

    public function destroy(Compra $compra)
    {
        $compra->delete();
        return response()->json(['message' => 'Eliminado']);
    }
}
