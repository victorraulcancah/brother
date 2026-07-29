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
        'unidad_compra_id',
        'unidad_base_id',
        'factor_compra_base',
        'descripcion',
        'imagen',
        'precio_base',
        'afecto_igv',
        'activo',
    ];

    protected function casts(): array
    {
        return [
            'precio_base' => 'decimal:2',
            'factor_compra_base' => 'decimal:2',
            'afecto_igv' => 'boolean',
            'activo' => 'boolean',
        ];
    }

    public function marca() { return $this->belongsTo(Marca::class); }
    public function subMarca() { return $this->belongsTo(SubMarca::class); }
    public function categoria() { return $this->belongsTo(Categoria::class); }
    public function unidadMedida() { return $this->belongsTo(UnidadMedida::class); }
    public function unidadCompra() { return $this->belongsTo(UnidadMedida::class, 'unidad_compra_id'); }
    public function unidadBase() { return $this->belongsTo(UnidadMedida::class, 'unidad_base_id'); }

    public function presentaciones() { return $this->hasMany(ProductoPresentacion::class); }
    public function stocks() { return $this->hasManyThrough(ProductoAlmacenStock::class, ProductoPresentacion::class); }
    public function movimientos() { return $this->hasManyThrough(MovimientoInventario::class, ProductoPresentacion::class); }
}
