<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductoAlmacenStock extends Model
{
    protected $table = 'producto_almacen_stock';

    protected $fillable = [
        'producto_id',
        'producto_variante_id',
        'almacen_id',
        'stock_actual',
        'stock_reservado',
        'stock_disponible',
        'stock_minimo',
        'stock_maximo',
        'ubicacion',
    ];

    protected function casts(): array
    {
        return [
            'stock_actual' => 'integer',
            'stock_reservado' => 'integer',
            'stock_disponible' => 'integer',
            'stock_minimo' => 'integer',
            'stock_maximo' => 'integer',
        ];
    }

    public function producto()
    {
        return $this->belongsTo(Producto::class);
    }

    public function productoVariante()
    {
        return $this->belongsTo(ProductoVariante::class);
    }

    public function almacen()
    {
        return $this->belongsTo(Almacen::class);
    }
}
