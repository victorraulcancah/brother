<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AlmacenStockResource\Pages;
use App\Models\ProductoAlmacenStock;
use Filament\Panel;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class AlmacenStockResource extends Resource
{
    protected static ?string $model = ProductoAlmacenStock::class;

    public static function getNavigationIcon(): string
    {
        return 'heroicon-o-building-storefront';
    }

    public static function getNavigationLabel(): string
    {
        return 'Existencias por Almacén';
    }

    public static function getModelLabel(): string
    {
        return 'Existencia';
    }

    public static function getPluralModelLabel(): string
    {
        return 'Existencias por Almacén';
    }

    public static function getNavigationGroup(): string
    {
        return 'Inventario';
    }

    public static function getNavigationSort(): ?int
    {
        return 2;
    }

    public static function getSlug(?Panel $panel = null): string
    {
        return 'existencias';
    }

    public static function form(Schema $schema): Schema
    {
        return $schema->components([]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('producto.codigo')
                    ->label('Código')
                    ->searchable()
                    ->sortable(),

                Tables\Columns\TextColumn::make('producto.nombre')
                    ->label('Descripción')
                    ->searchable()
                    ->wrap()
                    ->limit(55),

                Tables\Columns\TextColumn::make('producto.categoria.nombre')
                    ->label('Categoría')
                    ->placeholder('—')
                    ->badge()
                    ->color('gray'),

                Tables\Columns\TextColumn::make('almacen.nombre')
                    ->label('Almacén')
                    ->badge()
                    ->color('info')
                    ->toggleable(),

                Tables\Columns\TextColumn::make('stock_anterior')
                    ->label('Stock Anterior')
                    ->sortable()
                    ->numeric(decimalPlaces: 2)
                    ->toggleable(),

                Tables\Columns\TextColumn::make('stock_actual')
                    ->label('Stock Actual')
                    ->sortable()
                    ->numeric(decimalPlaces: 2)
                    ->badge()
                    ->color(fn ($state): string => (float) $state <= 0
                        ? 'danger'
                        : ((float) $state <= 5 ? 'warning' : 'success')),

                Tables\Columns\TextColumn::make('producto.precio_base')
                    ->label('Precio')
                    ->money('PEN')
                    ->sortable(),
            ])
            ->defaultSort('id');
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->with(['producto.categoria', 'almacen']);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListAlmacenStock::route('/'),
        ];
    }
}
