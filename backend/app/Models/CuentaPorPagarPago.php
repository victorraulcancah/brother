<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CuentaPorPagarPago extends Model
{
    protected $table = 'cuentas_por_pagar_pagos';

    protected $fillable = [
        'cuenta_por_pagar_id',
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

    public function cuentaPorPagar()
    {
        return $this->belongsTo(CuentaPorPagar::class, 'cuenta_por_pagar_id');
    }

    public function movimientoCaja()
    {
        return $this->belongsTo(MovimientoCaja::class, 'movimiento_caja_id');
    }
}
