<?php

namespace App\Http\Controllers;

use App\Models\MovimientoCaja;

class MovimientoCajaController extends Controller
{
    public function index()
    {
        return response()->json(
            MovimientoCaja::with(['metodoPago:id,nombre', 'apertura.caja:id,nombre'])
                ->latest('fecha')
                ->latest('id')
                ->limit(500)
                ->get()
        );
    }
}
