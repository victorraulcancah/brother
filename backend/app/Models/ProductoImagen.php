<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductoImagen extends Model
{
    protected $table = 'producto_imagenes';

    protected $fillable = [
        'producto_id',
        'url',
        'orden',
        'es_principal',
    ];

    protected function casts(): array
    {
        return [
            'orden' => 'integer',
            'es_principal' => 'boolean',
        ];
    }

    public function producto()
    {
        return $this->belongsTo(Producto::class);
    }
}
