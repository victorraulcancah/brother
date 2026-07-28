<?php

namespace App\Filament\Resources\MarcaResource\Pages;

use App\Filament\Resources\MarcaResource;
use App\Filament\Resources\SubMarcaResource;
use App\Models\Marca;
use App\Models\SubMarca;
use Filament\Actions;
use Filament\Resources\Pages\Page;
use Filament\Tables\Table;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;

class ListMarcas extends Page implements HasTable
{
    use InteractsWithTable;

    protected static string $resource = MarcaResource::class;

    public function getView(): string
    {
        return 'filament.pages.list-marcas';
    }

    public string $tab = 'marcas';

    public function getTable(): Table
    {
        if ($this->tab === 'submarcas') {
            return SubMarcaResource::table(
                Table::make($this)
                    ->query(SubMarca::query())
            );
        }

        return MarcaResource::table(
            Table::make($this)
                ->query(Marca::query())
        );
    }

    public function getHeading(): string
    {
        return $this->tab === 'submarcas' ? 'Submarcas' : 'Marcas';
    }

    protected function getHeaderActions(): array
    {
        if ($this->tab === 'submarcas') {
            return [
                Actions\CreateAction::make()
                    ->resource(SubMarcaResource::class)
                    ->modalWidth('2xl'),
            ];
        }

        return [
            Actions\CreateAction::make()
                ->modalWidth('2xl'),
        ];
    }
}
