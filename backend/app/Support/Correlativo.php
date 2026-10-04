<?php

namespace App\Support;

/**
 * Formato único del número de los documentos (ventas, pedidos, compras, órdenes,
 * traslados, ajustes, préstamos, recepciones): como mínimo dos dígitos, sin
 * ceros de relleno de más. NV01-01, C001-07, OC0001-19, NV01-123.
 */
class Correlativo
{
    public static function pad(int|string $numero): string
    {
        return str_pad((string) (int) $numero, 2, '0', STR_PAD_LEFT);
    }

    /** Acorta un código ya armado ("OC0001-00000019" → "OC0001-19"). Lo que no encaja, queda igual. */
    public static function acortarCodigo(string $codigo): string
    {
        return preg_replace_callback(
            '/^(.+-)(\d+)$/',
            fn (array $m) => $m[1] . self::pad($m[2]),
            $codigo,
        ) ?? $codigo;
    }
}
