<?php

namespace Database\Seeders;

use App\Models\MotivoMovimiento;
use Illuminate\Database\Seeder;

class MotivosMovimientoSeeder extends Seeder
{
    /**
     * Motivos base del sistema. Idempotente: se puede correr varias veces.
     * es_sistema = true  → los usa el sistema, no se pueden eliminar desde la UI.
     * es_sistema = false → manuales / de ajuste (editables y borrables).
     * ambito: 'inventario' (movimientos de stock) o 'caja' (ingresos/egresos de tesorería).
     */
    public function run(): void
    {
        // [nombre, tipo, es_sistema, ambito]
        $motivos = [
            // ── Entradas (ingresos) ──
            ['Recepción', 'entrada', true, 'inventario'],
            ['Compra', 'entrada', true, 'inventario'],
            ['Devolución de cliente', 'entrada', false, 'inventario'],
            ['Ajuste positivo', 'entrada', false, 'inventario'],
            ['Carga inicial', 'entrada', false, 'inventario'],

            // ── Salidas ──
            ['Salida por venta', 'salida', true, 'inventario'],
            ['Merma / pérdida', 'salida', false, 'inventario'],
            ['Consumo interno', 'salida', false, 'inventario'],
            ['Ajuste negativo', 'salida', false, 'inventario'],
            ['Devolución a proveedor', 'salida', false, 'inventario'],

            // ── Tesorería / Caja (entradas) ──
            ['Ingreso por venta', 'entrada', true, 'caja'],
            ['Ingreso por cobranza', 'entrada', true, 'caja'],
            ['Ingreso por préstamo', 'entrada', false, 'caja'],
            ['Otro ingreso', 'entrada', false, 'caja'],

            // ── Tesorería / Caja (salidas) ──
            ['Salida por pago de compra', 'salida', true, 'caja'],
            ['Salida por pago a proveedor', 'salida', true, 'caja'],
            ['Salida por gasto', 'salida', false, 'caja'],
            ['Salida por sueldo', 'salida', false, 'caja'],
            ['Otro egreso', 'salida', false, 'caja'],
        ];

        foreach ($motivos as [$nombre, $tipo, $sistema, $ambito]) {
            MotivoMovimiento::updateOrCreate(
                ['nombre' => $nombre, 'tipo' => $tipo, 'ambito' => $ambito],
                ['es_sistema' => $sistema, 'activo' => true],
            );
        }
    }
}
