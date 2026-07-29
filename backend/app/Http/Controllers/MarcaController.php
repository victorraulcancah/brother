<?php

namespace App\Http\Controllers;

use App\Http\Resources\MarcaResource;
use App\Models\Marca;

class MarcaController extends Controller
{
    public function __construct()
    {
    }

    public function index()
    {
        $marcas = Marca::with('subMarcas')->where('activo', true)->get();
        return MarcaResource::collection($marcas);
    }
}
