<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CosteoConfigResource\Pages;
use App\Models\CosteoConfig;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class CosteoConfigResource extends Resource
{
    protected static ?string $model = CosteoConfig::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-calculator'; }
    public static function getNavigationLabel(): string { return 'Costeo'; }
    public static function getPluralModelLabel(): string { return 'Configuración de Costeo'; }
    public static function getSlug(?Panel $panel = null): string { return 'costeo'; }
    public static function getNavigationGroup(): string { return 'Inventario'; }
    public static function getNavigationSort(): ?int { return 7; }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Section::make('Método de Costeo')
                    ->schema([
                        Components\Select::make('metodo')
                            ->label('Método')
                            ->options([
                                'peps' => 'PEPS (FIFO)',
                                'promedio_ponderado' => 'Promedio Ponderado',
                                'ueps' => 'UEPS (LIFO)',
                            ])
                            ->required(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('metodo')
                    ->label('Método')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'peps' => 'success',
                        'promedio_ponderado' => 'info',
                        'ueps' => 'warning',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Creado')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->label('Actualizado')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([])
            ->actions([
                Actions\EditAction::make()->modalWidth('2xl'),
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
            'index' => Pages\ListCosteoConfigs::route('/'),
        ];
    }
}
