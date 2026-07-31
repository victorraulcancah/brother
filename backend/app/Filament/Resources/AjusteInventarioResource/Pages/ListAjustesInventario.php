<?php

namespace App\Filament\Resources\AjusteInventarioResource\Pages;

use App\Filament\Resources\AjusteInventarioResource;
use App\Livewire\MotivosTable;
use App\Models\ProductoAlmacenStock;
use App\Models\ProductoPresentacion;
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
                ->modalWidth('3xl')
                ->mutateFormDataUsing(function (array $data): array {
                    $data['estado'] = 'pendiente';
                    $data['fecha'] = now();

                    foreach ($data['detalles'] ?? [] as $i => $detalle) {
                        $productoId = ProductoPresentacion::find($detalle['producto_presentacion_id'])?->producto_id;
                        $stock = ProductoAlmacenStock::where('producto_id', $productoId)
                            ->where('almacen_id', $data['almacen_id'])
                            ->value('stock_actual') ?? 0;
                        $data['detalles'][$i]['cantidad_sistema'] = $stock;
                        $data['detalles'][$i]['diferencia'] = $detalle['cantidad_fisica'] - $stock;
                    }

                    return $data;
                }),
        ];
    }

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
