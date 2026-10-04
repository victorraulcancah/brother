<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pedidos', function (Blueprint $table) {
            $table->id();
            $table->string('serie');
            $table->string('numero');
            $table->foreignId('cliente_id')->nullable()->constrained('clientes')->nullOnDelete();
            $table->foreignId('almacen_id')->constrained('almacenes');
            $table->foreignId('vendedor_id')->constrained('users');
            $table->date('fecha_pedido');
            $table->date('fecha_entrega')->nullable();
            $table->string('moneda', 10)->default('PEN');
            $table->decimal('subtotal', 12, 2)->default(0);
            $table->decimal('descuento_total', 12, 2)->default(0);
            $table->decimal('total', 12, 2)->default(0);
            // pendiente: tiene stock reservado · convertido: ya es nota de venta · cancelado: reserva liberada
            $table->string('estado', 20)->default('pendiente');
            $table->foreignId('nota_venta_id')->nullable()->constrained('notas_venta')->nullOnDelete();
            $table->text('motivo_cancelacion')->nullable();
            $table->foreignId('usuario_cancela_id')->nullable()->constrained('users')->nullOnDelete();
            $table->dateTime('fecha_cancelacion')->nullable();
            $table->text('observaciones')->nullable();
            $table->timestamps();
        });

        Schema::create('pedido_detalles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pedido_id')->constrained('pedidos')->cascadeOnDelete();
            $table->foreignId('producto_presentacion_id')->constrained('producto_presentaciones');
            $table->decimal('cantidad', 12, 2);
            $table->decimal('precio_unitario', 12, 2);
            $table->decimal('descuento', 12, 2)->default(0);
            $table->decimal('subtotal', 12, 2);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pedido_detalles');
        Schema::dropIfExists('pedidos');
    }
};
