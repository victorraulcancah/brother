<?php

namespace App\Filament\Resources\TransferenciaResource\Pages;

use App\Filament\Resources\TransferenciaResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListTransferencias extends ListRecords
{
    protected static string $resource = TransferenciaResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()
                ->modalWidth('screen'),
        ];
    }
}
