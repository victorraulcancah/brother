<?php

namespace App\Filament\Resources;

use App\Filament\Resources\RecepcionCompraResource\Pages;
use App\Models\RecepcionCompra;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class RecepcionCompraResource extends Resource
{
    protected static ?string $model = RecepcionCompra::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-truck'; }
    public static function getNavigationLabel(): string { return 'Recepciones'; }
    public static function getPluralModelLabel(): string { return 'Recepciones de Compra'; }
    public static function getSlug(?Panel $panel = null): string { return 'recepciones-compra'; }
    public static function getNavigationGroup(): string { return 'Compras'; }
    public static function getNavigationSort(): ?int { return 6; }
    public static function getNavigationBadge(): ?string { return (string) static::getModel()::count(); }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Tabs::make('Recepción')
                    ->tabs([
                        SchemaComponents\Tabs\Tab::make('Información')
                            ->icon('heroicon-o-information-circle')
                            ->schema([
                                SchemaComponents\Section::make('Datos de la Recepción')
                                    ->schema([
                                        Components\Select::make('orden_compra_id')
                                            ->label('Orden de Compra')
                                            ->relationship('ordenCompra', 'codigo')
                                            ->searchable()
                                            ->preload()
                                            ->nullable(),
                                        Components\Select::make('proveedor_id')
                                            ->label('Proveedor')
                                            ->relationship('proveedor', 'nombre')
                                            ->searchable()
                                            ->preload()
                                            ->nullable(),
                                        Components\Select::make('almacen_id')
                                            ->label('Almacén')
                                            ->relationship('almacen', 'nombre')
                                            ->searchable()
                                            ->preload()
                                            ->required(),
                                        Components\TextInput::make('numero_documento')
                                            ->label('N° Documento')
                                            ->maxLength(255),
                                        Components\Select::make('tipo_documento')
                                            ->label('Tipo Documento')
                                            ->options([
                                                'guia_remision' => 'Guía de Remisión',
                                                'factura' => 'Factura',
                                            ]),
                                        Components\DateTimePicker::make('fecha_recepcion')
                                            ->label('Fecha de Recepción')
                                            ->required(),
                                        Components\Select::make('estado')
                                            ->label('Estado')
                                            ->options([
                                                'parcial' => 'Parcial',
                                                'completa' => 'Completa',
                                                'con_discrepancia' => 'Con Discrepancia',
                                                'anulada' => 'Anulada',
                                            ])
                                            ->required(),
                                        Components\Select::make('usuario_recibe_id')
                                            ->label('Recibido por')
                                            ->relationship('usuarioRecibe', 'name')
                                            ->searchable()
                                            ->preload()
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
                                        SchemaComponents\Grid::make(4)
                                            ->schema([
                                                Components\TextInput::make('cantidad_ordenada')
                                                    ->label('Cant. Ordenada')
                                                    ->numeric()
                                                    ->required()
                                                    ->default(0),
                                                Components\TextInput::make('cantidad_recibida')
                                                    ->label('Cant. Recibida')
                                                    ->numeric()
                                                    ->required()
                                                    ->default(0),
                                                Components\TextInput::make('cantidad_conforme')
                                                    ->label('Cant. Conforme')
                                                    ->numeric()
                                                    ->required()
                                                    ->default(0),
                                                Components\TextInput::make('cantidad_rechazada')
                                                    ->label('Cant. Rechazada')
                                                    ->numeric()
                                                    ->default(0),
                                            ]),
                                        Components\TextInput::make('costo_unitario')
                                            ->label('Costo Unitario')
                                            ->numeric()
                                            ->required()
                                            ->default(0)
                                            ->prefix('S/'),
                                        SchemaComponents\Grid::make(2)
                                            ->schema([
                                                Components\TextInput::make('lote')
                                                    ->label('Lote')
                                                    ->maxLength(255),
                                                Components\DatePicker::make('fecha_vencimiento')
                                                    ->label('Fecha Vencimiento'),
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
                Tables\Columns\TextColumn::make('numero_documento')
                    ->label('N° Documento')
                    ->searchable(),
                Tables\Columns\TextColumn::make('almacen.nombre')
                    ->label('Almacén')
                    ->sortable(),
                Tables\Columns\TextColumn::make('fecha_recepcion')
                    ->label('Fecha Recepción')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('estado')
                    ->label('Estado')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'parcial' => 'warning',
                        'completa' => 'success',
                        'con_discrepancia' => 'danger',
                        'anulada' => 'gray',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('usuarioRecibe.name')
                    ->label('Recibido por'),
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
                        'parcial' => 'Parcial',
                        'completa' => 'Completa',
                        'con_discrepancia' => 'Con Discrepancia',
                        'anulada' => 'Anulada',
                    ]),
                Tables\Filters\SelectFilter::make('almacen_id')
                    ->label('Almacén')
                    ->relationship('almacen', 'nombre'),
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
            'index' => Pages\ListRecepcionesCompra::route('/'),
        ];
    }
}
