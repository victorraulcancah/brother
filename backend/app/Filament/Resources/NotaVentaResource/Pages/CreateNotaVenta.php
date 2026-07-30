<?php

namespace App\Filament\Resources\NotaVentaResource\Pages;

use App\Filament\Resources\NotaVentaResource;
use Filament\Actions;
use Filament\Resources\Pages\CreateRecord;

class CreateNotaVenta extends CreateRecord
{
    protected static string $resource = NotaVentaResource::class;

    protected function getActions(): array
    {
        return array_merge(parent::getActions(), [
            Actions\Action::make('recuperarOrdenVenta')
                ->label('↺ Recuperar Orden de Venta')
                ->url(NotaVentaResource::getUrl('index')),
            Actions\Action::make('recuperarVentaAnulada')
                ->label('↺ Recuperar Venta Anulada')
                ->url(NotaVentaResource::getUrl('index')),
            Actions\Action::make('recuperarVentaEnEspera')
                ->label('↺ Recuperar Venta en Espera')
                ->url(NotaVentaResource::getUrl('index')),
        ]);
    }

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
