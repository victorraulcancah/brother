<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MotivoMovimiento extends Model
{
    protected $table = 'motivos_movimiento';

    protected $fillable = [
        'nombre',
        'tipo',
        'ambito',
        'es_sistema',
        'activo',
    ];

    protected function casts(): array
    {
        return [
            'es_sistema' => 'boolean',
            'activo' => 'boolean',
        ];
    }
}
