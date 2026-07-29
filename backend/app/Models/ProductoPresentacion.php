<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductoPresentacion extends Model
{
    protected $table = 'producto_presentaciones';

    protected $fillable = [
        'producto_id',
        'nombre',
        'codigo_barras',
        'precio_venta',
        'factor_conversion',
        'es_compra',
        'es_venta',
        'unidad_base_id',
        'activo',
    ];

    protected function casts(): array
    {
        return [
            'precio_venta' => 'decimal:2',
            'factor_conversion' => 'decimal:2',
            'es_compra' => 'boolean',
            'es_venta' => 'boolean',
            'activo' => 'boolean',
        ];
    }

    public function producto() { return $this->belongsTo(Producto::class); }
    public function unidadBase() { return $this->belongsTo(UnidadMedida::class, 'unidad_base_id'); }
    public function stocks() { return $this->hasMany(ProductoAlmacenStock::class); }
    public function movimientos() { return $this->hasMany(MovimientoInventario::class); }
}
