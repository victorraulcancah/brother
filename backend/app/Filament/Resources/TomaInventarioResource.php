<?php

namespace App\Filament\Resources;

use App\Filament\Resources\TomaInventarioResource\Pages;
use App\Models\TomaInventario;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class TomaInventarioResource extends Resource
{
    protected static ?string $model = TomaInventario::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-clipboard-document-list'; }
    public static function getNavigationLabel(): string { return 'Tomas de Inventario'; }
    public static function getPluralModelLabel(): string { return 'Tomas de Inventario'; }
    public static function getSlug(?Panel $panel = null): string { return 'tomas-inventario'; }
    public static function getNavigationGroup(): string { return 'Inventario'; }
    public static function getNavigationSort(): ?int { return 5; }
    public static function getNavigationBadge(): ?string { return (string) static::getModel()::count(); }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Tabs::make('Toma de Inventario')
                    ->tabs([
                        SchemaComponents\Tabs\Tab::make('Información')
                            ->icon('heroicon-o-information-circle')
                            ->schema([
                                SchemaComponents\Section::make('Datos de la Toma')
                                    ->schema([
                                        Components\Select::make('almacen_id')
                                            ->label('Almacén')
                                            ->relationship('almacen', 'nombre')
                                            ->searchable()
                                            ->preload()
                                            ->required(),
                                        Components\DateTimePicker::make('fecha')
                                            ->label('Fecha')
                                            ->required(),
                                        Components\Select::make('estado')
                                            ->label('Estado')
                                            ->options([
                                                'en_proceso' => 'En Proceso',
                                                'cerrado' => 'Cerrado',
                                            ])
                                            ->required(),
                                        Components\Select::make('usuario_id')
                                            ->label('Responsable')
                                            ->relationship('usuario', 'name')
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
                                                Components\TextInput::make('stock_sistema')
                                                    ->label('Stock en Sistema')
                                                    ->numeric()
                                                    ->required()
                                                    ->default(0),
                                                Components\TextInput::make('stock_contado')
                                                    ->label('Stock Contado')
                                                    ->numeric()
                                                    ->required()
                                                    ->default(0),
                                                Components\TextInput::make('diferencia')
                                                    ->label('Diferencia')
                                                    ->numeric()
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
                Tables\Columns\TextColumn::make('almacen.nombre')
                    ->label('Almacén')
                    ->sortable(),
                Tables\Columns\TextColumn::make('fecha')
                    ->label('Fecha')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('estado')
                    ->label('Estado')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'en_proceso' => 'warning',
                        'cerrado' => 'success',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('usuario.name')
                    ->label('Responsable'),
                Tables\Columns\TextColumn::make('detalles_count')
                    ->label('Productos')
                    ->counts('detalles'),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Creado')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('estado')
                    ->label('Estado')
                    ->options(['en_proceso' => 'En Proceso', 'cerrado' => 'Cerrado']),
                Tables\Filters\SelectFilter::make('almacen_id')
                    ->label('Almacén')
                    ->relationship('almacen', 'nombre'),
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
            'index' => Pages\ListTomasInventario::route('/'),
        ];
    }
}
