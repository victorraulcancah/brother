<?php

namespace App\Services;

use App\Models\Almacen;
use App\Models\MovimientoInventario;
use App\Models\Producto;
use App\Models\ProductoAlmacenStock;
use App\Models\ProductoVariante;
use Illuminate\Support\Facades\DB;

class StockService
{
    public function entrada(
        Producto|ProductoVariante $item,
        Almacen $almacen,
        float $cantidad,
        float $costoUnitario,
        string $origen,
        ?string $documentoTipo = null,
        ?int $documentoId = null,
        ?int $usuarioId = null,
        ?string $fecha = null
    ): MovimientoInventario {
        return DB::transaction(function () use ($item, $almacen, $cantidad, $costoUnitario, $origen, $documentoTipo, $documentoId, $usuarioId, $fecha) {
            $stock = $this->getOrCreateStock($item, $almacen);
            $stock->stock_actual += $cantidad;
            $stock->stock_disponible = $stock->stock_actual - $stock->stock_reservado;
            $stock->save();

            return $this->registrarMovimiento(
                $item, $almacen, 'entrada', $origen,
                $cantidad, $costoUnitario, $stock->stock_actual,
                $documentoTipo, $documentoId, $usuarioId, $fecha
            );
        });
    }

    public function salida(
        Producto|ProductoVariante $item,
        Almacen $almacen,
        float $cantidad,
        float $costoUnitario,
        string $origen,
        ?string $documentoTipo = null,
        ?int $documentoId = null,
        ?int $usuarioId = null,
        ?string $fecha = null
    ): MovimientoInventario {
        return DB::transaction(function () use ($item, $almacen, $cantidad, $costoUnitario, $origen, $documentoTipo, $documentoId, $usuarioId, $fecha) {
            $stock = $this->getOrCreateStock($item, $almacen);
            $stock->stock_actual -= $cantidad;
            $stock->stock_disponible = $stock->stock_actual - $stock->stock_reservado;
            $stock->save();

            return $this->registrarMovimiento(
                $item, $almacen, 'salida', $origen,
                -$cantidad, $costoUnitario, $stock->stock_actual,
                $documentoTipo, $documentoId, $usuarioId, $fecha
            );
        });
    }

    public function transferir(
        Producto|ProductoVariante $item,
        Almacen $almacenOrigen,
        Almacen $almacenDestino,
        float $cantidad,
        float $costoUnitario,
        ?int $usuarioId = null
    ): array {
        return DB::transaction(function () use ($item, $almacenOrigen, $almacenDestino, $cantidad, $costoUnitario, $usuarioId) {
            $salida = $this->salida(
                $item, $almacenOrigen, $cantidad, $costoUnitario,
                'transferencia', 'transferencia', null, $usuarioId
            );
            $entrada = $this->entrada(
                $item, $almacenDestino, $cantidad, $costoUnitario,
                'transferencia', 'transferencia', null, $usuarioId
            );
            return [$salida, $entrada];
        });
    }

    public function reservar(Producto|ProductoVariante $item, Almacen $almacen, float $cantidad): void
    {
        DB::transaction(function () use ($item, $almacen, $cantidad) {
            $stock = $this->getOrCreateStock($item, $almacen);
            $stock->stock_reservado += $cantidad;
            $stock->stock_disponible = $stock->stock_actual - $stock->stock_reservado;
            $stock->save();
        });
    }

    public function liberarReserva(Producto|ProductoVariante $item, Almacen $almacen, float $cantidad): void
    {
        DB::transaction(function () use ($item, $almacen, $cantidad) {
            $stock = $this->getOrCreateStock($item, $almacen);
            $stock->stock_reservado -= $cantidad;
            $stock->stock_disponible = $stock->stock_actual - $stock->stock_reservado;
            $stock->save();
        });
    }

    private function getOrCreateStock(Producto|ProductoVariante $item, Almacen $almacen): ProductoAlmacenStock
    {
        $data = [
            'almacen_id' => $almacen->id,
        ];

        if ($item instanceof Producto) {
            $data['producto_id'] = $item->id;
        } else {
            $data['producto_variante_id'] = $item->id;
        }

        return ProductoAlmacenStock::firstOrCreate(
            $data,
            array_merge($data, [
                'stock_actual' => 0,
                'stock_reservado' => 0,
                'stock_disponible' => 0,
                'stock_minimo' => 0,
                'stock_maximo' => 0,
            ])
        );
    }

    private function registrarMovimiento(
        Producto|ProductoVariante $item,
        Almacen $almacen,
        string $tipoMovimiento,
        string $origen,
        float $cantidad,
        float $costoUnitario,
        float $saldoStock,
        ?string $documentoTipo = null,
        ?int $documentoId = null,
        ?int $usuarioId = null,
        ?string $fecha = null
    ): MovimientoInventario {
        $data = [
            'almacen_id' => $almacen->id,
            'tipo_movimiento' => $tipoMovimiento,
            'origen' => $origen,
            'documento_referencia_tipo' => $documentoTipo,
            'documento_referencia_id' => $documentoId,
            'cantidad' => $cantidad,
            'costo_unitario' => $costoUnitario,
            'saldo_stock' => $saldoStock,
            'fecha' => $fecha ?? now(),
            'usuario_id' => $usuarioId,
        ];

        if ($item instanceof Producto) {
            $data['producto_id'] = $item->id;
        } else {
            $data['producto_variante_id'] = $item->id;
        }

        return MovimientoInventario::create($data);
    }
}
