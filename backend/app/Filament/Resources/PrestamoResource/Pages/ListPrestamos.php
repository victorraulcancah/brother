<?php

namespace App\Filament\Resources\PrestamoResource\Pages;

use App\Filament\Resources\PrestamoResource;
use App\Models\Almacen;
use App\Models\ProductoPresentacion;
use Filament\Actions\Action;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\Tabs;
use Filament\Schemas\Components\Tabs\Tab;

class ListPrestamos extends ListRecords
{
    protected static string $resource = PrestamoResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Action::make('nuevo_prestamo')
                ->label('Nuevo Préstamo')
                ->icon('heroicon-o-plus')
                ->color('primary')
                ->modalWidth('2xl')
                ->form([
                    Tabs::make('Préstamo')
                        ->tabs([
                            Tab::make('Información')
                                ->icon('heroicon-o-information-circle')
                                ->schema([
                                    Select::make('tipo')
                                        ->label('Tipo')
                                        ->options([
                                            'prestado' => 'Presté (sale stock)',
                                            'recibido' => 'Me prestaron (entra stock)',
                                        ])
                                        ->default('prestado')
                                        ->required(),
                                    TextInput::make('tercero')
                                        ->label('Tercero')
                                        ->required()
                                        ->maxLength(150),
                                    Select::make('almacen_id')
                                        ->label('Almacén')
                                        ->options(fn() => Almacen::where('activo', true)->orderBy('nombre')->pluck('nombre', 'id'))
                                        ->required(),
                                    Textarea::make('observaciones')
                                        ->label('Observación')
                                        ->maxLength(255)
                                        ->columnSpanFull(),
                                ])->columns(2),
                            Tab::make('Productos')
                                ->icon('heroicon-o-cube')
                                ->schema([
                                    Repeater::make('detalles')
                                        ->label('Productos')
                                        ->schema([
                                            Select::make('producto_presentacion_id')
                                                ->label('Producto')
                                                ->options(fn() => ProductoPresentacion::with('producto')->orderBy('nombre')->limit(500)->get()
                                                    ->mapWithKeys(fn($p) => [$p->id => $p->producto->nombre . ' — ' . $p->nombre]))
                                                ->searchable()
                                                ->required()
                                                ->columnSpan(2),
                                            TextInput::make('cantidad')
                                                ->label('Cantidad')
                                                ->numeric()
                                                ->minValue(0.01)
                                                ->required(),
                                        ])
                                        ->columns(3)
                                        ->minItems(1)
                                        ->defaultItems(1)
                                        ->addActionLabel('Agregar Producto'),
                                ]),
                        ])->columnSpanFull(),
                ])
                ->action(function (array $data): void {
                    try {
                        $prestamo = PrestamoResource::crearPrestamo($data);
                        Notification::make()->success()
                            ->title("Préstamo #{$prestamo->id} registrado")
                            ->send();
                    } catch (\Throwable $e) {
                        Notification::make()->danger()->title('Error en préstamo')->body($e->getMessage())->send();
                    }
                }),
        ];
    }
}
