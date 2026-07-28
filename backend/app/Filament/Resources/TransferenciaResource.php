<?php

namespace App\Filament\Resources;

use App\Filament\Resources\TransferenciaResource\Pages;
use App\Models\Transferencia;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

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
                                                Components\Select::make('producto_id')
                                                    ->label('Producto')
                                                    ->relationship('producto', 'nombre')
                                                    ->searchable()
                                                    ->preload()
                                                    ->required()
                                                    ->live()
                                                    ->afterStateUpdated(fn($set) => $set('producto_variante_id', null)),
                                                Components\Select::make('producto_variante_id')
                                                    ->label('Variante')
                                                    ->relationship('productoVariante', 'sku_variante')
                                                    ->searchable()
                                                    ->preload()
                                                    ->nullable(),
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
                Actions\EditAction::make()->modalWidth('screen'),
                Actions\DeleteAction::make(),
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
