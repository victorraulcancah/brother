<?php

namespace App\Http\Controllers;

use App\Models\AperturaCaja;
use App\Models\CuentaPorCobrar;
use App\Models\CuentaPorCobrarPago;
use App\Models\MovimientoCaja;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CuentaPorCobrarController extends Controller
{
    /** Formas de pago admitidas (mismas que el POS). */
    private const FORMAS = 'efectivo,transferencia,tarjeta,yape,plin,otro';

    public function index()
    {
        return response()->json(
            CuentaPorCobrar::with(['cliente:id,nombre', 'notaVenta:id', 'pagos'])
                ->latest('id')
                ->get()
        );
    }

    public function show(CuentaPorCobrar $cuenta)
    {
        return response()->json($cuenta->load(['cliente:id,nombre', 'pagos']));
    }

    /** Registra uno o varios pagos (mixto) contra la cuenta y genera movimiento de caja. */
    public function registrarPago(Request $request, CuentaPorCobrar $cuenta)
    {
        if ($cuenta->estado === 'anulado' || $cuenta->estado === 'pagado') {
            return response()->json(['message' => 'La cuenta no admite más pagos.'], 422);
        }

        $data = $request->validate([
            'fecha' => 'nullable|date',
            'pagos' => 'required|array|min:1',
            'pagos.*.forma_pago' => 'required|in:'.self::FORMAS,
            'pagos.*.monto' => 'required|numeric|min:0.01',
            'pagos.*.referencia' => 'nullable|string|max:100',
        ]);

        $totalNuevo = collect($data['pagos'])->sum(fn ($p) => (float) $p['monto']);
        if ($totalNuevo > (float) $cuenta->saldo + 0.01) {
            return response()->json(['message' => 'El pago excede el saldo pendiente.'], 422);
        }

        $fecha = $data['fecha'] ?? now()->toDateString();

        DB::transaction(function () use ($cuenta, $data, $fecha) {
            $apertura = $this->aperturaAbierta();
            foreach ($data['pagos'] as $p) {
                $mov = $apertura
                    ? MovimientoCaja::create([
                        'apertura_caja_id' => $apertura->id,
                        'tipo' => 'ingreso',
                        'monto' => (float) $p['monto'],
                        'fecha' => $fecha,
                        'numero_operacion' => $p['referencia'] ?? null,
                        'documento_referencia_tipo' => 'cuenta_por_cobrar',
                        'documento_referencia_id' => $cuenta->id,
                    ])
                    : null;

                $cuenta->pagos()->create([
                    'forma_pago' => $p['forma_pago'],
                    'monto' => (float) $p['monto'],
                    'referencia' => $p['referencia'] ?? null,
                    'movimiento_caja_id' => $mov?->id,
                    'fecha' => $fecha,
                ]);
            }
            $this->recalcular($cuenta);
        });

        return response()->json($cuenta->fresh()->load(['cliente:id,nombre', 'pagos']));
    }

    /** Edita un pago existente y ajusta su movimiento de caja. */
    public function actualizarPago(Request $request, CuentaPorCobrarPago $pago)
    {
        $data = $request->validate([
            'forma_pago' => 'required|in:'.self::FORMAS,
            'monto' => 'required|numeric|min:0.01',
            'referencia' => 'nullable|string|max:100',
            'fecha' => 'nullable|date',
        ]);

        $cuenta = $pago->cuentaPorCobrar;
        $pagadoOtros = (float) $cuenta->pagos()->where('id', '!=', $pago->id)->sum('monto');
        if ($pagadoOtros + (float) $data['monto'] > (float) $cuenta->monto_total + 0.01) {
            return response()->json(['message' => 'El monto excede el total de la cuenta.'], 422);
        }

        DB::transaction(function () use ($pago, $cuenta, $data) {
            $pago->update([
                'forma_pago' => $data['forma_pago'],
                'monto' => (float) $data['monto'],
                'referencia' => $data['referencia'] ?? null,
                'fecha' => $data['fecha'] ?? $pago->fecha,
            ]);

            if ($pago->movimiento_caja_id) {
                MovimientoCaja::where('id', $pago->movimiento_caja_id)->update([
                    'monto' => (float) $data['monto'],
                    'numero_operacion' => $data['referencia'] ?? null,
                    'fecha' => $data['fecha'] ?? $pago->fecha,
                ]);
            }

            $this->recalcular($cuenta);
        });

        return response()->json($cuenta->fresh()->load(['cliente:id,nombre', 'pagos']));
    }

    /** Anula (elimina) un pago y revierte su movimiento de caja. */
    public function anularPago(CuentaPorCobrarPago $pago)
    {
        $cuenta = $pago->cuentaPorCobrar;

        DB::transaction(function () use ($pago, $cuenta) {
            if ($pago->movimiento_caja_id) {
                MovimientoCaja::where('id', $pago->movimiento_caja_id)->delete();
            }
            $pago->delete();
            $this->recalcular($cuenta);
        });

        return response()->json($cuenta->fresh()->load(['cliente:id,nombre', 'pagos']));
    }

    private function aperturaAbierta(): ?AperturaCaja
    {
        return AperturaCaja::where('estado', 'abierta')->latest('fecha_apertura')->first();
    }

    private function recalcular(CuentaPorCobrar $cuenta): void
    {
        $pagado = (float) $cuenta->pagos()->sum('monto');
        $total = (float) $cuenta->monto_total;
        $saldo = round($total - $pagado, 2);
        $estado = $saldo <= 0.005 ? 'pagado' : ($pagado > 0 ? 'parcial' : 'pendiente');

        $cuenta->update([
            'monto_pagado' => $pagado,
            'saldo' => max($saldo, 0),
            'estado' => $estado,
        ]);
    }
}
