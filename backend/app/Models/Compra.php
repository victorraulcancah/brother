<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Compra extends Model
{
    protected $table = 'compras';

    protected $fillable = [
        'correlativo',
        'proveedor_id',
        'orden_compra_id',
        'tipo_documento',
        'serie',
        'numero',
        'guia',
        'fecha',
        'forma_pago',
        'dias_credito',
        'fecha_vencimiento',
        'flete',
        'subtotal',
        'total',
        'estado',
        'observaciones',
        'usuario_id',
    ];

    protected $appends = ['numero_compra'];

    protected function casts(): array
    {
        return [
            'correlativo' => 'integer',
            'fecha' => 'date',
            'fecha_vencimiento' => 'date',
            'flete' => 'decimal:2',
            'subtotal' => 'decimal:2',
            'total' => 'decimal:2',
        ];
    }

    /** Número interno propio de la compra, ej. "000001". */
    public function getNumeroCompraAttribute(): ?string
    {
        return $this->correlativo ? str_pad((string) $this->correlativo, 6, '0', STR_PAD_LEFT) : null;
    }

    public function proveedor()
    {
        return $this->belongsTo(Proveedor::class);
    }

    public function ordenCompra()
    {
        return $this->belongsTo(OrdenCompra::class);
    }

    public function usuario()
    {
        return $this->belongsTo(User::class, 'usuario_id');
    }

    public function detalles()
    {
        return $this->hasMany(CompraDetalle::class);
    }

    public function pagos()
    {
        return $this->hasMany(CompraPago::class);
    }
}
