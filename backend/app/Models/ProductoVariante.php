<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductoVariante extends Model
{
    protected $table = 'producto_variantes';

    protected $fillable = [
        'producto_id',
        'sku_variante',
        'precio_diferencial',
        'stock',
        'activo',
    ];

    protected function casts(): array
    {
        return [
            'precio_diferencial' => 'decimal:2',
            'stock' => 'integer',
            'activo' => 'boolean',
        ];
    }

    public function producto()
    {
        return $this->belongsTo(Producto::class);
    }

    public function atributoValores()
    {
        return $this->belongsToMany(AtributoValor::class, 'producto_variante_atributo_valor');
    }
}
