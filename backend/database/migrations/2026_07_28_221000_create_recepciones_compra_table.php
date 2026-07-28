<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('recepciones_compra', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('orden_compra_id')->nullable();
            $table->unsignedBigInteger('proveedor_id')->nullable();
            $table->foreignId('almacen_id')->constrained('almacenes');
            $table->string('numero_documento')->nullable();
            $table->string('tipo_documento')->nullable();
            $table->timestamp('fecha_recepcion');
            $table->string('estado')->default('parcial');
            $table->foreignId('usuario_recibe_id')->constrained('users');
            $table->text('observaciones')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('recepciones_compra');
    }
};
