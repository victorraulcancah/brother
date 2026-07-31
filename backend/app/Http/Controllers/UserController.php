<?php

namespace App\Http\Controllers;

use App\Http\Requests\User\AssignRoleRequest;
use App\Http\Requests\User\StoreUserRequest;
use App\Http\Requests\User\UpdateUserRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Spatie\Permission\Models\Role;

class UserController extends Controller
{
    public function __construct()
    {
    }

    public function index(): JsonResponse
    {
        return response()->json(User::with('empresa', 'roles')->get());
    }

    public function store(StoreUserRequest $request): JsonResponse
    {
        $data = $request->validated();
        $role = $data['role'] ?? null;
        unset($data['role']);

        $user = User::create($data);

        if ($role) {
            $user->syncRoles([$role]);
        }

        return response()->json($user->load('empresa', 'roles'), 201);
    }

    public function show(int $id): JsonResponse
    {
        return response()->json(User::with('empresa', 'roles')->findOrFail($id));
    }

    public function update(UpdateUserRequest $request, int $id): JsonResponse
    {
        $user = User::findOrFail($id);
        $data = $request->validated();
        $role = $data['role'] ?? null;
        unset($data['role']);

        if (!empty($data)) {
            $user->update($data);
        }

        if ($role) {
            $user->syncRoles([$role]);
        }

        return response()->json($user->load('empresa', 'roles'));
    }

    public function destroy(int $id): JsonResponse
    {
        User::findOrFail($id)->delete();

        return response()->json(null, 204);
    }

    public function assignRole(AssignRoleRequest $request, int $id): JsonResponse
    {
        $user = User::findOrFail($id);
        $user->assignRole($request->role);

        return response()->json($user->load('roles'));
    }

    public function roles(): JsonResponse
    {
        return response()->json(Role::all()->pluck('name'));
    }
}
