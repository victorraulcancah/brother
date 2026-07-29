<?php

namespace App\Filament\Resources\AjusteInventarioResource\Pages;

use App\Filament\Resources\AjusteInventarioResource;
use App\Livewire\MotivosTable;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\EmbeddedTable;
use Filament\Schemas\Components\Livewire;
use Filament\Schemas\Components\Tabs;
use Filament\Schemas\Components\Tabs\Tab;
use Filament\Schemas\Schema;

class ListAjustesInventario extends ListRecords
{
    protected static string $resource = AjusteInventarioResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()
                ->modalWidth('3xl'),
        ];
    }

    /** Dos pestañas en la misma página: Ajustes y Motivos. */
    public function content(Schema $schema): Schema
    {
        return $schema->components([
            Tabs::make()
                ->tabs([
                    Tab::make('Ajustes')
                        ->icon('heroicon-o-adjustments-horizontal')
                        ->schema([
                            EmbeddedTable::make(),
                        ]),
                    Tab::make('Motivos')
                        ->icon('heroicon-o-tag')
                        ->schema([
                            Livewire::make(MotivosTable::class),
                        ]),
                ]),
        ]);
    }
}
