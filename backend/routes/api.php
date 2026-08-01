<?php

use App\Http\Controllers\AjusteInventarioController;
use App\Http\Controllers\AlmacenController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\BancoController;
use App\Http\Controllers\BilleteraDigitalController;
use App\Http\Controllers\CajaController;
use App\Http\Controllers\CuentaBancariaController;
use App\Http\Controllers\CuentaPorCobrarController;
use App\Http\Controllers\CuentaPorPagarController;
use App\Http\Controllers\MovimientoCajaController;
use App\Http\Controllers\TarjetaBancariaController;
use App\Http\Controllers\CategoriaController;
use App\Http\Controllers\CompraController;
use App\Http\Controllers\ClienteController;
use App\Http\Controllers\EmpresaController;
use App\Http\Controllers\MarcaController;
use App\Http\Controllers\MotivoMovimientoController;
use App\Http\Controllers\MovimientoInventarioController;
use App\Http\Controllers\NotaVentaController;
use App\Http\Controllers\OrdenCompraController;
use App\Http\Controllers\ProductoController;
use App\Http\Controllers\ProductoPresentacionController;
use App\Http\Controllers\ProveedorController;
use App\Http\Controllers\PrestamoController;
use App\Http\Controllers\RecepcionCompraController;
use App\Http\Controllers\RoleController;
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
    Route::apiResource('ordenes-compra', OrdenCompraController::class);
    Route::apiResource('compras', CompraController::class);
    Route::post('compras/{compra}/anular', [CompraController::class, 'anular']);
    Route::apiResource('recepciones-compra', RecepcionCompraController::class);

    // Inventario
    Route::get('existencias', [AlmacenController::class, 'existencias']);
    Route::apiResource('almacenes', AlmacenController::class);
    Route::get('movimientos', [MovimientoInventarioController::class, 'index']);
    Route::apiResource('transferencias', TransferenciaController::class);
    Route::post('transferencias/{transferencia}/enviar', [TransferenciaController::class, 'enviar']);
    Route::post('transferencias/{transferencia}/recibir', [TransferenciaController::class, 'recibir']);
    Route::post('transferencias/{transferencia}/anular', [TransferenciaController::class, 'anular']);
    Route::apiResource('ajustes', AjusteInventarioController::class);
    Route::apiResource('tomas-inventario', TomaInventarioController::class);
    Route::apiResource('motivos-movimiento', MotivoMovimientoController::class);
    Route::apiResource('prestamos', PrestamoController::class);
    Route::post('prestamos/{prestamo}/devoluciones', [PrestamoController::class, 'devolucion']);
    // Facturación
    Route::apiResource('clientes', ClienteController::class);
    Route::get('notas-venta', [NotaVentaController::class, 'index']);
    Route::post('notas-venta', [NotaVentaController::class, 'store']);
    Route::get('notas-venta/{notaVenta}', [NotaVentaController::class, 'show']);
    Route::post('notas-venta/{notaVenta}/anular', [NotaVentaController::class, 'anular']);
    Route::delete('notas-venta/{notaVenta}', [NotaVentaController::class, 'destroy']);

    // Tesorería
    Route::apiResource('bancos', BancoController::class);
    Route::apiResource('cuentas-bancarias', CuentaBancariaController::class);
    Route::apiResource('tarjetas-bancarias', TarjetaBancariaController::class);
    Route::apiResource('billeteras-digitales', BilleteraDigitalController::class);
    Route::apiResource('cajas', CajaController::class);
    Route::get('movimientos-caja', [MovimientoCajaController::class, 'index']);
    Route::get('cuentas-por-cobrar', [CuentaPorCobrarController::class, 'index']);
    Route::get('cuentas-por-pagar', [CuentaPorPagarController::class, 'index']);

    // Gestión
    Route::apiResource('empresas', EmpresaController::class);
    Route::get('users', [UserController::class, 'index']);
    Route::post('users', [UserController::class, 'store']);
    Route::get('users/{id}', [UserController::class, 'show']);
    Route::put('users/{id}', [UserController::class, 'update']);
    Route::delete('users/{id}', [UserController::class, 'destroy']);
    Route::post('users/{id}/assign-role', [UserController::class, 'assignRole']);
    Route::apiResource('roles', RoleController::class);
});
