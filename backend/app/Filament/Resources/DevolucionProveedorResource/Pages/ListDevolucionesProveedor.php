<?php

namespace App\Filament\Resources\DevolucionProveedorResource\Pages;

use App\Filament\Resources\DevolucionProveedorResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListDevolucionesProveedor extends ListRecords
{
    protected static string $resource = DevolucionProveedorResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()->modalWidth('screen'),
        ];
    }
}
