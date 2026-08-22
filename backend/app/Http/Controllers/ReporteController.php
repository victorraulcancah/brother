<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Reportes del negocio. Solo soles, sin IGV.
 * Utilidad bruta = ventas − costo (costo promedio ponderado).
 * Utilidad neta  = utilidad bruta − gastos operativos (egresos de caja con motivo 'operativo').
 */
class ReporteController extends Controller
{
    public function utilidades(Request $request)
    {
        $agrupar = in_array($request->input('agrupar'), ['mes', 'producto', 'categoria']) ? $request->input('agrupar') : 'mes';
        $desde = $request->date('desde')?->startOfDay() ?? now()->subMonths(11)->startOfMonth();
        $hasta = $request->date('hasta')?->endOfDay() ?? now()->endOfMonth();
        $rango = [$desde->toDateString(), $hasta->toDateString()];

        // Expresión de agrupación + join de categoría cuando aplica.
        $costoSub = '(SELECT producto_id, AVG(NULLIF(costo_promedio,0)) AS costo FROM producto_almacen_stock GROUP BY producto_id)';

        $q = DB::table('nota_venta_detalles as d')
            ->join('notas_venta as nv', 'nv.id', '=', 'd.nota_venta_id')
            ->join('producto_presentaciones as pp', 'pp.id', '=', 'd.producto_presentacion_id')
            ->join('productos as p', 'p.id', '=', 'pp.producto_id')
            ->leftJoin(DB::raw("($costoSub) as c"), 'c.producto_id', '=', 'p.id')
            ->where('nv.estado', 'emitida')
            ->whereBetween('nv.fecha_emision', $rango);

        if ($agrupar === 'producto') {
            $grupoSel = 'p.nombre as grupo';
            $groupBy = ['p.id', 'p.nombre'];
        } elseif ($agrupar === 'categoria') {
            $q->leftJoin('categorias as cat', 'cat.id', '=', 'p.categoria_id');
            $grupoSel = "COALESCE(cat.nombre, 'Sin categoría') as grupo";
            $groupBy = ['cat.id', 'cat.nombre'];
        } else { // mes
            $grupoSel = "DATE_FORMAT(nv.fecha_emision, '%Y-%m') as grupo";
            $groupBy = ['grupo'];
        }

        $ventas = $q->groupBy($groupBy)
            ->selectRaw("$grupoSel,
                SUM(d.subtotal) as ventas,
                SUM(d.cantidad * pp.factor_conversion * COALESCE(c.costo,0)) as costo")
            ->get();

        // Gastos operativos por mes (solo relevante para agrupación por mes).
        $gastosPorMes = [];
        if ($agrupar === 'mes') {
            $gastosPorMes = DB::table('movimientos_caja as m')
                ->join('motivos_movimiento as mo', 'mo.id', '=', 'm.motivo_movimiento_id')
                ->where('m.tipo', 'egreso')
                ->where('mo.categoria_gasto', 'operativo')
                ->whereBetween('m.fecha', $rango)
                ->selectRaw("DATE_FORMAT(m.fecha, '%Y-%m') as grupo, SUM(m.monto) as gastos")
                ->groupBy('grupo')
                ->pluck('gastos', 'grupo');
        }

        $filas = $ventas->map(function ($r) use ($agrupar, $gastosPorMes) {
            $vtas = round((float) $r->ventas, 2);
            $costo = round((float) $r->costo, 2);
            $bruta = round($vtas - $costo, 2);
            $gastos = $agrupar === 'mes' ? round((float) ($gastosPorMes[$r->grupo] ?? 0), 2) : 0.0;
            $neta = round($bruta - $gastos, 2);

            return [
                'grupo' => $r->grupo,
                'ventas' => $vtas,
                'costo' => $costo,
                // Ganancia = lo que se gana en la venta (ventas − costo), antes de gastos.
                'ganancia' => $bruta,
                'utilidad_bruta' => $bruta,
                'gastos' => $gastos,
                // Utilidad = ganancia − gastos operativos (lo que realmente queda).
                'utilidad_neta' => $neta,
                // % de ganancia (marcado sobre el costo) y margen (sobre ventas).
                'margen_ganancia' => $costo > 0 ? round($bruta / $costo * 100, 1) : 0,
                'margen' => $vtas > 0 ? round($neta / $vtas * 100, 1) : 0,
            ];
        });

        // Orden: por mes ascendente; por producto/categoría por utilidad neta desc.
        $filas = $agrupar === 'mes'
            ? $filas->sortBy('grupo')->values()
            : $filas->sortByDesc('utilidad_neta')->values();

        $tot = [
            'ventas' => round($filas->sum('ventas'), 2),
            'costo' => round($filas->sum('costo'), 2),
            'ganancia' => round($filas->sum('ganancia'), 2),
            'utilidad_bruta' => round($filas->sum('utilidad_bruta'), 2),
            'gastos' => round($filas->sum('gastos'), 2),
            'utilidad_neta' => round($filas->sum('utilidad_neta'), 2),
        ];
        $tot['margen_ganancia'] = $tot['costo'] > 0 ? round($tot['ganancia'] / $tot['costo'] * 100, 1) : 0;
        $tot['margen'] = $tot['ventas'] > 0 ? round($tot['utilidad_neta'] / $tot['ventas'] * 100, 1) : 0;

        return response()->json([
            'agrupar' => $agrupar,
            'rango' => ['desde' => $rango[0], 'hasta' => $rango[1]],
            'filas' => $filas,
            'totales' => $tot,
        ]);
    }
}
