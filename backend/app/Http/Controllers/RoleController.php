<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Spatie\Permission\Models\Role;

class RoleController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(
            Role::orderBy('name')->get(['id', 'name', 'guard_name'])
        );
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => 'required|string|max:255|unique:roles,name',
        ]);

        $role = Role::create(['name' => $data['name']]);

        return response()->json($role, 201);
    }

    public function show(int $id): JsonResponse
    {
        $role = Role::findOrFail($id);

        return response()->json($role->only(['id', 'name', 'guard_name']));
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $role = Role::findOrFail($id);

        $data = $request->validate([
            'name' => 'required|string|max:255|unique:roles,name,' . $role->id,
        ]);

        $role->update(['name' => $data['name']]);

        return response()->json($role->only(['id', 'name', 'guard_name']));
    }

    public function destroy(int $id): JsonResponse
    {
        Role::findOrFail($id)->delete();

        return response()->json(['message' => 'Rol eliminado']);
    }
}
