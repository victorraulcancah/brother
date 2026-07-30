<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CuentaPorCobrarPago extends Model
{
    protected $table = 'cuentas_por_cobrar_pagos';

    protected $fillable = [
        'cuenta_por_cobrar_id',
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

    public function cuentaPorCobrar()
    {
        return $this->belongsTo(CuentaPorCobrar::class, 'cuenta_por_cobrar_id');
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
