<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CuentaPorPagarPago extends Model
{
    protected $table = 'cuentas_por_pagar_pagos';

    protected $fillable = [
        'cuenta_por_pagar_id',
        'metodo_pago_id',
        'monto',
        'movimiento_caja_id',
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

    public function metodoPago()
    {
        return $this->belongsTo(MetodoPago::class, 'metodo_pago_id');
    }

    public function movimientoCaja()
    {
        return $this->belongsTo(MovimientoCaja::class, 'movimiento_caja_id');
    }
}
