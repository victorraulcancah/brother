<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Producto extends Model
{
    protected $table = 'productos';

    protected $fillable = [
        'codigo',
        'codigo_barras',
        'nombre',
        'descripcion_ticket',
        'marca_id',
        'sub_marca_id',
        'categoria_id',
        'sub_categoria_id',
        'unidad_medida_id',
        'unidad_compra_id',
        'unidad_base_id',
        'factor_compra_base',
        'descripcion',
        'imagen',
        'ficha_tecnica',
        'accion_tecnica',
        'precio_base',
        'stock_minimo',
        'stock_maximo',
        'activo',
    ];

    protected function casts(): array
    {
        return [
            'precio_base' => 'decimal:2',
            'factor_compra_base' => 'decimal:2',
            'stock_minimo' => 'decimal:2',
            'stock_maximo' => 'decimal:2',
            'activo' => 'boolean',
        ];
    }

    public function marca() { return $this->belongsTo(Marca::class); }
    public function subMarca() { return $this->belongsTo(SubMarca::class); }
    public function categoria() { return $this->belongsTo(Categoria::class); }
    public function subCategoria() { return $this->belongsTo(Categoria::class, 'sub_categoria_id'); }
    public function unidadMedida() { return $this->belongsTo(UnidadMedida::class); }
    public function unidadCompra() { return $this->belongsTo(UnidadMedida::class, 'unidad_compra_id'); }
    public function unidadBase() { return $this->belongsTo(UnidadMedida::class, 'unidad_base_id'); }

    public function presentaciones() { return $this->hasMany(ProductoPresentacion::class); }
    public function lotes() { return $this->hasMany(ProductoLote::class); }
    public function stocks() { return $this->hasMany(ProductoAlmacenStock::class); }
    public function movimientos() { return $this->hasMany(MovimientoInventario::class); }
}
