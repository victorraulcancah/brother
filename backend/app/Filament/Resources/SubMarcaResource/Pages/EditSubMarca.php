<?php

namespace App\Filament\Resources\SubMarcaResource\Pages;

use App\Filament\Resources\SubMarcaResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditSubMarca extends EditRecord
{
    protected static string $resource = SubMarcaResource::class;

    protected function getHeaderActions(): array
    {
        return [Actions\DeleteAction::make()];
    }
}
