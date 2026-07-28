<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AtributoValorResource\Pages;
use App\Models\AtributoValor;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class AtributoValorResource extends Resource
{
    protected static ?string $model = AtributoValor::class;

    public static function getNavigationIcon(): string
    {
        return 'heroicon-o-variable';
    }

    public static function getNavigationLabel(): string
    {
        return 'Valores de Atributos';
    }

    public static function getPluralModelLabel(): string
    {
        return 'Valores de Atributos';
    }

    public static function getSlug(?Panel $panel = null): string
    {
        return 'valores-atributos';
    }

    public static function getNavigationGroup(): string
    {
        return 'Catálogo';
    }

    public static function getNavigationSort(): ?int
    {
        return 7;
    }

    public static function getNavigationBadge(): ?string
    {
        return (string) static::getModel()::count();
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                Components\Section::make('Información del Valor')
                    ->schema([
                        Components\Select::make('atributo_id')
                            ->label('Atributo')
                            ->relationship('atributo', 'nombre')
                            ->searchable()
                            ->preload()
                            ->required(),
                        Components\TextInput::make('valor')
                            ->label('Valor')
                            ->required()
                            ->maxLength(255),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('atributo.nombre')
                    ->label('Atributo')
                    ->sortable()
                    ->searchable(),
                Tables\Columns\TextColumn::make('valor')
                    ->label('Valor')
                    ->searchable()
                    ->sortable()
                    ->badge()
                    ->color('info'),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('atributo_id')
                    ->relationship('atributo', 'nombre')
                    ->label('Atributo'),
            ])
            ->actions([
                Actions\EditAction::make(),
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
            'index' => Pages\ListAtributoValors::route('/'),
        ];
    }
}
