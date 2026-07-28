<?php

namespace App\Http\Controllers;

use App\Http\Resources\CategoriaResource;
use App\Models\Categoria;

class CategoriaController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    public function index()
    {
        $categorias = Categoria::with('hijos')->whereNull('categoria_padre_id')->where('activo', true)->get();
        return CategoriaResource::collection($categorias);
    }
}
