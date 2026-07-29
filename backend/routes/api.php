<?php

use App\Http\Controllers\AjusteInventarioController;
use App\Http\Controllers\AlmacenController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CategoriaController;
use App\Http\Controllers\CosteoController;
use App\Http\Controllers\EmpresaController;
use App\Http\Controllers\MarcaController;
use App\Http\Controllers\MovimientoInventarioController;
use App\Http\Controllers\OrdenCompraController;
use App\Http\Controllers\ProductoController;
use App\Http\Controllers\ProductoPresentacionController;
use App\Http\Controllers\ProveedorController;
use App\Http\Controllers\RecepcionCompraController;
use App\Http\Controllers\RoleController;
use App\Http\Controllers\SolicitudCompraController;
use App\Http\Controllers\SubMarcaController;
use App\Http\Controllers\TomaInventarioController;
use App\Http\Controllers\TransferenciaController;
use App\Http\Controllers\UnidadMedidaController;
use App\Http\Controllers\UserController;
use Illuminate\Support\Facades\Route;

Route::post('login', [AuthController::class, 'login']);
Route::post('register', [AuthController::class, 'register']);
Route::post('refresh', [AuthController::class, 'refresh']);

Route::middleware('auth:api')->group(function () {
    Route::post('logout', [AuthController::class, 'logout']);
    Route::get('me', [AuthController::class, 'me']);

    // Catálogo
    Route::apiResource('categorias', CategoriaController::class);
    Route::apiResource('marcas', MarcaController::class);
    Route::apiResource('sub-marcas', SubMarcaController::class);
    Route::apiResource('productos', ProductoController::class);
    Route::apiResource('productos.presentaciones', ProductoPresentacionController::class)->shallow();
    Route::apiResource('unidades-medida', UnidadMedidaController::class);

    // Compras
    Route::apiResource('proveedores', ProveedorController::class);
    Route::apiResource('solicitudes-compra', SolicitudCompraController::class);
    Route::apiResource('ordenes-compra', OrdenCompraController::class);
    Route::apiResource('recepciones-compra', RecepcionCompraController::class);

    // Inventario
    Route::get('existencias', [AlmacenController::class, 'existencias']);
    Route::apiResource('almacenes', AlmacenController::class);
    Route::get('movimientos', [MovimientoInventarioController::class, 'index']);
    Route::apiResource('transferencias', TransferenciaController::class);
    Route::apiResource('ajustes', AjusteInventarioController::class);
    Route::apiResource('tomas-inventario', TomaInventarioController::class);
    Route::get('costeo', [CosteoController::class, 'index']);
    Route::put('costeo', [CosteoController::class, 'update']);

    // Gestión
    Route::apiResource('empresas', EmpresaController::class);
    Route::get('users', [UserController::class, 'index']);
    Route::get('users/{id}', [UserController::class, 'show']);
    Route::put('users/{id}', [UserController::class, 'update']);
    Route::delete('users/{id}', [UserController::class, 'destroy']);
    Route::post('users/{id}/assign-role', [UserController::class, 'assignRole']);
    Route::apiResource('roles', RoleController::class);
});
