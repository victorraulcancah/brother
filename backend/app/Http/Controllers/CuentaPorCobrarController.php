<?php

namespace App\Http\Controllers;

use App\Models\CuentaPorCobrar;

class CuentaPorCobrarController extends Controller
{
    public function index()
    {
        return response()->json(
            CuentaPorCobrar::with(['cliente:id,nombre', 'notaVenta:id'])
                ->latest('id')
                ->get()
        );
    }
}
