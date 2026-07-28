<?php

namespace App\Filament\Resources\CosteoConfigResource\Pages;

use App\Filament\Resources\CosteoConfigResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListCosteoConfigs extends ListRecords
{
    protected static string $resource = CosteoConfigResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()->modalWidth('2xl'),
        ];
    }
}
