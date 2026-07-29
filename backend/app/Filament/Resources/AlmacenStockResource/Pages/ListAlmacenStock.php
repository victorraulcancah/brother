<?php

namespace App\Filament\Resources\AlmacenStockResource\Pages;

use App\Filament\Resources\AlmacenStockResource;
use App\Filament\Resources\AlmacenStockResource\Widgets\AlmacenStockStats;
use App\Models\Almacen;
use App\Models\MovimientoInventario;
use App\Models\Producto;
use App\Models\ProductoAlmacenStock;
use Filament\Actions\Action;
use Filament\Actions\ActionGroup;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\Tabs\Tab;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;

class ListAlmacenStock extends ListRecords
{
    protected static string $resource = AlmacenStockResource::class;

    protected function getHeaderWidgets(): array
    {
        return [
            AlmacenStockStats::class,
        ];
    }

    protected function almacenes()
    {
        return Almacen::where('activo', true)->orderBy('nombre')->get();
    }

    public function getTabs(): array
    {
        $tabs = [];

        foreach ($this->almacenes() as $almacen) {
            $tabs['alm-' . $almacen->id] = Tab::make($almacen->nombre)
                ->modifyQueryUsing(fn (Builder $query) => $query->where('almacen_id', $almacen->id));
        }

        $tabs['todos'] = Tab::make('Todos');

        return $tabs;
    }

    /** Formulario de ingreso/salida de stock. */
    protected function movimientoForm(): array
    {
        return [
            Select::make('almacen_id')
                ->label('Almacén')
                ->options(fn () => $this->almacenes()->pluck('nombre', 'id')->toArray())
                ->required(),

            Select::make('producto_id')
                ->label('Producto')
                ->options(fn () => Producto::orderBy('nombre')->limit(500)->pluck('nombre', 'id')->toArray())
                ->searchable()
                ->required(),

            TextInput::make('cantidad')
                ->label('Cantidad')
                ->numeric()
                ->integer()
                ->minValue(1)
                ->required(),

            TextInput::make('observacion')
                ->label('Observaciones')
                ->maxLength(255),
        ];
    }

    /** Registra el movimiento y actualiza el stock del producto en el almacén. */
    protected function registrarMovimiento(array $data, string $tipo): void
    {
        DB::transaction(function () use ($data, $tipo): void {
            $stock = ProductoAlmacenStock::firstOrCreate(
                [
                    'producto_id' => $data['producto_id'],
                    'almacen_id' => $data['almacen_id'],
                ],
                ['stock_actual' => 0],
            );

            $anterior = (int) $stock->stock_actual;
            $cant = (int) $data['cantidad'];

            if ($tipo === 'salida' && $cant > $anterior) {
                throw new \RuntimeException("Stock insuficiente en ese almacén. Disponible: {$anterior}.");
            }

            $nuevo = $tipo === 'entrada' ? $anterior + $cant : $anterior - $cant;
            $stock->update(['stock_actual' => $nuevo]);

            MovimientoInventario::create([
                'almacen_id' => $data['almacen_id'],
                'producto_id' => $data['producto_id'],
                'tipo_movimiento' => $tipo,
                'origen' => $data['observacion'] ?: ($tipo === 'entrada' ? 'Ingreso manual' : 'Salida manual'),
                'cantidad' => $cant,
                'costo_unitario' => 0,
                'saldo_stock' => $nuevo,
                'fecha' => now(),
                'usuario_id' => auth()->id(),
            ]);
        });
    }

    protected function getHeaderActions(): array
    {
        return [
            Action::make('ingreso')
                ->label('Ingreso')
                ->icon('heroicon-o-arrow-down-tray')
                ->color('success')
                ->form($this->movimientoForm())
                ->action(function (array $data): void {
                    try {
                        $this->registrarMovimiento($data, 'entrada');
                        Notification::make()->success()->title('Ingreso registrado')->send();
                    } catch (\Throwable $e) {
                        Notification::make()->danger()->title('Error')->body($e->getMessage())->send();
                    }
                }),

            Action::make('salida')
                ->label('Salida')
                ->icon('heroicon-o-arrow-up-tray')
                ->color('danger')
                ->form($this->movimientoForm())
                ->action(function (array $data): void {
                    try {
                        $this->registrarMovimiento($data, 'salida');
                        Notification::make()->success()->title('Salida registrada')->send();
                    } catch (\Throwable $e) {
                        Notification::make()->danger()->title('Error')->body($e->getMessage())->send();
                    }
                }),

            ActionGroup::make([
                Action::make('nuevo_almacen')
                    ->label('Nuevo Almacén')
                    ->icon('heroicon-o-plus')
                    ->form([
                        TextInput::make('nombre')->label('Nombre')->required()->maxLength(255),
                        TextInput::make('codigo')->label('Código')->required()->maxLength(50),
                        TextInput::make('direccion')->label('Descripción')->maxLength(500),
                    ])
                    ->action(function (array $data): void {
                        Almacen::create([
                            'nombre' => $data['nombre'],
                            'codigo' => $data['codigo'],
                            'direccion' => $data['direccion'] ?? null,
                            'tipo' => 'principal',
                            'activo' => true,
                        ]);
                        Notification::make()->success()->title('Almacén creado')->send();
                    }),

                Action::make('editar_almacen')
                    ->label('Editar Almacén')
                    ->icon('heroicon-o-pencil')
                    ->form(fn (): array => [
                        Select::make('id')
                            ->label('Almacén')
                            ->options($this->almacenes()->pluck('nombre', 'id')->toArray())
                            ->live()
                            ->afterStateUpdated(function ($state, callable $set): void {
                                $a = Almacen::find($state);
                                $set('nombre', $a?->nombre);
                                $set('direccion', $a?->direccion);
                            })
                            ->required(),
                        TextInput::make('nombre')->label('Nombre')->required()->maxLength(255),
                        TextInput::make('direccion')->label('Descripción')->maxLength(500),
                    ])
                    ->action(function (array $data): void {
                        Almacen::whereKey($data['id'])->update([
                            'nombre' => $data['nombre'],
                            'direccion' => $data['direccion'] ?? null,
                        ]);
                        Notification::make()->success()->title('Almacén actualizado')->send();
                    }),

                Action::make('desactivar_almacen')
                    ->label('Desactivar Almacén')
                    ->icon('heroicon-o-trash')
                    ->color('danger')
                    ->form(fn (): array => [
                        Select::make('id')
                            ->label('Almacén')
                            ->options($this->almacenes()->pluck('nombre', 'id')->toArray())
                            ->required(),
                    ])
                    ->requiresConfirmation()
                    ->modalDescription('El almacén se desactivará. Los productos y movimientos históricos se conservan.')
                    ->action(function (array $data): void {
                        Almacen::whereKey($data['id'])->update(['activo' => false]);
                        Notification::make()->success()->title('Almacén desactivado')->send();
                    }),
            ])
                ->label('Almacenes')
                ->icon('heroicon-o-building-storefront')
                ->button()
                ->color('gray'),
        ];
    }
}
