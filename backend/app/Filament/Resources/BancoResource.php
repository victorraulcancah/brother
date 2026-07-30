<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BancoResource\Pages;
use App\Models\Banco;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Panel;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class BancoResource extends Resource
{
    protected static ?string $model = Banco::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-building-library'; }
    public static function getNavigationLabel(): string { return 'Bancos'; }
    public static function getPluralModelLabel(): string { return 'Bancos'; }
    public static function getSlug(?Panel $panel = null): string { return 'bancos'; }
    public static function getNavigationGroup(): string { return 'Tesorería'; }
    public static function getNavigationSort(): ?int { return 2; }

    public static function form(Schema $schema): Schema
    {
        return $schema->schema([
            SchemaComponents\Section::make('Datos del Banco')
                ->schema([
                    Components\TextInput::make('nombre')->label('Nombre')->required()->maxLength(255),
                ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('nombre')->label('Nombre')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('cuentas_count')->label('Cuentas')->counts('cuentas'),
            ])
            ->headerActions([
                Actions\CreateAction::make(),
            ])
            ->actions([
                Actions\EditAction::make(),
                Actions\DeleteAction::make(),
            ]);
    }

    public static function getRelations(): array { return []; }

    public static function getPages(): array
    {
        return ['index' => Pages\ListBancos::route('/')];
    }
}
