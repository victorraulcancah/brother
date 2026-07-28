<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transferencia extends Model
{
    protected $table = 'transferencias';

    protected $fillable = [
        'almacen_origen_id',
        'almacen_destino_id',
        'estado',
        'fecha_envio',
        'fecha_recepcion',
        'usuario_envio_id',
        'usuario_recepcion_id',
        'observaciones',
    ];

    protected function casts(): array
    {
        return [
            'fecha_envio' => 'datetime',
            'fecha_recepcion' => 'datetime',
        ];
    }

    public function almacenOrigen()
    {
        return $this->belongsTo(Almacen::class, 'almacen_origen_id');
    }

    public function almacenDestino()
    {
        return $this->belongsTo(Almacen::class, 'almacen_destino_id');
    }

    public function usuarioEnvio()
    {
        return $this->belongsTo(User::class, 'usuario_envio_id');
    }

    public function usuarioRecepcion()
    {
        return $this->belongsTo(User::class, 'usuario_recepcion_id');
    }

    public function detalles()
    {
        return $this->hasMany(TransferenciaDetalle::class);
    }
}
