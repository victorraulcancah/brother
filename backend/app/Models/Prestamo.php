<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Prestamo extends Model
{
    protected $table = 'prestamos';

    protected $fillable = [
        'almacen_id',
        'tipo',
        'tercero',
        'fecha_prestamo',
        'fecha_devolucion_esperada',
        'fecha_devolucion',
        'estado',
        'usuario_id',
        'observaciones',
    ];

    protected function casts(): array
    {
        return [
            'fecha_prestamo' => 'datetime',
            'fecha_devolucion_esperada' => 'date',
            'fecha_devolucion' => 'datetime',
        ];
    }

    public function almacen()
    {
        return $this->belongsTo(Almacen::class);
    }

    public function usuario()
    {
        return $this->belongsTo(User::class, 'usuario_id');
    }

    public function detalles()
    {
        return $this->hasMany(PrestamoDetalle::class);
    }

    public function devoluciones()
    {
        return $this->hasMany(PrestamoDevolucion::class);
    }
}
