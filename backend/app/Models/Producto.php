<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Producto extends Model
{
    protected $table = 'productos';

    protected $fillable = [
        'codigo',
        'nombre',
        'marca_id',
        'sub_marca_id',
        'categoria_id',
        'unidad_medida_id',
        'descripcion',
        'precio_base',
        'afecto_igv',
        'activo',
    ];

    protected function casts(): array
    {
        return [
            'precio_base' => 'decimal:2',
            'afecto_igv' => 'boolean',
            'activo' => 'boolean',
        ];
    }

    public function marca()
    {
        return $this->belongsTo(Marca::class);
    }

    public function subMarca()
    {
        return $this->belongsTo(SubMarca::class);
    }

    public function categoria()
    {
        return $this->belongsTo(Categoria::class);
    }

    public function unidadMedida()
    {
        return $this->belongsTo(UnidadMedida::class);
    }

    public function variantes()
    {
        return $this->hasMany(ProductoVariante::class);
    }

    public function imagenes()
    {
        return $this->hasMany(ProductoImagen::class);
    }

    public function stocks()
    {
        return $this->hasMany(ProductoAlmacenStock::class);
    }

    public function movimientos()
    {
        return $this->hasMany(MovimientoInventario::class);
    }
}
