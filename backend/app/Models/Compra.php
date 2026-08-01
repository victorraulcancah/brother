<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Compra extends Model
{
    protected $table = 'compras';

    protected $fillable = [
        'proveedor_id',
        'orden_compra_id',
        'tipo_documento',
        'serie',
        'numero',
        'guia',
        'fecha',
        'forma_pago',
        'dias_credito',
        'fecha_vencimiento',
        'flete',
        'subtotal',
        'total',
        'estado',
        'observaciones',
        'usuario_id',
    ];

    protected function casts(): array
    {
        return [
            'fecha' => 'date',
            'fecha_vencimiento' => 'date',
            'flete' => 'decimal:2',
            'subtotal' => 'decimal:2',
            'total' => 'decimal:2',
        ];
    }

    public function proveedor()
    {
        return $this->belongsTo(Proveedor::class);
    }

    public function ordenCompra()
    {
        return $this->belongsTo(OrdenCompra::class);
    }

    public function usuario()
    {
        return $this->belongsTo(User::class, 'usuario_id');
    }

    public function detalles()
    {
        return $this->hasMany(CompraDetalle::class);
    }

    public function pagos()
    {
        return $this->hasMany(CompraPago::class);
    }
}
