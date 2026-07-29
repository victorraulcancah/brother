<?php

namespace App\Filament\Resources\RecepcionCompraResource\Pages;

use App\Filament\Resources\RecepcionCompraResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListRecepcionesCompra extends ListRecords
{
    protected static string $resource = RecepcionCompraResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()->modalWidth('3xl'),
        ];
    }
}
