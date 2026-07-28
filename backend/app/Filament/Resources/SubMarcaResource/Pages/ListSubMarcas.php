<?php

namespace App\Filament\Resources\SubMarcaResource\Pages;

use App\Filament\Resources\SubMarcaResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListSubMarcas extends ListRecords
{
    protected static string $resource = SubMarcaResource::class;

    protected function getHeaderActions(): array
    {
        return [Actions\CreateAction::make()];
    }
}
