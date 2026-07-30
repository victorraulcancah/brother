<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AjusteDetalle extends Model
{
    protected $table = 'ajuste_detalles';

    protected $fillable = [
        'ajuste_id',
        'producto_id',
        'producto_variante_id',
        'cantidad_sistema',
        'cantidad_fisica',
        'diferencia',
    ];

    protected function casts(): array
    {
        return [
            'cantidad_sistema' => 'decimal:2',
            'cantidad_fisica' => 'decimal:2',
            'diferencia' => 'decimal:2',
        ];
    }

    public function ajuste() { return $this->belongsTo(AjusteInventario::class, 'ajuste_id'); }
    public function producto() { return $this->belongsTo(Producto::class, 'producto_id'); }
    public function variante() { return $this->belongsTo(ProductoVariante::class, 'producto_variante_id'); }
}
