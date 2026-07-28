<?php

namespace App\Filament\Resources\CategoriaResource\Pages;

use App\Filament\Resources\CategoriaResource;
use App\Filament\Resources\SubCategoriaResource;
use App\Models\SubCategoria;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\Tabs\Tab;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class ListCategorias extends ListRecords
{
    protected static string $resource = CategoriaResource::class;

    protected function getHeaderActions(): array
    {
        if ($this->activeTab === 'subcategorias') {
            return [
                Actions\Action::make('createSubCategoria')
                    ->label('Crear Sub Categoría')
                    ->icon('heroicon-o-plus')
                    ->modalHeading('Crear Sub Categoría')
                    ->modalWidth('2xl')
                    ->schema([
                        Components\Select::make('categoria_id')
                            ->label('Categoría')
                            ->relationship('categoria', 'nombre')
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
                    ->action(fn (array $data) => SubCategoria::create($data)),
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
            'categorias' => Tab::make('Categorías')
                ->icon('heroicon-o-rectangle-group'),
            'subcategorias' => Tab::make('Sub Categorías')
                ->icon('heroicon-o-rectangle-stack'),
        ];
    }

    protected function makeTable(): Table
    {
        if ($this->activeTab === 'subcategorias') {
            $table = Table::make($this)
                ->query(fn (): Builder => SubCategoria::query())
                ->modelLabel('Sub Categoría')
                ->pluralModelLabel('Sub Categorías');

            SubCategoriaResource::configureTable($table);

            return $table;
        }

        return parent::makeTable();
    }
}
