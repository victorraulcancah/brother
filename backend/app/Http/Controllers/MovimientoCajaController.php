<?php

namespace App\Http\Controllers;

use App\Models\MovimientoCaja;
use Illuminate\Http\Request;

class MovimientoCajaController extends Controller
{
    public function index(Request $request)
    {
        $user = auth('api')->user();

        $query = MovimientoCaja::with(['metodoPago:id,nombre', 'apertura.caja:id,nombre'])
            ->when($request->filled('caja_id'), fn ($q) => $q->whereHas('apertura', fn ($a) => $a->where('caja_id', $request->integer('caja_id'))))
            ->when(
                $user?->caja_id && !$user->hasRole('super-admin'),
                fn ($q) => $q->whereHas('apertura', fn ($a) => $a->where('caja_id', $user->caja_id))
            )
            ->latest('fecha')
            ->latest('id')
            ->limit(500);

        return response()->json($query->get());
    }
}
