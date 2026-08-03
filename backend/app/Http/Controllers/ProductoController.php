<?php
namespace App\Http\Controllers;

use App\Http\Requests\Producto\StoreProductoRequest;
use App\Http\Requests\Producto\UpdateProductoRequest;
use App\Http\Resources\ProductoResource;
use App\Models\Almacen;
use App\Models\Producto;
use App\Models\ProductoAlmacenStock;
use App\Models\ProductoLote;
use App\Models\ProductoPresentacion;
use Illuminate\Support\Facades\DB;

class ProductoController extends Controller
{
    private const RELATIONS = [
        'marca', 'subMarca', 'categoria', 'subCategoria', 'unidadMedida',
        'unidadCompra', 'unidadBase',
        'presentaciones.unidadBase', 'presentaciones.complementario',
        'lotes',
    ];

    public function index()
    {
        $productos = Producto::with(['marca', 'categoria', 'subCategoria', 'unidadMedida', 'presentaciones'])
            ->paginate(15);
        return ProductoResource::collection($productos);
    }

    public function store(StoreProductoRequest $request)
    {
        $data = $request->validated();

        $producto = DB::transaction(function () use ($data) {
            $producto = Producto::create($this->soloProducto($data));
            $this->syncPresentaciones($producto, $data['presentaciones'] ?? []);
            $this->registrarLoteInicial($producto, $data['lote'] ?? null);
            return $producto;
        });

        return new ProductoResource($producto->load(self::RELATIONS));
    }

    public function show(Producto $producto)
    {
        return new ProductoResource($producto->load(self::RELATIONS));
    }

    public function update(UpdateProductoRequest $request, Producto $producto)
    {
        $data = $request->validated();

        DB::transaction(function () use ($producto, $data) {
            $producto->update($this->soloProducto($data));
            if (array_key_exists('presentaciones', $data)) {
                $this->syncPresentaciones($producto, $data['presentaciones'] ?? []);
            }
        });

        return new ProductoResource($producto->load(self::RELATIONS));
    }

    public function destroy(Producto $producto)
    {
        $producto->delete();
        return response()->json(['message' => 'Producto eliminado correctamente']);
    }

    /** Solo las columnas propias del producto (sin presentaciones ni lote). */
    private function soloProducto(array $data): array
    {
        return collect($data)->except(['presentaciones', 'lote'])->all();
    }

    /** Reemplaza las presentaciones del producto por la lista enviada. */
    private function syncPresentaciones(Producto $producto, array $lista): void
    {
        $producto->presentaciones()->delete();

        foreach ($lista as $p) {
            ProductoPresentacion::create([
                'producto_id' => $producto->id,
                'nombre' => $p['nombre'],
                'codigo_barras' => $p['codigo_barras'] ?? null,
                'precio_venta' => $p['precio_venta'] ?? 0,
                'precio_compra' => $p['precio_compra'] ?? 0,
                'margen' => $p['margen'] ?? 0,
                'factor_conversion' => $p['factor_conversion'],
                'unidad_base_id' => $p['unidad_base_id'] ?? null,
                'producto_complementario_id' => $p['producto_complementario_id'] ?? null,
                'cantidad_complementaria' => $p['cantidad_complementaria'] ?? 0,
                'activo' => $p['activo'] ?? true,
            ]);
        }
    }

    /** Crea el lote inicial y carga el stock en el almacén principal. */
    private function registrarLoteInicial(Producto $producto, ?array $lote): void
    {
        if (! $lote) {
            return;
        }

        $stockInicial = (float) ($lote['stock_inicial'] ?? 0);
        $tieneLote = ! empty($lote['numero_lote']) || ! empty($lote['fecha_vencimiento']) || $stockInicial > 0;
        if (! $tieneLote) {
            return;
        }

        ProductoLote::create([
            'producto_id' => $producto->id,
            'numero_lote' => $lote['numero_lote'] ?? null,
            'fecha_vencimiento' => $lote['fecha_vencimiento'] ?? null,
            'stock_inicial' => $stockInicial,
        ]);

        if ($stockInicial > 0) {
            $almacen = Almacen::orderBy('id')->first();
            if ($almacen) {
                $stock = ProductoAlmacenStock::firstOrNew([
                    'producto_id' => $producto->id,
                    'almacen_id' => $almacen->id,
                ]);
                $actual = (float) ($stock->stock_actual ?? 0);
                $stock->stock_actual = $actual + $stockInicial;
                $stock->stock_disponible = $stock->stock_actual - (float) ($stock->stock_reservado ?? 0);
                $stock->save();
            }
        }
    }
}
