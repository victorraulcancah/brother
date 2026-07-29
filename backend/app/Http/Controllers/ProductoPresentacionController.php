<?php
namespace App\Http\Controllers;

use App\Models\Producto;
use App\Models\ProductoPresentacion;
use Illuminate\Http\Request;

class ProductoPresentacionController extends Controller
{
    public function index(Producto $producto)
    {
        return response()->json(
            $producto->presentaciones()->with('unidadBase')->orderBy('factor_conversion')->get()
        );
    }

    public function store(Request $request, Producto $producto)
    {
        $data = $request->validate([
            'nombre' => 'required|string|max:255',
            'codigo_barras' => 'nullable|string|max:255|unique:producto_presentaciones,codigo_barras',
            'precio_venta' => 'required|numeric|min:0',
            'factor_conversion' => 'required|numeric|min:0.01',
            'es_compra' => 'boolean',
            'es_venta' => 'boolean',
            'unidad_base_id' => 'nullable|exists:unidades_medida,id',
            'activo' => 'boolean',
        ]);

        $data['producto_id'] = $producto->id;
        $presentacion = ProductoPresentacion::create($data);

        return response()->json(
            $presentacion->load('unidadBase'),
            201
        );
    }

    public function show(ProductoPresentacion $presentacion)
    {
        return response()->json($presentacion->load('unidadBase'));
    }

    public function update(Request $request, ProductoPresentacion $presentacion)
    {
        $data = $request->validate([
            'nombre' => 'required|string|max:255',
            'codigo_barras' => 'nullable|string|max:255|unique:producto_presentaciones,codigo_barras,' . $presentacion->id,
            'precio_venta' => 'required|numeric|min:0',
            'factor_conversion' => 'required|numeric|min:0.01',
            'es_compra' => 'boolean',
            'es_venta' => 'boolean',
            'unidad_base_id' => 'nullable|exists:unidades_medida,id',
            'activo' => 'boolean',
        ]);

        $presentacion->update($data);
        return response()->json($presentacion->load('unidadBase'));
    }

    public function destroy(ProductoPresentacion $presentacion)
    {
        $presentacion->delete();
        return response()->json(['message' => 'Presentación eliminada']);
    }
}
