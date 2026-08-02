<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Caja extends Model
{
    protected $table = 'cajas';

    protected $fillable = [
        'nombre',
        'almacen_id',
        'activo',
    ];

    protected function casts(): array
    {
        return ['activo' => 'boolean'];
    }

    public function almacen()
    {
        return $this->belongsTo(Almacen::class);
    }

    public function metodosPago()
    {
        return $this->belongsToMany(MetodoPago::class, 'caja_metodo_pago')
            ->withTimestamps()
            ->orderBy('metodos_pago.nombre');
    }

    public function aperturas()
    {
        return $this->hasMany(AperturaCaja::class);
    }
}
