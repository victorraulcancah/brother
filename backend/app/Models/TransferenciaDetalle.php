<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TransferenciaDetalle extends Model
{
    protected $table = 'transferencia_detalles';

    protected $fillable = [
        'transferencia_id',
        'producto_id',
        'producto_variante_id',
        'cantidad_enviada',
        'cantidad_recibida',
    ];

    protected function casts(): array
    {
        return [
            'cantidad_enviada' => 'decimal:2',
            'cantidad_recibida' => 'decimal:2',
        ];
    }

    public function transferencia()
    {
        return $this->belongsTo(Transferencia::class);
    }

    public function producto()
    {
        return $this->belongsTo(Producto::class);
    }

    public function productoVariante()
    {
        return $this->belongsTo(ProductoVariante::class);
    }
}
