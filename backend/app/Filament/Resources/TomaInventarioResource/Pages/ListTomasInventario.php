<?php

namespace App\Filament\Resources\TomaInventarioResource\Pages;

use App\Filament\Resources\TomaInventarioResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListTomasInventario extends ListRecords
{
    protected static string $resource = TomaInventarioResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()->modalWidth('3xl'),
        ];
    }
}
