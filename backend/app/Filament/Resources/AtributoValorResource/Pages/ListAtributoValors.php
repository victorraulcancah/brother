<?php

namespace App\Filament\Resources\AtributoValorResource\Pages;

use App\Filament\Resources\AtributoValorResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListAtributoValors extends ListRecords
{
    protected static string $resource = AtributoValorResource::class;

    protected function getHeaderActions(): array
    {
        return [Actions\CreateAction::make()];
    }
}
