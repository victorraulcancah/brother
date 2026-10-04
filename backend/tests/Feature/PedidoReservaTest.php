<?php

namespace Tests\Feature;

use App\Models\Almacen;
use App\Models\Marca;
use App\Models\Producto;
use App\Models\ProductoAlmacenStock;
use App\Models\ProductoPresentacion;
use App\Models\UnidadMedida;
use App\Models\User;
use App\Services\PedidoService;
use App\Services\StockService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PedidoReservaTest extends TestCase
{
    use RefreshDatabase;

    private Almacen $almacen;
    private ProductoPresentacion $presentacion;
    private User $vendedor;

    protected function setUp(): void
    {
        parent::setUp();

        $this->vendedor = User::factory()->create();
        $this->actingAs($this->vendedor, 'api');

        $this->almacen = Almacen::create(['nombre' => 'Principal', 'codigo' => 'ALM1', 'activo' => true]);

        $unidad = UnidadMedida::create(['nombre' => 'Unidad', 'abreviatura' => 'u', 'factor_base' => 1]);
        $marca = Marca::create(['nombre' => 'Marca']);
        $producto = Producto::create([
            'codigo' => 'P1', 'nombre' => 'Arroz', 'precio_base' => 4, 'activo' => true,
            'marca_id' => $marca->id, 'unidad_medida_id' => $unidad->id, 'unidad_base_id' => $unidad->id,
        ]);
        $this->presentacion = ProductoPresentacion::create([
            'producto_id' => $producto->id,
            'nombre' => 'Unidad',
            'precio_venta' => 5,
            'factor_conversion' => 1,
            'activo' => true,
        ]);

        // 10 unidades físicas en el almacén.
        app(StockService::class)->entrada($this->presentacion, $this->almacen, 10, 3, 'compra');
    }

    private function datos(float $cantidad): array
    {
        return [
            'almacen_id' => $this->almacen->id,
            'vendedor_id' => $this->vendedor->id,
            'fecha_pedido' => now()->toDateString(),
            'subtotal' => $cantidad * 5,
            'total' => $cantidad * 5,
            'detalles' => [[
                'producto_presentacion_id' => $this->presentacion->id,
                'cantidad' => $cantidad,
                'precio_unitario' => 5,
                'subtotal' => $cantidad * 5,
            ]],
        ];
    }

    private function stock(): ProductoAlmacenStock
    {
        return ProductoAlmacenStock::where('almacen_id', $this->almacen->id)->firstOrFail();
    }

    public function test_crear_pedido_reserva_sin_descontar_stock_fisico(): void
    {
        $pedido = app(PedidoService::class)->crear($this->datos(4));

        $this->assertSame('pendiente', $pedido->estado);
        $this->assertSame('PE01-001', $pedido->serie . '-' . $pedido->numero);
        $this->assertEquals(10, $this->stock()->stock_actual);
        $this->assertEquals(4, $this->stock()->stock_reservado);
        $this->assertEquals(6, $this->stock()->stock_disponible);
    }

    public function test_no_se_puede_reservar_mas_de_lo_disponible(): void
    {
        app(PedidoService::class)->crear($this->datos(8));

        $this->expectException(\RuntimeException::class);
        app(PedidoService::class)->crear($this->datos(3));
    }

    public function test_pedido_fallido_no_deja_reservas_a_medias(): void
    {
        try {
            app(PedidoService::class)->crear($this->datos(11));
        } catch (\RuntimeException) {
        }

        $this->assertEquals(0, $this->stock()->stock_reservado);
        $this->assertDatabaseCount('pedidos', 0);
    }

    public function test_cancelar_libera_la_reserva(): void
    {
        $service = app(PedidoService::class);
        $pedido = $service->crear($this->datos(4));

        $service->cancelar($pedido, 'Cliente desistió');

        $this->assertSame('cancelado', $pedido->fresh()->estado);
        $this->assertEquals(0, $this->stock()->stock_reservado);
        $this->assertEquals(10, $this->stock()->stock_disponible);
    }

    public function test_editar_reajusta_la_reserva(): void
    {
        $service = app(PedidoService::class);
        $pedido = $service->crear($this->datos(4));

        $service->actualizar($pedido, $this->datos(7));

        $this->assertEquals(7, $this->stock()->stock_reservado);
        $this->assertEquals(3, $this->stock()->stock_disponible);
    }

    public function test_una_venta_directa_no_puede_usar_lo_reservado(): void
    {
        app(PedidoService::class)->crear($this->datos(8));

        $this->postJson('/api/notas-venta', $this->datosVenta(5))
            ->assertStatus(422)
            ->assertJsonPath('message', fn ($m) => str_contains($m, 'Stock insuficiente'));

        $this->assertEquals(10, $this->stock()->stock_actual);
    }

    public function test_convertir_libera_reserva_y_descuenta_stock_real(): void
    {
        $service = app(PedidoService::class);
        $pedido = $service->crear($this->datos(8));

        $nota = $service->convertir($pedido, $this->datosVenta(8));

        $this->assertSame('convertido', $pedido->fresh()->estado);
        $this->assertSame($nota->id, $pedido->fresh()->nota_venta_id);
        $this->assertEquals(2, $this->stock()->stock_actual);
        $this->assertEquals(0, $this->stock()->stock_reservado);
        $this->assertEquals(2, $this->stock()->stock_disponible);
    }

    public function test_convertir_que_falla_conserva_la_reserva(): void
    {
        $service = app(PedidoService::class);
        $pedido = $service->crear($this->datos(8));

        try {
            // Intenta vender 12 de un stock de 10: la venta falla.
            $service->convertir($pedido, $this->datosVenta(12));
            $this->fail('Debió fallar por stock insuficiente');
        } catch (\RuntimeException) {
        }

        $this->assertSame('pendiente', $pedido->fresh()->estado);
        $this->assertEquals(8, $this->stock()->stock_reservado);
        $this->assertEquals(10, $this->stock()->stock_actual);
    }

    public function test_un_pedido_ya_convertido_no_se_cancela(): void
    {
        $service = app(PedidoService::class);
        $pedido = $service->crear($this->datos(2));
        $service->convertir($pedido, $this->datosVenta(2));

        $this->expectException(\InvalidArgumentException::class);
        $service->cancelar($pedido->fresh(), 'tarde');
    }

    private function datosVenta(float $cantidad): array
    {
        return [
            'almacen_id' => $this->almacen->id,
            'vendedor_id' => $this->vendedor->id,
            'fecha_emision' => now()->toDateString(),
            'tipo_pago' => 'contado',
            'subtotal' => $cantidad * 5,
            'total' => $cantidad * 5,
            'detalles' => [[
                'producto_presentacion_id' => $this->presentacion->id,
                'cantidad' => $cantidad,
                'precio_unitario' => 5,
                'descuento' => 0,
                'subtotal' => $cantidad * 5,
            ]],
            'pagos' => [[
                'forma_pago' => 'efectivo',
                'monto' => $cantidad * 5,
                'fecha' => now()->toDateString(),
            ]],
        ];
    }
}
