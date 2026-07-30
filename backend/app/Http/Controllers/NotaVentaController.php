<?php

namespace App\Http\Controllers;

use App\Models\AperturaCaja;
use App\Models\CuentaPorCobrar;
use App\Models\MovimientoCaja;
use App\Models\NotaVenta;
use App\Models\SerieDocumento;
use App\Services\StockService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotaVentaController extends Controller
{
    public function __construct(
        protected StockService $stockService
    ) {}

    public function index()
    {
        return response()->json(
            NotaVenta::with(['cliente', 'almacen', 'vendedor', 'detalles.presentacion.producto', 'pagos.metodoPago'])
                ->orderBy('created_at', 'desc')
                ->paginate(15)
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'cliente_id' => 'nullable|exists:clientes,id',
            'almacen_id' => 'required|exists:almacenes,id',
            'vendedor_id' => 'required|exists:users,id',
            'fecha_emision' => 'required|date',
            'moneda' => 'string|max:10|in:PEN,USD',
            'tipo_pago' => 'string|max:20|in:contado,credito',
            'subtotal' => 'required|numeric|min:0',
            'descuento_total' => 'numeric|min:0',
            'total' => 'required|numeric|min:0',
            'observaciones' => 'nullable|string',
            'serie' => 'nullable|string|max:10',
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_presentacion_id' => 'required|exists:producto_presentaciones,id',
            'detalles.*.cantidad' => 'required|numeric|min:0.01',
            'detalles.*.precio_unitario' => 'required|numeric|min:0',
            'detalles.*.descuento' => 'numeric|min:0',
            'detalles.*.subtotal' => 'required|numeric|min:0',
            'pagos' => 'required|array|min:1',
            'pagos.*.metodo_pago_id' => 'nullable|exists:metodos_pago,id',
            'pagos.*.forma_pago' => 'required|string|max:30',
            'pagos.*.monto' => 'required|numeric|min:0.01',
            'pagos.*.fecha' => 'required|date',
            'pagos.*.referencia' => 'nullable|string|max:100',
        ]);

        return DB::transaction(function () use ($data) {
            $serie = $data['serie'] ?? 'NV01';
            $serieDoc = SerieDocumento::firstOrCreate(
                ['tipo_documento' => 'nota_venta', 'serie' => $serie],
                ['numero_actual' => 0, 'activo' => true]
            );
            $serieDoc->increment('numero_actual');
            $numero = str_pad($serieDoc->numero_actual, 3, '0', STR_PAD_LEFT);

            $nota = NotaVenta::create([
                'serie' => $serie,
                'numero' => $numero,
                'cliente_id' => $data['cliente_id'] ?? null,
                'almacen_id' => $data['almacen_id'],
                'vendedor_id' => $data['vendedor_id'],
                'fecha_emision' => $data['fecha_emision'],
                'moneda' => $data['moneda'] ?? 'PEN',
                'tipo_pago' => $data['tipo_pago'] ?? 'contado',
                'subtotal' => $data['subtotal'],
                'descuento_total' => $data['descuento_total'] ?? 0,
                'total' => $data['total'],
                'estado' => 'emitida',
                'observaciones' => $data['observaciones'] ?? null,
            ]);

            $nota->detalles()->createMany($data['detalles']);
            $nota->pagos()->createMany($data['pagos']);

            $nota->load(['detalles.presentacion', 'almacen']);

            foreach ($nota->detalles as $detalle) {
                $this->stockService->salida(
                    $detalle->presentacion,
                    $nota->almacen,
                    (float) $detalle->cantidad,
                    0,
                    'nota_venta',
                    'nota_venta',
                    $nota->id,
                    auth()->id(),
                    $data['fecha_emision']
                );
            }

            $apertura = AperturaCaja::where('estado', 'abierta')
                ->whereHas('caja', fn ($q) => $q->where('almacen_id', $data['almacen_id']))
                ->latest('fecha_apertura')
                ->first();

            if ($apertura && $data['tipo_pago'] === 'contado') {
                foreach ($data['pagos'] as $pago) {
                    $movData = [
                        'apertura_caja_id' => $apertura->id,
                        'tipo' => 'ingreso',
                        'metodo_pago_id' => $pago['metodo_pago_id'] ?? null,
                        'monto' => $pago['monto'],
                        'fecha' => $pago['fecha'],
                        'numero_operacion' => $pago['referencia'] ?? null,
                        'documento_referencia_tipo' => 'nota_venta',
                        'documento_referencia_id' => $nota->id,
                    ];

                    $mpId = $pago['metodo_pago_id'] ?? null;
                    if ($mpId) {
                        $mp = \App\Models\MetodoPago::find($mpId);
                        if ($mp) {
                            if ($mp->tipo === 'banco') {
                                $movData['cuenta_bancaria_id'] = null;
                            } elseif ($mp->tipo === 'tarjeta') {
                                $movData['tarjeta_id'] = null;
                            } elseif ($mp->tipo === 'billetera') {
                                $movData['billetera_id'] = null;
                            }
                        }
                    }

                    MovimientoCaja::create($movData);
                }
            }

            if ($data['tipo_pago'] === 'credito' && ($data['cliente_id'] ?? null)) {
                CuentaPorCobrar::create([
                    'nota_venta_id' => $nota->id,
                    'cliente_id' => $data['cliente_id'],
                    'monto_total' => $data['total'],
                    'monto_pagado' => 0,
                    'saldo' => $data['total'],
                    'fecha_vencimiento' => $data['fecha_emision'],
                    'estado' => 'pendiente',
                ]);
            }

            return response()->json(
                $nota->load(['cliente', 'almacen', 'vendedor', 'detalles.presentacion.producto', 'pagos.metodoPago']),
                201
            );
        });
    }

    public function show(NotaVenta $notaVenta)
    {
        return response()->json(
            $notaVenta->load(['cliente', 'almacen', 'vendedor', 'detalles.presentacion.producto', 'pagos.metodoPago'])
        );
    }

    public function anular(Request $request, NotaVenta $notaVenta)
    {
        $data = $request->validate([
            'motivo_anulacion' => 'required|string|max:500',
        ]);

        if ($notaVenta->estado !== 'emitida') {
            return response()->json(['message' => 'Solo se pueden anular notas de venta emitidas'], 422);
        }

        return DB::transaction(function () use ($notaVenta, $data) {
            $notaVenta->update([
                'estado' => 'anulada',
                'motivo_anulacion' => $data['motivo_anulacion'],
                'usuario_anula_id' => auth()->id(),
                'fecha_anulacion' => now(),
            ]);

            $notaVenta->load(['detalles.presentacion', 'almacen']);

            foreach ($notaVenta->detalles as $detalle) {
                $this->stockService->entrada(
                    $detalle->presentacion,
                    $notaVenta->almacen,
                    (float) $detalle->cantidad,
                    0,
                    'anulacion_nota_venta',
                    'nota_venta',
                    $notaVenta->id,
                    auth()->id(),
                    now()->toDateTimeString()
                );
            }

            MovimientoCaja::where('documento_referencia_tipo', 'nota_venta')
                ->where('documento_referencia_id', $notaVenta->id)
                ->delete();

            CuentaPorCobrar::where('nota_venta_id', $notaVenta->id)->delete();

            return response()->json(
                $notaVenta->load(['cliente', 'almacen', 'vendedor', 'detalles.presentacion.producto', 'pagos.metodoPago'])
            );
        });
    }

    public function destroy(NotaVenta $notaVenta)
    {
        $notaVenta->delete();
        return response()->json(['message' => 'Nota de venta eliminada correctamente']);
    }
}
