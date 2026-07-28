<?php

namespace App\Filament\Resources\MarcaResource\Pages;

use App\Filament\Resources\MarcaResource;
use App\Filament\Resources\SubMarcaResource;
use App\Models\SubMarca;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\Tabs\Tab;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class ListMarcas extends ListRecords
{
    protected static string $resource = MarcaResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()
                ->modalWidth('2xl')
                ->visible(fn (): bool => $this->activeTab !== 'submarcas'),
        ];
    }

    public function getTabs(): array
    {
        return [
            'marcas' => Tab::make('Marcas')
                ->icon('heroicon-o-tag'),
            'submarcas' => Tab::make('Submarcas')
                ->icon('heroicon-o-circle-stack'),
        ];
    }

    protected function makeTable(): Table
    {
        if ($this->activeTab === 'submarcas') {
            $table = Table::make($this)
                ->query(fn (): Builder => SubMarca::query())
                ->modelLabel('Submarca')
                ->pluralModelLabel('Submarcas');

            SubMarcaResource::configureTable($table);

            return $table;
        }

        return parent::makeTable();
    }
}
