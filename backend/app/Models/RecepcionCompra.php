<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RecepcionCompra extends Model
{
    protected $table = 'recepciones_compra';

    protected $fillable = [
        'orden_compra_id',
        'proveedor_id',
        'almacen_id',
        'numero_documento',
        'tipo_documento',
        'fecha_recepcion',
        'estado',
        'stock_aplicado',
        'usuario_recibe_id',
        'observaciones',
    ];

    protected function casts(): array
    {
        return [
            'fecha_recepcion' => 'datetime',
            'stock_aplicado' => 'boolean',
        ];
    }

    public function ordenCompra()
    {
        return $this->belongsTo(OrdenCompra::class);
    }

    public function proveedor()
    {
        return $this->belongsTo(Proveedor::class);
    }

    public function almacen()
    {
        return $this->belongsTo(Almacen::class);
    }

    public function usuarioRecibe()
    {
        return $this->belongsTo(User::class, 'usuario_recibe_id');
    }

    public function detalles()
    {
        return $this->hasMany(RecepcionCompraDetalle::class);
    }

    public function devoluciones()
    {
        return $this->hasMany(DevolucionProveedor::class);
    }
}
