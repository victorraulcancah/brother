<?php

namespace App\Filament\Resources\SubCategoriaResource\Pages;

use App\Filament\Resources\SubCategoriaResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditSubCategoria extends EditRecord
{
    protected static string $resource = SubCategoriaResource::class;

    protected function getHeaderActions(): array
    {
        return [Actions\DeleteAction::make()];
    }
}
