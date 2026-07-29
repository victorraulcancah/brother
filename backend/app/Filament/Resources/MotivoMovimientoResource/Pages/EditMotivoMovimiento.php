<?php

namespace App\Filament\Resources\MotivoMovimientoResource\Pages;

use App\Filament\Resources\MotivoMovimientoResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditMotivoMovimiento extends EditRecord
{
    protected static string $resource = MotivoMovimientoResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make()
                ->visible(fn (): bool => ! $this->getRecord()->es_sistema),
        ];
    }
}
