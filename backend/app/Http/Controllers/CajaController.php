<?php

namespace App\Http\Controllers;

use App\Models\Caja;
use App\Models\User;
use Illuminate\Http\Request;

class CajaController extends Controller
{
    private const WITH = ['almacen:id,nombre', 'metodosPago:id,nombre,tipo,es_sistema', 'usuario:id,name,email,caja_id'];

    public function index()
    {
        return response()->json(Caja::with(self::WITH)->orderBy('nombre')->get());
    }

    public function store(Request $request)
    {
        $data = $this->validated($request);
        $metodos = $data['metodos_pago'] ?? [];
        unset($data['metodos_pago']);

        $caja = Caja::create($data);
        $caja->metodosPago()->sync($metodos);
        $this->assignUsuario($caja, $data['usuario_id'] ?? null);

        return response()->json($caja->load(self::WITH), 201);
    }

    public function show(Caja $caja)
    {
        return response()->json($caja->load(self::WITH));
    }

    public function update(Request $request, Caja $caja)
    {
        $data = $this->validated($request);
        $metodos = $data['metodos_pago'] ?? [];
        unset($data['metodos_pago']);

        $caja->update($data);
        $caja->metodosPago()->sync($metodos);
        $this->assignUsuario($caja, $data['usuario_id'] ?? null);

        return response()->json($caja->load(self::WITH));
    }

    public function destroy(Caja $caja)
    {
        User::where('caja_id', $caja->id)->update(['caja_id' => null]);
        $caja->delete();
        return response()->json(['message' => 'Eliminado']);
    }

    private function assignUsuario(Caja $caja, ?int $usuarioId): void
    {
        User::where('caja_id', $caja->id)->update(['caja_id' => null]);
        if ($usuarioId) {
            User::where('id', $usuarioId)->update(['caja_id' => $caja->id]);
        }
    }

    private function validated(Request $request): array
    {
        return $request->validate([
            'nombre' => 'required|string|max:255',
            'almacen_id' => 'nullable|exists:almacenes,id',
            'activo' => 'boolean',
            'usuario_id' => 'nullable|exists:users,id',
            'metodos_pago' => 'nullable|array',
            'metodos_pago.*' => 'exists:metodos_pago,id',
        ]);
    }
}
