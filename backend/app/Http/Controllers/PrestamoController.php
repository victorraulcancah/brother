<?php

namespace App\Http\Controllers;

use App\Models\Prestamo;
use App\Models\PrestamoDevolucion;
use Illuminate\Http\Request;

class PrestamoController extends Controller
{
    public function index()
    {
        return response()->json(
            Prestamo::with(['almacen', 'detalles.presentacion.producto'])->latest()->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'almacen_id' => 'required|exists:almacenes,id',
            'tipo' => 'required|string|in:prestado,recibido',
            'tercero' => 'required|string|max:255',
            'fecha_prestamo' => 'nullable|date',
            'fecha_devolucion_esperada' => 'nullable|date',
            'observaciones' => 'nullable|string',
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_presentacion_id' => 'required|exists:producto_presentaciones,id',
            'detalles.*.cantidad_prestada' => 'required|numeric|min:0.01',
        ]);

        $data['fecha_prestamo'] = $data['fecha_prestamo'] ?? now();
        $data['estado'] = 'prestado';
        $data['usuario_id'] = auth()->id();

        $prestamo = Prestamo::create($data);

        foreach ($data['detalles'] as $detalle) {
            $prestamo->detalles()->create([
                'producto_presentacion_id' => $detalle['producto_presentacion_id'],
                'cantidad_prestada' => $detalle['cantidad_prestada'],
            ]);
        }

        return response()->json(
            $prestamo->load(['almacen', 'detalles.presentacion.producto']),
            201
        );
    }

    public function show(Prestamo $prestamo)
    {
        return response()->json(
            $prestamo->load(['almacen', 'usuario', 'detalles.presentacion.producto', 'devoluciones.presentacion.producto'])
        );
    }

    public function update(Request $request, Prestamo $prestamo)
    {
        $data = $request->validate([
            'tercero' => 'string|max:255',
            'fecha_devolucion_esperada' => 'nullable|date',
            'observaciones' => 'nullable|string',
        ]);
        $prestamo->update($data);
        return response()->json($prestamo->load('almacen'));
    }

    public function destroy(Prestamo $prestamo)
    {
        $prestamo->delete();
        return response()->json(['message' => 'Eliminado']);
    }

    /**
     * Registra una devolución (parcial o total) y recalcula el estado.
     */
    public function devolucion(Request $request, Prestamo $prestamo)
    {
        $data = $request->validate([
            'producto_presentacion_id' => 'required|exists:producto_presentaciones,id',
            'cantidad' => 'required|numeric|min:0.01',
        ]);

        $detalle = $prestamo->detalles()
            ->where('producto_presentacion_id', $data['producto_presentacion_id'])
            ->first();

        if (!$detalle) {
            return response()->json(['message' => 'El producto no pertenece a este préstamo.'], 422);
        }

        $devuelto = $prestamo->devoluciones()
            ->where('producto_presentacion_id', $data['producto_presentacion_id'])
            ->sum('cantidad');

        if ($devuelto + $data['cantidad'] > $detalle->cantidad_prestada + 0.0001) {
            return response()->json(['message' => 'La cantidad devuelta supera lo prestado.'], 422);
        }

        PrestamoDevolucion::create([
            'prestamo_id' => $prestamo->id,
            'producto_presentacion_id' => $data['producto_presentacion_id'],
            'cantidad' => $data['cantidad'],
            'fecha' => now(),
            'usuario_id' => auth()->id(),
        ]);

        $prestamo->estado = $this->calcularEstado($prestamo);
        $prestamo->save();

        return response()->json(
            $prestamo->load(['almacen', 'detalles.presentacion.producto', 'devoluciones.presentacion.producto'])
        );
    }

    /**
     * Estado calculado: prestado (nada devuelto), parcial (algo devuelto) o devuelto (todo devuelto).
     */
    private function calcularEstado(Prestamo $prestamo): string
    {
        $pendiente = false;
        foreach ($prestamo->detalles as $detalle) {
            $devuelto = $prestamo->devoluciones()
                ->where('producto_presentacion_id', $detalle->producto_presentacion_id)
                ->sum('cantidad');
            if ($devuelto < $detalle->cantidad_prestada) {
                $pendiente = true;
            }
        }

        if (!$pendiente) {
            return 'devuelto';
        }

        return $prestamo->devoluciones()->exists() ? 'parcial' : 'prestado';
    }
}
