<?php

namespace App\Http\Controllers;

use App\Http\Requests\NotaVenta\StoreNotaVentaRequest;
use App\Http\Requests\Pedido\StorePedidoRequest;
use App\Http\Resources\NotaVentaResource;
use App\Http\Resources\PedidoResource;
use App\Models\Pedido;
use App\Services\PedidoService;
use Illuminate\Http\Request;

class PedidoController extends Controller
{
    private const RELACIONES = ['cliente', 'almacen', 'vendedor', 'notaVenta', 'detalles.presentacion.producto.marca'];

    public function __construct(
        protected PedidoService $pedidoService
    ) {}

    public function index(Request $request)
    {
        $pedidos = Pedido::with(self::RELACIONES)
            ->when($request->filled('estado'), fn ($q) => $q->where('estado', $request->string('estado')))
            ->orderBy('created_at', 'desc')
            ->paginate(min(max($request->integer('per_page', 15), 1), 200));

        return PedidoResource::collection($pedidos);
    }

    public function store(StorePedidoRequest $request)
    {
        return $this->conMensajes(fn () => new PedidoResource(
            $this->pedidoService->crear($request->validated())
        ), 201);
    }

    public function show(Pedido $pedido)
    {
        return new PedidoResource($pedido->load(self::RELACIONES));
    }

    public function update(StorePedidoRequest $request, Pedido $pedido)
    {
        return $this->conMensajes(fn () => new PedidoResource(
            $this->pedidoService->actualizar($pedido, $request->validated())
        ));
    }

    public function cancelar(Request $request, Pedido $pedido)
    {
        $motivo = $request->validate(['motivo_cancelacion' => 'required|string|max:500'])['motivo_cancelacion'];

        return $this->conMensajes(fn () => new PedidoResource(
            $this->pedidoService->cancelar($pedido, $motivo)
        ));
    }

    /** Recibe el mismo cuerpo que POST notas-venta y emite la venta desde el pedido. */
    public function convertir(StoreNotaVentaRequest $request, Pedido $pedido)
    {
        return $this->conMensajes(fn () => new NotaVentaResource(
            $this->pedidoService->convertir($pedido, $request->validated())
        ), 201);
    }

    /**
     * Los errores de negocio (pedido que no está pendiente, stock insuficiente)
     * se devuelven como 422 con su mensaje; sin esto el usuario vería un 500
     * genérico y no sabría qué producto falta.
     */
    private function conMensajes(\Closure $accion, int $status = 200)
    {
        try {
            return $accion()->response()->setStatusCode($status);
        } catch (\InvalidArgumentException|\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }
}
