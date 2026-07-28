<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DevolucionProveedorDetalle extends Model
{
    protected $table = 'devolucion_proveedor_detalles';

    protected $fillable = [
        'devolucion_id',
        'producto_id',
        'producto_variante_id',
        'cantidad',
        'costo_unitario',
    ];

    protected function casts(): array
    {
        return [
            'cantidad' => 'decimal:2',
            'costo_unitario' => 'decimal:2',
        ];
    }

    public function devolucion()
    {
        return $this->belongsTo(DevolucionProveedor::class);
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
