<?php

namespace App\Filament\Resources\NotaVentaResource\Pages;

use App\Filament\Resources\NotaVentaResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListNotasVenta extends ListRecords
{
    protected static string $resource = NotaVentaResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()
                ->url(fn (): string => NotaVentaResource::getUrl('create')),
        ];
    }
}
