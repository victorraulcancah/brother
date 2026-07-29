<?php

namespace App\Http\Controllers;

use App\Models\MovimientoInventario;
use Illuminate\Http\Request;

class MovimientoInventarioController extends Controller
{
    public function __construct()
    {
    }

    public function index()
    {
        return response()->json(MovimientoInventario::with('producto', 'almacen')->latest()->get());
    }
}
