<?php

use App\Support\Correlativo;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Los números de documento se guardaban con relleno largo ("C001-00000007",
 * "NV01-005"). Se acortan a dos dígitos como mínimo ("C001-07", "NV01-05").
 *
 * Solo cambia el texto del número: la serie, el contador y el orden no se tocan, y
 * como "007" y "7" son el mismo número, dos documentos nunca chocan entre sí.
 * No es reversible: no se puede saber con cuántos ceros se guardó cada uno.
 */
return new class extends Migration
{
    /** Tablas con serie + número propios (columna `numero`). */
    private const TABLAS_CON_NUMERO = [
        'notas_venta',
        'pedidos',
        'ajustes_inventario',
        'prestamos',
        'recepciones_compra',
        'transferencias',
    ];

    public function up(): void
    {
        foreach (self::TABLAS_CON_NUMERO as $tabla) {
            DB::table($tabla)->select('id', 'numero')->orderBy('id')->chunkById(500, function ($filas) use ($tabla) {
                foreach ($filas as $fila) {
                    if ($fila->numero === null || ! ctype_digit((string) $fila->numero)) {
                        continue;
                    }
                    $nuevo = Correlativo::pad($fila->numero);
                    if ($nuevo !== (string) $fila->numero) {
                        DB::table($tabla)->where('id', $fila->id)->update(['numero' => $nuevo]);
                    }
                }
            });
        }

        // Las órdenes de compra guardan el código completo ("OC0001-00000019").
        DB::table('ordenes_compra')->select('id', 'codigo')->orderBy('id')->chunkById(500, function ($filas) {
            foreach ($filas as $fila) {
                $nuevo = Correlativo::acortarCodigo((string) $fila->codigo);
                if ($nuevo !== $fila->codigo) {
                    DB::table('ordenes_compra')->where('id', $fila->id)->update(['codigo' => $nuevo]);
                }
            }
        });
    }

    public function down(): void
    {
        // Irreversible a propósito: ver el comentario de la clase.
    }
};
