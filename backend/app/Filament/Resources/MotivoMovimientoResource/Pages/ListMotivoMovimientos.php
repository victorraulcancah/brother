<?php

namespace App\Filament\Resources\MotivoMovimientoResource\Pages;

use App\Filament\Resources\MotivoMovimientoResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\Tabs\Tab;
use Illuminate\Database\Eloquent\Builder;

class ListMotivoMovimientos extends ListRecords
{
    protected static string $resource = MotivoMovimientoResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }

    public function getTabs(): array
    {
        return [
            'todos' => Tab::make('Todos'),
            'entradas' => Tab::make('Entradas')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('tipo', 'entrada')),
            'salidas' => Tab::make('Salidas')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('tipo', 'salida')),
        ];
    }
}
