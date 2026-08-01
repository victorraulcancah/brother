<?php

namespace App\Http\Controllers;

use App\Models\CuentaPorPagar;

class CuentaPorPagarController extends Controller
{
    public function index()
    {
        return response()->json(
            CuentaPorPagar::with(['proveedor:id,nombre', 'recepcionCompra:id'])
                ->latest('id')
                ->get()
        );
    }
}
