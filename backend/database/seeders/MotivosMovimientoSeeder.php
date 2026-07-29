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
     */
    public function run(): void
    {
        // [nombre, tipo, es_sistema]
        $motivos = [
            // ── Entradas (ingresos) ──
            ['Recepción', 'entrada', true],
            ['Compra', 'entrada', true],
            ['Devolución de cliente', 'entrada', false],
            ['Ajuste positivo', 'entrada', false],
            ['Carga inicial', 'entrada', false],

            // ── Salidas ──
            ['Salida por venta', 'salida', true],
            ['Merma / pérdida', 'salida', false],
            ['Consumo interno', 'salida', false],
            ['Ajuste negativo', 'salida', false],
            ['Devolución a proveedor', 'salida', false],
        ];

        foreach ($motivos as [$nombre, $tipo, $sistema]) {
            MotivoMovimiento::updateOrCreate(
                ['nombre' => $nombre, 'tipo' => $tipo],
                ['es_sistema' => $sistema, 'activo' => true],
            );
        }
    }
}
