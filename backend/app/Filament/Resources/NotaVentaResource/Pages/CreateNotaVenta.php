<?php

namespace App\Filament\Resources\NotaVentaResource\Pages;

use App\Filament\Resources\NotaVentaResource;
use Filament\Resources\Pages\CreateRecord;

class CreateNotaVenta extends CreateRecord
{
    protected static string $resource = NotaVentaResource::class;

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
