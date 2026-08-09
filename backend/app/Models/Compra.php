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

    /** Serie del correlativo interno (no es la serie del documento del proveedor). */
    public const SERIE_INTERNA = 'C001';

    /** Número interno propio de la compra, ej. "C001-00000001". */
    public function getNumeroCompraAttribute(): ?string
    {
        return $this->correlativo
            ? self::SERIE_INTERNA . '-' . str_pad((string) $this->correlativo, 8, '0', STR_PAD_LEFT)
            : null;
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
