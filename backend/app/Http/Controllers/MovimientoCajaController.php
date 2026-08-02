<?php

namespace App\Http\Controllers;

use App\Models\AperturaCaja;
use App\Models\MetodoPago;
use App\Models\MovimientoCaja;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class MovimientoCajaController extends Controller
{
    private const WITH = [
        'motivo:id,nombre,tipo,es_sistema',
        'metodoPago:id,nombre,tipo,requiere_cuenta_bancaria,requiere_numero_operacion',
        'cuentaBancaria:id,nombre,numero',
        'tarjeta:id,nombre,numero',
        'billetera:id,nombre',
        'apertura.caja:id,nombre',
    ];

    public function index(Request $request)
    {
        $user = auth('api')->user();

        $query = MovimientoCaja::with(self::WITH)
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

    public function store(Request $request)
    {
        $user = auth('api')->user();

        $data = $request->validate([
            'caja_id' => 'nullable|exists:cajas,id',
            'tipo' => 'required|in:ingreso,egreso',
            'motivo_movimiento_id' => 'required|exists:motivos_movimiento,id',
            'metodo_pago_id' => 'required|exists:metodos_pago,id',
            'cuenta_bancaria_id' => 'nullable|exists:cuentas_bancarias,id',
            'billetera_id' => 'nullable|exists:billeteras_digitales,id',
            'numero_operacion' => 'nullable|string|max:100',
            'monto' => 'required|numeric|min:0.01',
            'descripcion' => 'nullable|string|max:255',
            'fecha' => 'required|date',
        ]);

        $cajaId = $data['caja_id'] ?? $user?->caja_id;
        if (!$cajaId) {
            throw ValidationException::withMessages(['caja_id' => 'No tienes una caja asignada.']);
        }

        $apertura = AperturaCaja::where('caja_id', $cajaId)
            ->where('estado', 'abierta')
            ->latest('fecha_apertura')
            ->first();

        if (!$apertura) {
            throw ValidationException::withMessages(['caja_id' => 'La caja no tiene una apertura abierta.']);
        }

        return DB::transaction(function () use ($data, $apertura) {
            $motivo = \App\Models\MotivoMovimiento::findOrFail($data['motivo_movimiento_id']);
            $metodo = MetodoPago::findOrFail($data['metodo_pago_id']);

            $tipoMotivo = $data['tipo'] === 'ingreso' ? 'entrada' : 'salida';
            if ($motivo->tipo !== $tipoMotivo) {
                throw ValidationException::withMessages([
                    'motivo_movimiento_id' => "El motivo \"{$motivo->nombre}\" es de tipo {$motivo->tipo} y no corresponde a un " . ($data['tipo'] === 'ingreso' ? 'ingreso' : 'egreso') . '.',
                ]);
            }

            $asignados = $apertura->caja->metodosPago()->pluck('metodos_pago.id');
            if ($asignados->isNotEmpty() && !$asignados->contains($metodo->id)) {
                throw ValidationException::withMessages([
                    'metodo_pago_id' => "La caja no acepta el método de pago \"{$metodo->nombre}\".",
                ]);
            }

            if ($metodo->requiere_cuenta_bancaria && empty($data['cuenta_bancaria_id'])) {
                throw ValidationException::withMessages(['cuenta_bancaria_id' => 'Este método requiere seleccionar una cuenta bancaria.']);
            }
            if ($metodo->tipo === 'billetera' && empty($data['billetera_id'])) {
                throw ValidationException::withMessages(['billetera_id' => 'Este método requiere seleccionar una billetera digital.']);
            }
            if ($metodo->requiere_numero_operacion && empty($data['numero_operacion'])) {
                throw ValidationException::withMessages(['numero_operacion' => 'Este método requiere el número de operación.']);
            }

            $movimiento = MovimientoCaja::create([
                'apertura_caja_id' => $apertura->id,
                'tipo' => $data['tipo'],
                'motivo_movimiento_id' => $motivo->id,
                'metodo_pago_id' => $metodo->id,
                'cuenta_bancaria_id' => $data['cuenta_bancaria_id'] ?? null,
                'billetera_id' => $data['billetera_id'] ?? null,
                'numero_operacion' => $data['numero_operacion'] ?? null,
                'monto' => $data['monto'],
                'descripcion' => $data['descripcion'] ?? null,
                'fecha' => $data['fecha'],
            ]);

            return response()->json($movimiento->load(self::WITH), 201);
        });
    }
}
