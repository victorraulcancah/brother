<?php

namespace App\Filament\Resources\SubCategoriaResource\Pages;

use App\Filament\Resources\SubCategoriaResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListSubCategorias extends ListRecords
{
    protected static string $resource = SubCategoriaResource::class;

    protected function getHeaderActions(): array
    {
        return [Actions\CreateAction::make()];
    }
}
