<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MovimientoInventarioResource\Pages;
use App\Models\MovimientoInventario;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class MovimientoInventarioResource extends Resource
{
    protected static ?string $model = MovimientoInventario::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-arrow-path'; }
    public static function getNavigationLabel(): string { return 'Movimientos'; }
    public static function getPluralModelLabel(): string { return 'Movimientos'; }
    public static function getSlug(?Panel $panel = null): string { return 'movimientos'; }
    public static function getNavigationGroup(): string { return 'Inventario'; }
    public static function getNavigationSort(): ?int { return 2; }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Section::make('Detalle del Movimiento')
                    ->schema([
                        Components\TextInput::make('tipo_movimiento')->label('Tipo'),
                        Components\TextInput::make('origen')->label('Origen'),
                        Components\TextInput::make('cantidad')->label('Cantidad'),
                        Components\TextInput::make('costo_unitario')->label('Costo Unitario'),
                        Components\TextInput::make('saldo_stock')->label('Saldo'),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Fecha')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('tipo_movimiento')
                    ->label('Tipo')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'entrada' => 'success',
                        'salida' => 'danger',
                        'transferencia' => 'info',
                        'ajuste' => 'warning',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('origen')
                    ->label('Origen')
                    ->badge()
                    ->color('gray'),
                Tables\Columns\TextColumn::make('producto.nombre')
                    ->label('Producto')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('productoVariante.sku_variante')
                    ->label('Variante')
                    ->badge()
                    ->color('gray'),
                Tables\Columns\TextColumn::make('almacen.nombre')
                    ->label('Almacén'),
                Tables\Columns\TextColumn::make('cantidad')
                    ->label('Cantidad')
                    ->numeric()
                    ->sortable()
                    ->color(fn($record) => $record->cantidad > 0 ? 'success' : 'danger'),
                Tables\Columns\TextColumn::make('costo_unitario')
                    ->label('Costo Unit.')
                    ->money('PEN'),
                Tables\Columns\TextColumn::make('saldo_stock')
                    ->label('Saldo')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('usuario.name')
                    ->label('Usuario'),
                Tables\Columns\TextColumn::make('documento_referencia_tipo')
                    ->label('Doc. Referencia')
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('tipo_movimiento')
                    ->label('Tipo')
                    ->options([
                        'entrada' => 'Entrada',
                        'salida' => 'Salida',
                        'transferencia' => 'Transferencia',
                        'ajuste' => 'Ajuste',
                    ]),
                Tables\Filters\SelectFilter::make('origen')
                    ->label('Origen')
                    ->options([
                        'compra' => 'Compra',
                        'venta' => 'Venta',
                        'devolucion' => 'Devolución',
                        'merma' => 'Merma',
                        'transferencia' => 'Transferencia',
                        'ajuste_manual' => 'Ajuste Manual',
                    ]),
                Tables\Filters\SelectFilter::make('almacen_id')
                    ->label('Almacén')
                    ->relationship('almacen', 'nombre'),
                Tables\Filters\SelectFilter::make('producto_id')
                    ->label('Producto')
                    ->relationship('producto', 'nombre'),
            ])
            ->defaultSort('created_at', 'desc')
            ->actions([])
            ->bulkActions([]);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListMovimientosInventario::route('/'),
        ];
    }
}
