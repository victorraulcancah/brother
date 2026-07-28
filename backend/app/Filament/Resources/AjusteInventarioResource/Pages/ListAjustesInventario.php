<?php

namespace App\Filament\Resources\AjusteInventarioResource\Pages;

use App\Filament\Resources\AjusteInventarioResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListAjustesInventario extends ListRecords
{
    protected static string $resource = AjusteInventarioResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()
                ->modalWidth('screen'),
        ];
    }
}
