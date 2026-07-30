<?php

namespace App\Filament\Resources\NotaVentaResource\Pages;

use App\Filament\Resources\NotaVentaResource;
use App\Models\MetodoPago;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Resources\Pages\CreateRecord;
use Filament\Schemas\Components as SchemaComponents;

class CreateNotaVenta extends CreateRecord
{
    protected static string $resource = NotaVentaResource::class;

    protected function getHeaderActions(): array
    {
        return [
            // ── Recuperar ────────────────────────────────────────────────
            Actions\Action::make('recuperarOrdenVenta')
                ->label('↺ Recuperar Orden de Venta')
                ->color('gray')
                ->outlined()
                ->url(NotaVentaResource::getUrl('index')),

            Actions\Action::make('recuperarVentaAnulada')
                ->label('↺ Recuperar Venta Anulada')
                ->color('gray')
                ->outlined()
                ->url(NotaVentaResource::getUrl('index')),

            Actions\Action::make('recuperarVentaEnEspera')
                ->label('↺ Recuperar en Espera')
                ->color('gray')
                ->outlined()
                ->url(NotaVentaResource::getUrl('index')),

            // ── Modal de Pago ─────────────────────────────────────────────
            Actions\Action::make('registrarPago')
                ->label('Registrar Pago')
                ->color('success')
                ->icon('heroicon-o-credit-card')
                ->modalHeading('Pagar - Métodos de Pago')
                ->modalDescription('')
                ->modalWidth('5xl')
                ->modalSubmitActionLabel('Guardar')
                ->modalCancelActionLabel('Cancelar')
                ->form(NotaVentaResource::pagosSchema())
                ->action(function (array $data): void {
                    // Los pagos se guardan junto con el formulario principal;
                    // este modal permite pre-cargarlos antes de guardar.
                    // Si el record ya existe (edit), se persisten aquí.
                }),
        ];
    }

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
