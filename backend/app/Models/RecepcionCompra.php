<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RecepcionCompra extends Model
{
    protected $table = 'recepciones_compra';

    protected $fillable = [
        'orden_compra_id',
        'proveedor_id',
        'almacen_id',
        'serie',
        'numero',
        'numero_documento',
        'tipo_documento',
        'fecha_recepcion',
        'estado',
        'stock_aplicado',
        'usuario_recibe_id',
        'observaciones',
    ];

    protected $appends = ['documento'];

    protected function casts(): array
    {
        return [
            'fecha_recepcion' => 'datetime',
            'stock_aplicado' => 'boolean',
        ];
    }

    /** Número formal del documento de recepción, ej. "RA0001-00000019". */
    public function getDocumentoAttribute(): ?string
    {
        if (! $this->serie || ! $this->numero) {
            return null;
        }

        return "{$this->serie}-{$this->numero}";
    }

    public function ordenCompra()
    {
        return $this->belongsTo(OrdenCompra::class);
    }

    public function proveedor()
    {
        return $this->belongsTo(Proveedor::class);
    }

    public function almacen()
    {
        return $this->belongsTo(Almacen::class);
    }

    public function usuarioRecibe()
    {
        return $this->belongsTo(User::class, 'usuario_recibe_id');
    }

    public function detalles()
    {
        return $this->hasMany(RecepcionCompraDetalle::class, 'recepcion_id');
    }

    public function devoluciones()
    {
        return $this->hasMany(DevolucionProveedor::class);
    }
}
