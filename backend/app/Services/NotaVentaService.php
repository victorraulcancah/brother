<?php
namespace App\Services;

use App\Models\AperturaCaja;
use App\Models\CuentaPorCobrar;
use App\Models\MotivoMovimiento;
use App\Models\MovimientoCaja;
use App\Models\NotaVenta;
use App\Models\SerieDocumento;
use Illuminate\Support\Facades\DB;

class NotaVentaService
{
    public function __construct(
        protected StockService $stockService
    ) {}

    public function crear(array $data): NotaVenta
    {
        return DB::transaction(function () use ($data) {
            $serie = $data['serie'] ?? 'NV01';
            $serieDoc = SerieDocumento::where('tipo_documento', 'nota_venta')
                ->where('serie', $serie)
                ->lockForUpdate()
                ->firstOrCreate(
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

            // El ingreso de caja va a la caja del vendedor (una caja pertenece a un usuario).
            $cajaId = \App\Models\User::find($data['vendedor_id'])?->caja_id;
            $apertura = $cajaId
                ? AperturaCaja::where('estado', 'abierta')
                    ->where('caja_id', $cajaId)
                    ->latest('fecha_apertura')
                    ->first()
                : null;

            if ($apertura && $data['tipo_pago'] === 'contado') {
                // Sin motivo, el movimiento aparece con "—" en Mi Caja.
                $motivoVentaId = MotivoMovimiento::where('tipo', 'entrada')
                    ->where('nombre', 'Ingreso por venta')
                    ->value('id');

                foreach ($data['pagos'] as $pago) {
                    MovimientoCaja::create([
                        'apertura_caja_id' => $apertura->id,
                        'tipo' => 'ingreso',
                        'motivo_movimiento_id' => $motivoVentaId,
                        'descripcion' => "Venta {$nota->serie}-{$nota->numero}",
                        'cuenta_bancaria_id' => ($pago['forma_pago'] ?? null) === 'transferencia' ? ($pago['cuenta_bancaria_id'] ?? null) : null,
                        'billetera_id' => ($pago['forma_pago'] ?? null) === 'billetera' ? ($pago['billetera_id'] ?? null) : null,
                        'monto' => $pago['monto'],
                        'fecha' => $pago['fecha'],
                        'numero_operacion' => $pago['referencia'] ?? null,
                        'documento_referencia_tipo' => 'nota_venta',
                        'documento_referencia_id' => $nota->id,
                    ]);
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

            return $nota->load([
                'cliente', 'almacen', 'vendedor',
                'detalles.presentacion.producto', 'pagos.metodoPago',
            ]);
        });
    }

    public function anular(NotaVenta $notaVenta, string $motivo): NotaVenta
    {
        if ($notaVenta->estado !== 'emitida') {
            throw new \InvalidArgumentException('Solo se pueden anular notas de venta emitidas');
        }

        return DB::transaction(function () use ($notaVenta, $motivo) {
            $notaVenta->update([
                'estado' => 'anulada',
                'motivo_anulacion' => $motivo,
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

            return $notaVenta->load([
                'cliente', 'almacen', 'vendedor',
                'detalles.presentacion.producto', 'pagos.metodoPago',
            ]);
        });
    }
}
