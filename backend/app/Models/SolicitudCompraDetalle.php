<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SolicitudCompraDetalle extends Model
{
    protected $table = 'solicitud_compra_detalles';

    protected $fillable = [
        'solicitud_id',
        'producto_id',
        'producto_variante_id',
        'cantidad_solicitada',
        'cantidad_aprobada',
        'observaciones',
    ];

    protected function casts(): array
    {
        return [
            'cantidad_solicitada' => 'decimal:2',
            'cantidad_aprobada' => 'decimal:2',
        ];
    }

    public function solicitud()
    {
        return $this->belongsTo(SolicitudCompra::class, 'solicitud_id');
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
