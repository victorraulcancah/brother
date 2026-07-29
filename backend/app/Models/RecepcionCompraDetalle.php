<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RecepcionCompraDetalle extends Model
{
    protected $table = 'recepcion_compra_detalles';

    protected $fillable = [
        'recepcion_id',
        'orden_compra_detalle_id',
        'producto_presentacion_id',
        'cantidad_ordenada',
        'cantidad_recibida',
        'cantidad_conforme',
        'cantidad_rechazada',
        'costo_unitario',
        'lote',
        'fecha_vencimiento',
    ];

    protected function casts(): array
    {
        return [
            'cantidad_ordenada' => 'decimal:2',
            'cantidad_recibida' => 'decimal:2',
            'cantidad_conforme' => 'decimal:2',
            'cantidad_rechazada' => 'decimal:2',
            'costo_unitario' => 'decimal:2',
            'fecha_vencimiento' => 'datetime',
        ];
    }

    public function recepcion() { return $this->belongsTo(RecepcionCompra::class); }
    public function presentacion() { return $this->belongsTo(ProductoPresentacion::class, 'producto_presentacion_id'); }
}
