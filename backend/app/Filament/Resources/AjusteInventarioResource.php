<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AjusteInventarioResource\Pages;
use App\Models\AjusteInventario;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class AjusteInventarioResource extends Resource
{
    protected static ?string $model = AjusteInventario::class;

    public static function getNavigationIcon(): string
    {
        return 'heroicon-o-adjustments-horizontal';
    }

    public static function getNavigationLabel(): string
    {
        return 'Ajustes';
    }

    public static function getPluralModelLabel(): string
    {
        return 'Ajustes de Inventario';
    }

    public static function getSlug(?Panel $panel = null): string
    {
        return 'ajustes';
    }

    public static function getNavigationGroup(): string
    {
        return 'Inventario';
    }

    public static function getNavigationSort(): ?int
    {
        return 4;
    }

    public static function getNavigationBadge(): ?string
    {
        return (string) static::getModel()::count();
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Section::make('Datos del Ajuste')
                    ->schema([
                        Components\Select::make('almacen_id')
                            ->label('Almacén')
                            ->relationship('almacen', 'nombre')
                            ->searchable()
                            ->preload()
                            ->required(),
                        Components\Select::make('tipo')
                            ->label('Tipo')
                            ->options([
                                'ingreso' => 'Ingreso',
                                'salida' => 'Salida',
                            ])
                            ->live()
                            ->afterStateUpdated(fn (callable $set) => $set('motivo', null))
                            ->required(),
                        Components\Select::make('motivo')
                            ->label('Motivo')
                            ->options(function (callable $get): array {
                                $tipoAjuste = $get('tipo');
                                $query = \App\Models\MotivoMovimiento::where('activo', true)
                                    ->where('es_sistema', false);
                                if ($tipoAjuste) {
                                    $tipoMotivo = $tipoAjuste === 'ingreso' ? 'entrada' : 'salida';
                                    $query->where('tipo', $tipoMotivo);
                                }
                                return $query->orderBy('nombre')->pluck('nombre', 'nombre')->toArray();
                            })
                            ->searchable()
                            ->required(),
                        Components\Textarea::make('observaciones')
                            ->label('Observación')
                            ->maxLength(5000)
                            ->columnSpanFull(),
                        Components\Repeater::make('detalles')
                            ->relationship('detalles')
                            ->compact(true)
                            ->schema([
                                SchemaComponents\Grid::make(3)
                                    ->schema([
                                        Components\Select::make('producto_id')
                                            ->label('Producto')
                                            ->relationship('producto', 'nombre')
                                            ->searchable()
                                            ->preload()
                                            ->required()
                                            ->columnSpan(2),
                                        Components\TextInput::make('cantidad_fisica')
                                            ->label('Nuevo stock')
                                            ->numeric()
                                            ->required()
                                            ->default(0),
                                    ]),
                            ])
                            ->defaultItems(1)
                            ->addActionLabel('Agregar Producto'),
                    ])->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('fecha')
                    ->label('Fecha')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
                Tables\Columns\TextColumn::make('almacen.nombre')
                    ->label('Almacén')
                    ->sortable(),
                Tables\Columns\TextColumn::make('tipo')
                    ->label('Tipo')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => $state === 'ingreso' ? 'Ingreso' : 'Salida')
                    ->color(fn(string $state): string => $state === 'ingreso' ? 'success' : 'danger'),
                Tables\Columns\TextColumn::make('motivo')
                    ->label('Motivo')
                    ->badge()
                    ->color('gray'),
                Tables\Columns\TextColumn::make('detalles_count')
                    ->label('Productos')
                    ->counts('detalles'),
                Tables\Columns\TextColumn::make('estado')
                    ->label('Estado')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'pendiente' => 'warning',
                        'aprobado' => 'success',
                        'rechazado' => 'danger',
                        default => 'gray',
                    }),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('tipo')
                    ->label('Tipo')
                    ->options(['ingreso' => 'Ingreso', 'salida' => 'Salida']),
                Tables\Filters\SelectFilter::make('estado')
                    ->label('Estado')
                    ->options(['pendiente' => 'Pendiente', 'aprobado' => 'Aprobado', 'rechazado' => 'Rechazado']),
            ])
            ->actions([
                Actions\EditAction::make()->modalWidth('3xl'),
                Actions\DeleteAction::make(),
            ])
            ->defaultSort('id', 'desc');
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListAjustesInventario::route('/'),
        ];
    }
}
