<?php

namespace Tests\Unit;

use App\Support\Correlativo;
use PHPUnit\Framework\TestCase;

class CorrelativoTest extends TestCase
{
    public function test_como_minimo_dos_digitos_y_sin_ceros_de_mas(): void
    {
        $this->assertSame('01', Correlativo::pad(1));
        $this->assertSame('07', Correlativo::pad('00000007'));
        $this->assertSame('10', Correlativo::pad('010'));
        $this->assertSame('123', Correlativo::pad(123));
    }

    public function test_acorta_codigos_ya_armados(): void
    {
        $this->assertSame('OC0001-19', Correlativo::acortarCodigo('OC0001-00000019'));
        $this->assertSame('C001-07', Correlativo::acortarCodigo('C001-00000007'));
        $this->assertSame('NV01-05', Correlativo::acortarCodigo('NV01-005'));
        $this->assertSame('SIN-GUION-X', Correlativo::acortarCodigo('SIN-GUION-X'));
    }
}
