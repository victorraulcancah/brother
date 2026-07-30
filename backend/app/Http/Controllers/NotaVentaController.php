<?php

namespace App\Http\Controllers;

use App\Http\Requests\NotaVenta\AnularNotaVentaRequest;
use App\Http\Requests\NotaVenta\StoreNotaVentaRequest;
use App\Http\Resources\NotaVentaResource;
use App\Models\NotaVenta;
use App\Services\NotaVentaService;

class NotaVentaController extends Controller
{
    public function __construct(
        protected NotaVentaService $notaVentaService
    ) {}

    public function index()
    {
        $notas = NotaVenta::with(['cliente', 'almacen', 'vendedor', 'detalles.presentacion.producto', 'pagos.metodoPago'])
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return NotaVentaResource::collection($notas);
    }

    public function store(StoreNotaVentaRequest $request)
    {
        $nota = $this->notaVentaService->crear($request->validated());

        return new NotaVentaResource($nota);
    }

    public function show(NotaVenta $notaVenta)
    {
        return new NotaVentaResource(
            $notaVenta->load(['cliente', 'almacen', 'vendedor', 'detalles.presentacion.producto', 'pagos.metodoPago'])
        );
    }

    public function anular(AnularNotaVentaRequest $request, NotaVenta $notaVenta)
    {
        if ($notaVenta->estado !== 'emitida') {
            return response()->json(['message' => 'Solo se pueden anular notas de venta emitidas'], 422);
        }

        $nota = $this->notaVentaService->anular($notaVenta, $request->validated()['motivo_anulacion']);

        return new NotaVentaResource($nota);
    }

    public function destroy(NotaVenta $notaVenta)
    {
        $notaVenta->delete();
        return response()->json(['message' => 'Nota de venta eliminada correctamente']);
    }
}
