<?php

namespace Database\Seeders;

use App\Models\MetodoPago;
use Illuminate\Database\Seeder;

class MetodosPagoSeeder extends Seeder
{
    public function run(): void
    {
        $metodos = [
            ['nombre' => 'Efectivo', 'tipo' => 'efectivo', 'es_sistema' => true],
            ['nombre' => 'Transferencia', 'tipo' => 'banco', 'es_sistema' => false, 'requiere_cuenta_bancaria' => true, 'requiere_numero_operacion' => true],
            ['nombre' => 'Yape', 'tipo' => 'billetera', 'es_sistema' => false, 'requiere_numero_operacion' => true],
            ['nombre' => 'Plin', 'tipo' => 'billetera', 'es_sistema' => false, 'requiere_numero_operacion' => true],
            ['nombre' => 'Tarjeta Débito', 'tipo' => 'tarjeta', 'es_sistema' => false, 'requiere_tarjeta' => true],
            ['nombre' => 'Tarjeta Crédito', 'tipo' => 'tarjeta', 'es_sistema' => false, 'requiere_tarjeta' => true],
        ];

        foreach ($metodos as $m) {
            MetodoPago::updateOrCreate(
                ['nombre' => $m['nombre']],
                array_merge($m, ['activo' => true])
            );
        }
    }
}
