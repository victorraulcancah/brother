<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AjusteInventario extends Model
{
    protected $table = 'ajustes_inventario';

    protected $fillable = [
        'almacen_id',
        'tipo',
        'motivo',
        'estado',
        'usuario_solicita_id',
        'usuario_aprueba_id',
        'fecha',
        'observaciones',
    ];

    protected function casts(): array
    {
        return [
            'fecha' => 'datetime',
        ];
    }

    public function almacen()
    {
        return $this->belongsTo(Almacen::class);
    }

    public function usuarioSolicita()
    {
        return $this->belongsTo(User::class, 'usuario_solicita_id');
    }

    public function usuarioAprueba()
    {
        return $this->belongsTo(User::class, 'usuario_aprueba_id');
    }

    public function detalles()
    {
        return $this->hasMany(AjusteDetalle::class);
    }
}
