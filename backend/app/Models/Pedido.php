<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Pedido extends Model
{
    protected $table = 'pedidos';

    protected $fillable = [
        'serie',
        'numero',
        'cliente_id',
        'almacen_id',
        'vendedor_id',
        'fecha_pedido',
        'fecha_entrega',
        'moneda',
        'subtotal',
        'descuento_total',
        'total',
        'estado',
        'nota_venta_id',
        'motivo_cancelacion',
        'usuario_cancela_id',
        'fecha_cancelacion',
        'observaciones',
    ];

    protected function casts(): array
    {
        return [
            'fecha_pedido' => 'date',
            'fecha_entrega' => 'date',
            'fecha_cancelacion' => 'datetime',
            'subtotal' => 'decimal:2',
            'descuento_total' => 'decimal:2',
            'total' => 'decimal:2',
        ];
    }

    public function cliente()
    {
        return $this->belongsTo(Cliente::class);
    }

    public function almacen()
    {
        return $this->belongsTo(Almacen::class);
    }

    public function vendedor()
    {
        return $this->belongsTo(User::class, 'vendedor_id');
    }

    public function usuarioCancela()
    {
        return $this->belongsTo(User::class, 'usuario_cancela_id');
    }

    public function notaVenta()
    {
        return $this->belongsTo(NotaVenta::class);
    }

    public function detalles()
    {
        return $this->hasMany(PedidoDetalle::class);
    }
}
