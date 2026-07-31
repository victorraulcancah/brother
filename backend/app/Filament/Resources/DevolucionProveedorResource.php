<?php

namespace App\Filament\Resources;

use App\Filament\Resources\DevolucionProveedorResource\Pages;
use App\Models\DevolucionProveedor;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class DevolucionProveedorResource extends Resource
{
    protected static ?string $model = DevolucionProveedor::class;
    protected static bool $shouldRegisterNavigation = false;

    public static function getNavigationIcon(): string { return 'heroicon-o-arrow-uturn-left'; }
    public static function getNavigationLabel(): string { return 'Devoluciones'; }
    public static function getPluralModelLabel(): string { return 'Devoluciones a Proveedor'; }
    public static function getSlug(?Panel $panel = null): string { return 'devoluciones-proveedor'; }
    public static function getNavigationGroup(): string { return 'Inventario'; }
    public static function getNavigationSort(): ?int { return 8; }
    public static function getNavigationBadge(): ?string { return (string) static::getModel()::count(); }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Tabs::make('Devolución')
                    ->tabs([
                        SchemaComponents\Tabs\Tab::make('Información')
                            ->icon('heroicon-o-information-circle')
                            ->schema([
                                SchemaComponents\Section::make('Datos de la Devolución')
                                    ->schema([
                                        Components\Select::make('recepcion_compra_id')
                                            ->label('Recepción de Compra')
                                            ->relationship('recepcionCompra', 'id')
                                            ->searchable()
                                            ->preload()
                                            ->required(),
                                        Components\Select::make('almacen_id')
                                            ->label('Almacén')
                                            ->relationship('almacen', 'nombre')
                                            ->searchable()
                                            ->preload()
                                            ->required(),
                                        Components\Select::make('motivo')
                                            ->label('Motivo')
                                            ->options([
                                                'producto_malogrado' => 'Producto Malogrado',
                                                'producto_equivocado' => 'Producto Equivocado',
                                                'exceso_cantidad' => 'Exceso de Cantidad',
                                                'defecto_fabricacion' => 'Defecto de Fabricación',
                                                'vencimiento' => 'Próximo a Vencer',
                                                'otro' => 'Otro',
                                            ])
                                            ->required(),
                                        Components\Select::make('estado')
                                            ->label('Estado')
                                            ->options([
                                                'pendiente_reemplazo' => 'Pendiente de Reemplazo',
                                                'reembolsado' => 'Reembolsado',
                                                'cerrado' => 'Cerrado',
                                            ])
                                            ->required(),
                                        Components\DateTimePicker::make('fecha')
                                            ->label('Fecha')
                                            ->required(),
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
                                                Components\TextInput::make('cantidad')
                                                    ->label('Cantidad')
                                                    ->numeric()
                                                    ->required()
                                                    ->default(0),
                                                Components\TextInput::make('costo_unitario')
                                                    ->label('Costo Unitario')
                                                    ->numeric()
                                                    ->default(0)
                                                    ->prefix('S/'),
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
                Tables\Columns\TextColumn::make('recepcionCompra.id')
                    ->label('Recepción #')
                    ->sortable(),
                Tables\Columns\TextColumn::make('almacen.nombre')
                    ->label('Almacén')
                    ->sortable(),
                Tables\Columns\TextColumn::make('motivo')
                    ->label('Motivo')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'producto_malogrado' => 'danger',
                        'producto_equivocado' => 'warning',
                        'exceso_cantidad' => 'info',
                        'defecto_fabricacion' => 'danger',
                        'vencimiento' => 'warning',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('estado')
                    ->label('Estado')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'pendiente_reemplazo' => 'warning',
                        'reembolsado' => 'info',
                        'cerrado' => 'success',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('fecha')
                    ->label('Fecha')
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
                        'pendiente_reemplazo' => 'Pendiente de Reemplazo',
                        'reembolsado' => 'Reembolsado',
                        'cerrado' => 'Cerrado',
                    ]),
                Tables\Filters\SelectFilter::make('motivo')
                    ->label('Motivo')
                    ->options([
                        'producto_malogrado' => 'Producto Malogrado',
                        'producto_equivocado' => 'Producto Equivocado',
                        'exceso_cantidad' => 'Exceso de Cantidad',
                        'defecto_fabricacion' => 'Defecto de Fabricación',
                        'vencimiento' => 'Próximo a Vencer',
                        'otro' => 'Otro',
                    ]),
            ])
            ->actions([
                Actions\EditAction::make()->modalWidth('3xl'),
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
            'index' => Pages\ListDevolucionesProveedor::route('/'),
        ];
    }
}
