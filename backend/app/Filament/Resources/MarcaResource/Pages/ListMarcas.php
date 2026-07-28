<?php

namespace App\Filament\Resources\MarcaResource\Pages;

use App\Filament\Resources\MarcaResource;
use App\Filament\Resources\SubMarcaResource;
use App\Models\SubMarca;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\Tabs\Tab;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class ListMarcas extends ListRecords
{
    protected static string $resource = MarcaResource::class;

    protected function getHeaderActions(): array
    {
        if ($this->activeTab === 'submarcas') {
            return [
                Actions\Action::make('createSubMarca')
                    ->label('Crear Submarca')
                    ->icon('heroicon-o-plus')
                    ->modalHeading('Crear Submarca')
                    ->modalWidth('2xl')
                    ->schema([
                        Components\Select::make('marca_id')
                            ->label('Marca')
                            ->relationship('marca', 'nombre')
                            ->searchable()
                            ->preload()
                            ->required(),
                        Components\TextInput::make('nombre')
                            ->label('Nombre')
                            ->required()
                            ->maxLength(255),
                        Components\Toggle::make('activo')
                            ->label('Activo')
                            ->default(true),
                    ])
                    ->action(fn (array $data) => SubMarca::create($data)),
            ];
        }

        return [
            Actions\CreateAction::make()
                ->modalWidth('2xl'),
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
