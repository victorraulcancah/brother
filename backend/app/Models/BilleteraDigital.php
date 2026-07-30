<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BilleteraDigital extends Model
{
    protected $table = 'billeteras_digitales';

    protected $fillable = [
        'nombre',
        'numero_asociado',
        'requiere_captura',
        'requiere_numero_operacion',
        'activo',
    ];

    protected function casts(): array
    {
        return [
            'requiere_captura' => 'boolean',
            'requiere_numero_operacion' => 'boolean',
            'activo' => 'boolean',
        ];
    }
}
