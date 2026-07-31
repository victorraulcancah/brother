<?php
namespace App\Services;

use App\Models\Almacen;
use App\Models\MovimientoInventario;
use App\Models\ProductoAlmacenStock;
use App\Models\ProductoPresentacion;
use Illuminate\Support\Facades\DB;

class StockService
{
    /**
     * Registra una entrada de stock.
     * $cantidad = cantidad en unidades de la PRESENTACIÓN (ej: 10 cajas).
     * El sistema convierte automáticamente a unidad base usando factor_conversion.
     */
    public function entrada(
        ProductoPresentacion $presentacion,
        Almacen $almacen,
        float $cantidadPresentacion,
        float $costoUnitario,
        string $origen,
        ?string $documentoTipo = null,
        ?int $documentoId = null,
        ?int $usuarioId = null,
        ?string $fecha = null
    ): MovimientoInventario {
        return DB::transaction(function () use ($presentacion, $almacen, $cantidadPresentacion, $costoUnitario, $origen, $documentoTipo, $documentoId, $usuarioId, $fecha) {
            $factor = (float) $presentacion->factor_conversion ?: 1;
            $cantidadBase = $cantidadPresentacion * $factor;

            $stock = $this->getOrCreateStock($presentacion, $almacen);
            $anterior = (float) $stock->stock_actual;
            $stock->stock_anterior = $anterior;
            $stock->stock_actual = $anterior + $cantidadBase;
            $stock->stock_disponible = $stock->stock_actual - $stock->stock_reservado;
            $stock->save();

            return $this->registrarMovimiento(
                $presentacion, $almacen, 'entrada', $origen,
                $cantidadPresentacion, $cantidadBase, $costoUnitario, $anterior, $stock->stock_actual,
                $documentoTipo, $documentoId, $usuarioId, $fecha
            );
        });
    }

    /**
     * Registra una salida de stock.
     * $cantidad = cantidad en unidades de la PRESENTACIÓN (ej: 2 botellas).
     */
    public function salida(
        ProductoPresentacion $presentacion,
        Almacen $almacen,
        float $cantidadPresentacion,
        float $costoUnitario,
        string $origen,
        ?string $documentoTipo = null,
        ?int $documentoId = null,
        ?int $usuarioId = null,
        ?string $fecha = null
    ): MovimientoInventario {
        return DB::transaction(function () use ($presentacion, $almacen, $cantidadPresentacion, $costoUnitario, $origen, $documentoTipo, $documentoId, $usuarioId, $fecha) {
            $factor = (float) $presentacion->factor_conversion ?: 1;
            $cantidadBase = $cantidadPresentacion * $factor;

            $stock = $this->getOrCreateStock($presentacion, $almacen);
            $anterior = (float) $stock->stock_actual;

            if ($cantidadBase > $anterior) {
                throw new \RuntimeException(
                    "Stock insuficiente para \"{$presentacion->nombre}\" en \"{$almacen->nombre}\". Disponible: {$anterior}."
                );
            }

            $stock->stock_anterior = $anterior;
            $stock->stock_actual = $anterior - $cantidadBase;
            $stock->stock_disponible = $stock->stock_actual - $stock->stock_reservado;
            $stock->save();

            return $this->registrarMovimiento(
                $presentacion, $almacen, 'salida', $origen,
                -$cantidadPresentacion, -$cantidadBase, $costoUnitario, $anterior, $stock->stock_actual,
                $documentoTipo, $documentoId, $usuarioId, $fecha
            );
        });
    }

    public function transferir(
        ProductoPresentacion $presentacion,
        Almacen $almacenOrigen,
        Almacen $almacenDestino,
        float $cantidadPresentacion,
        float $costoUnitario,
        ?int $usuarioId = null
    ): array {
        return DB::transaction(function () use ($presentacion, $almacenOrigen, $almacenDestino, $cantidadPresentacion, $costoUnitario, $usuarioId) {
            $salida = $this->salida(
                $presentacion, $almacenOrigen, $cantidadPresentacion, $costoUnitario,
                'transferencia', 'transferencia', null, $usuarioId
            );
            $entrada = $this->entrada(
                $presentacion, $almacenDestino, $cantidadPresentacion, $costoUnitario,
                'transferencia', 'transferencia', null, $usuarioId
            );
            return [$salida, $entrada];
        });
    }

    public function reservar(ProductoPresentacion $presentacion, Almacen $almacen, float $cantidadPresentacion): void
    {
        DB::transaction(function () use ($presentacion, $almacen, $cantidadPresentacion) {
            $factor = (float) $presentacion->factor_conversion ?: 1;
            $cantidadBase = $cantidadPresentacion * $factor;

            $stock = $this->getOrCreateStock($presentacion, $almacen);
            $stock->stock_reservado += $cantidadBase;
            $stock->stock_disponible = $stock->stock_actual - $stock->stock_reservado;
            $stock->save();
        });
    }

    public function liberarReserva(ProductoPresentacion $presentacion, Almacen $almacen, float $cantidadPresentacion): void
    {
        DB::transaction(function () use ($presentacion, $almacen, $cantidadPresentacion) {
            $factor = (float) $presentacion->factor_conversion ?: 1;
            $cantidadBase = $cantidadPresentacion * $factor;

            $stock = $this->getOrCreateStock($presentacion, $almacen);
            $stock->stock_reservado -= $cantidadBase;
            $stock->stock_disponible = $stock->stock_actual - $stock->stock_reservado;
            $stock->save();
        });
    }

    /**
     * Debe llamarse dentro de una transacción activa: bloquea la fila
     * (o la crea si no existe) para evitar carreras entre movimientos concurrentes.
     */
    private function getOrCreateStock(ProductoPresentacion $presentacion, Almacen $almacen): ProductoAlmacenStock
    {
        $stock = ProductoAlmacenStock::where('producto_id', $presentacion->producto_id)
            ->where('almacen_id', $almacen->id)
            ->lockForUpdate()
            ->first();

        return $stock ?? ProductoAlmacenStock::create([
            'producto_id' => $presentacion->producto_id,
            'almacen_id' => $almacen->id,
            'stock_actual' => 0,
            'stock_reservado' => 0,
            'stock_disponible' => 0,
            'stock_minimo' => 0,
            'stock_maximo' => 0,
        ]);
    }

    private function registrarMovimiento(
        ProductoPresentacion $presentacion,
        Almacen $almacen,
        string $tipoMovimiento,
        string $origen,
        float $cantidadPresentacion,
        float $cantidadBase,
        float $costoUnitario,
        float $stockAnterior,
        float $saldoStock,
        ?string $documentoTipo = null,
        ?int $documentoId = null,
        ?int $usuarioId = null,
        ?string $fecha = null
    ): MovimientoInventario {
        return MovimientoInventario::create([
            'producto_id' => $presentacion->producto_id,
            'almacen_id' => $almacen->id,
            'tipo_movimiento' => $tipoMovimiento,
            'origen' => $origen,
            'documento_referencia_tipo' => $documentoTipo,
            'documento_referencia_id' => $documentoId,
            'cantidad' => $cantidadBase,
            'stock_anterior' => $stockAnterior,
            'costo_unitario' => $costoUnitario,
            'saldo_stock' => $saldoStock,
            'fecha' => $fecha ?? now(),
            'usuario_id' => $usuarioId,
        ]);
    }
}
