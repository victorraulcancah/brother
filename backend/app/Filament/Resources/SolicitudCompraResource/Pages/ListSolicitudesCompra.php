<?php

namespace App\Filament\Resources\SolicitudCompraResource\Pages;

use App\Filament\Resources\SolicitudCompraResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListSolicitudesCompra extends ListRecords
{
    protected static string $resource = SolicitudCompraResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()->modalWidth('3xl'),
        ];
    }
}
