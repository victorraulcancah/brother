<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CuentaPorCobrarPago extends Model
{
    protected $table = 'cuentas_por_cobrar_pagos';

    protected $fillable = [
        'cuenta_por_cobrar_id',
        'forma_pago',
        'monto',
        'movimiento_caja_id',
        'referencia',
        'fecha',
    ];

    protected function casts(): array
    {
        return [
            'monto' => 'decimal:2',
            'fecha' => 'date',
        ];
    }

    public function cuentaPorCobrar()
    {
        return $this->belongsTo(CuentaPorCobrar::class, 'cuenta_por_cobrar_id');
    }

    public function movimientoCaja()
    {
        return $this->belongsTo(MovimientoCaja::class, 'movimiento_caja_id');
    }
}
