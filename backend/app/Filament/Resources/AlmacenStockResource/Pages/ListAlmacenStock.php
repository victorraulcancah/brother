<?php

namespace App\Filament\Resources\AlmacenStockResource\Pages;

use App\Filament\Resources\AlmacenStockResource;
use App\Filament\Resources\AlmacenStockResource\Widgets\AlmacenStockStats;
use App\Models\Almacen;
use App\Models\MovimientoInventario;
use App\Models\ProductoPresentacion;
use App\Models\ProductoAlmacenStock;
use Filament\Actions\Action;
use Filament\Actions\ActionGroup;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\EmbeddedTable;
use Filament\Schemas\Components\Livewire;
use Filament\Schemas\Components\Tabs\Tab;
use Filament\Schemas\Schema;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;

class ListAlmacenStock extends ListRecords
{
    protected static string $resource = AlmacenStockResource::class;

    /** Orden: pestañas arriba, tarjetas KPI debajo, tabla al final. */
    public function content(Schema $schema): Schema
    {
        return $schema->components([
            $this->getTabsContentComponent(),
            Livewire::make(AlmacenStockStats::class),
            EmbeddedTable::make(),
        ]);
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

            Select::make('producto_presentacion_id')
                ->label('Presentación')
                ->options(fn () => ProductoPresentacion::with('producto')->orderBy('nombre')->limit(500)->get()->mapWithKeys(fn ($p) => [$p->id => $p->producto->nombre . ' — ' . $p->nombre])->toArray())
                ->searchable()
                ->required(),

            TextInput::make('cantidad')
                ->label('Cantidad (en unidades de la presentación)')
                ->numeric()
                ->minValue(0.01)
                ->required(),

            TextInput::make('observacion')
                ->label('Observaciones')
                ->maxLength(255),
        ];
    }

    /**
     * Convierte la presentación a unidad base (cantidad × factor) y actualiza
     * el stock del PRODUCTO en el almacén. El Kardex se guarda en unidad base.
     */
    protected function registrarMovimiento(array $data, string $tipo): void
    {
        DB::transaction(function () use ($data, $tipo): void {
            $presentacion = ProductoPresentacion::findOrFail($data['producto_presentacion_id']);
            $productoId = $presentacion->producto_id;
            $factor = (float) $presentacion->factor_conversion ?: 1;
            $base = (float) $data['cantidad'] * $factor;

            $stock = ProductoAlmacenStock::firstOrCreate(
                [
                    'producto_id' => $productoId,
                    'almacen_id' => $data['almacen_id'],
                ],
                ['stock_actual' => 0],
            );

            $anterior = (float) $stock->stock_actual;

            if ($tipo === 'salida' && $base > $anterior) {
                throw new \RuntimeException("Stock insuficiente. Disponible: {$anterior} (u. base).");
            }

            $nuevo = $tipo === 'entrada' ? $anterior + $base : $anterior - $base;
            $stock->update([
                'stock_actual' => $nuevo,
                'stock_disponible' => $nuevo - (float) $stock->stock_reservado,
            ]);

            MovimientoInventario::create([
                'almacen_id' => $data['almacen_id'],
                'producto_id' => $productoId,
                'tipo_movimiento' => $tipo,
                'origen' => $data['observacion'] ?: ($tipo === 'entrada' ? 'Ingreso manual' : 'Salida manual'),
                'cantidad' => $base,
                'costo_unitario' => 0,
                'stock_anterior' => $anterior,
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
