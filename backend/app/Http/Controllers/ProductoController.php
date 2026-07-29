<?php

namespace App\Http\Controllers;

use App\Http\Requests\Producto\StoreProductoRequest;
use App\Http\Requests\Producto\UpdateProductoRequest;
use App\Http\Resources\ProductoResource;
use App\Models\Producto;

class ProductoController extends Controller
{
    public function __construct()
    {
    }

    public function index()
    {
        $productos = Producto::with(['marca', 'categoria', 'unidadMedida'])->paginate(15);
        return ProductoResource::collection($productos);
    }

    public function store(StoreProductoRequest $request)
    {
        $producto = Producto::create($request->validated());
        return new ProductoResource($producto->load(['marca', 'categoria', 'unidadMedida']));
    }

    public function show(Producto $producto)
    {
        $producto->load(['marca', 'subMarca', 'categoria', 'unidadMedida', 'variantes.atributoValores', 'imagenes']);
        return new ProductoResource($producto);
    }

    public function update(UpdateProductoRequest $request, Producto $producto)
    {
        $producto->update($request->validated());
        return new ProductoResource($producto->load(['marca', 'categoria', 'unidadMedida']));
    }

    public function destroy(Producto $producto)
    {
        $producto->delete();
        return response()->json(['message' => 'Producto eliminado correctamente']);
    }
}
