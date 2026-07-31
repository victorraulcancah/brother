<?php

namespace App\Filament\Resources;

use App\Filament\Resources\TransferenciaResource\Pages;
use App\Models\Transferencia;
use App\Services\StockService;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Notifications\Notification;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Facades\DB;

class TransferenciaResource extends Resource
{
    protected static ?string $model = Transferencia::class;

    public static function getNavigationIcon(): string
    {
        return 'heroicon-o-arrow-path';
    }

    public static function getNavigationLabel(): string
    {
        return 'Transferencias';
    }

    public static function getPluralModelLabel(): string
    {
        return 'Transferencias';
    }

    public static function getSlug(?Panel $panel = null): string
    {
        return 'transferencias';
    }

    public static function getNavigationGroup(): string
    {
        return 'Inventario';
    }

    public static function getNavigationSort(): ?int
    {
        return 3;
    }

    public static function getNavigationBadge(): ?string
    {
        return (string) static::getModel()::count();
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Tabs::make('Transferencia')
                    ->tabs([
                        SchemaComponents\Tabs\Tab::make('Información')
                            ->icon('heroicon-o-information-circle')
                            ->schema([
                                SchemaComponents\Section::make('Datos de la Transferencia')
                                    ->schema([
                                        Components\Select::make('almacen_origen_id')
                                            ->label('Almacén Origen')
                                            ->relationship('almacenOrigen', 'nombre')
                                            ->searchable()
                                            ->preload()
                                            ->required(),
                                        Components\Select::make('almacen_destino_id')
                                            ->label('Almacén Destino')
                                            ->relationship('almacenDestino', 'nombre')
                                            ->searchable()
                                            ->preload()
                                            ->required(),
                                        Components\Select::make('estado')
                                            ->label('Estado')
                                            ->options([
                                                'pendiente' => 'Pendiente',
                                                'en_transito' => 'En Tránsito',
                                                'recibido' => 'Recibido',
                                                'anulado' => 'Anulado',
                                            ])
                                            ->required(),
                                        Components\DateTimePicker::make('fecha_envio')
                                            ->label('Fecha de Envío'),
                                        Components\DateTimePicker::make('fecha_recepcion')
                                            ->label('Fecha de Recepción'),
                                        Components\Textarea::make('observaciones')
                                            ->label('Observaciones')
                                            ->maxLength(5000)
                                            ->columnSpanFull(),
                                    ])->columns(2),
                            ]),
                        SchemaComponents\Tabs\Tab::make('Productos')
                            ->icon('heroicon-o-cube')
                            ->schema([
                                Components\Repeater::make('detalles')
                                    ->relationship('detalles')
                                    ->schema([
                                        SchemaComponents\Grid::make(3)
                                            ->schema([
                                                Components\Select::make('producto_presentacion_id')
                                                    ->label('Producto / Presentación')
                                                    ->relationship('presentacion', 'nombre')
                                                    ->getOptionLabelFromRecordUsing(fn($record) => trim(($record->producto?->nombre ?? '') . ' — ' . $record->nombre, ' —'))
                                                    ->searchable()
                                                    ->preload()
                                                    ->required()
                                                    ->columnSpan(2),
                                                Components\TextInput::make('cantidad_enviada')
                                                    ->label('Cantidad Enviada')
                                                    ->numeric()
                                                    ->required()
                                                    ->default(0),
                                            ]),
                                    ])
                                    ->defaultItems(0)
                                    ->addActionLabel('Agregar Producto')
                                    ->collapsible()
                                    ->cloneable(),
                            ]),
                    ])->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('#')
                    ->sortable(),
                Tables\Columns\TextColumn::make('almacenOrigen.nombre')
                    ->label('Origen')
                    ->sortable(),
                Tables\Columns\TextColumn::make('almacenDestino.nombre')
                    ->label('Destino')
                    ->sortable(),
                Tables\Columns\TextColumn::make('estado')
                    ->label('Estado')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'pendiente' => 'warning',
                        'en_transito' => 'info',
                        'recibido' => 'success',
                        'anulado' => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('fecha_envio')
                    ->label('Fecha Envío')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('fecha_recepcion')
                    ->label('Fecha Recepción')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Creado')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('estado')
                    ->label('Estado')
                    ->options([
                        'pendiente' => 'Pendiente',
                        'en_transito' => 'En Tránsito',
                        'recibido' => 'Recibido',
                        'anulado' => 'Anulado',
                    ]),
            ])
            ->actions([
                Actions\Action::make('enviar')
                    ->label('Enviar')
                    ->icon('heroicon-o-arrow-up-tray')
                    ->color('info')
                    ->visible(fn(Transferencia $record): bool => $record->estado === 'pendiente')
                    ->requiresConfirmation()
                    ->modalDescription('Se descontará la cantidad enviada de cada línea del almacén de origen.')
                    ->action(function (Transferencia $record): void {
                        try {
                            DB::transaction(function () use ($record): void {
                                $record->loadMissing(['detalles.presentacion', 'almacenOrigen']);

                                foreach ($record->detalles as $detalle) {
                                    $cantidad = (float) $detalle->cantidad_enviada;
                                    if ($cantidad <= 0 || ! $detalle->presentacion) {
                                        continue;
                                    }

                                    app(StockService::class)->salida(
                                        presentacion: $detalle->presentacion,
                                        almacen: $record->almacenOrigen,
                                        cantidadPresentacion: $cantidad,
                                        costoUnitario: 0,
                                        origen: 'transferencia',
                                        documentoTipo: 'transferencia',
                                        documentoId: $record->id,
                                        usuarioId: auth()->id(),
                                    );
                                }

                                $record->update([
                                    'estado' => 'en_transito',
                                    'fecha_envio' => now(),
                                    'usuario_envio_id' => auth()->id(),
                                ]);
                            });

                            Notification::make()->success()->title('Transferencia enviada')->body('Se descontó el stock del almacén de origen.')->send();
                        } catch (\Throwable $e) {
                            Notification::make()->danger()->title('No se pudo enviar')->body($e->getMessage())->send();
                        }
                    }),
                Actions\Action::make('recibir')
                    ->label('Recibir')
                    ->icon('heroicon-o-arrow-down-tray')
                    ->color('success')
                    ->visible(fn(Transferencia $record): bool => $record->estado === 'en_transito')
                    ->form(fn(Transferencia $record): array => $record->detalles
                        ->map(fn($detalle) => Components\TextInput::make("cantidad_{$detalle->id}")
                            ->label(trim(($detalle->presentacion?->producto?->nombre ?? 'Producto') . ' — ' . ($detalle->presentacion?->nombre ?? '')))
                            ->numeric()
                            ->minValue(0)
                            ->default($detalle->cantidad_enviada)
                            ->helperText("Enviado: {$detalle->cantidad_enviada}")
                            ->required())
                        ->all())
                    ->action(function (Transferencia $record, array $data): void {
                        try {
                            DB::transaction(function () use ($record, $data): void {
                                $record->loadMissing(['detalles.presentacion', 'almacenDestino']);

                                foreach ($record->detalles as $detalle) {
                                    $cantidad = (float) ($data["cantidad_{$detalle->id}"] ?? 0);
                                    $detalle->update(['cantidad_recibida' => $cantidad]);

                                    if ($cantidad <= 0 || ! $detalle->presentacion) {
                                        continue;
                                    }

                                    app(StockService::class)->entrada(
                                        presentacion: $detalle->presentacion,
                                        almacen: $record->almacenDestino,
                                        cantidadPresentacion: $cantidad,
                                        costoUnitario: 0,
                                        origen: 'transferencia',
                                        documentoTipo: 'transferencia',
                                        documentoId: $record->id,
                                        usuarioId: auth()->id(),
                                    );
                                }

                                $record->update([
                                    'estado' => 'recibido',
                                    'fecha_recepcion' => now(),
                                    'usuario_recepcion_id' => auth()->id(),
                                ]);
                            });

                            Notification::make()->success()->title('Transferencia recibida')->body('Se agregó el stock al almacén de destino.')->send();
                        } catch (\Throwable $e) {
                            Notification::make()->danger()->title('No se pudo recibir')->body($e->getMessage())->send();
                        }
                    }),
                Actions\Action::make('anular')
                    ->label('Anular')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->visible(fn(Transferencia $record): bool => $record->estado === 'pendiente')
                    ->requiresConfirmation()
                    ->action(fn(Transferencia $record) => $record->update(['estado' => 'anulado'])),
                Actions\EditAction::make()
                    ->modalWidth('3xl')
                    ->visible(fn(Transferencia $record): bool => $record->estado === 'pendiente'),
                Actions\DeleteAction::make()
                    ->visible(fn(Transferencia $record): bool => $record->estado === 'pendiente'),
            ])
            ->bulkActions([
                Actions\BulkActionGroup::make([
                    Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListTransferencias::route('/'),
        ];
    }
}
