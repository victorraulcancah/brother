<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CuentaBancariaResource\Pages;
use App\Models\CuentaBancaria;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Panel;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class CuentaBancariaResource extends Resource
{
    protected static ?string $model = CuentaBancaria::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-credit-card'; }
    public static function getNavigationLabel(): string { return 'Cuentas Bancarias'; }
    public static function getPluralModelLabel(): string { return 'Cuentas Bancarias'; }
    public static function getSlug(?Panel $panel = null): string { return 'cuentas-bancarias'; }
    public static function getNavigationGroup(): string { return 'Tesorería'; }
    public static function getNavigationSort(): ?int { return 3; }
    public static function shouldRegisterNavigation(): bool { return false; } // Gestionado desde la página "Cuentas y Medios de Pago"

    public static function form(Schema $schema): Schema
    {
        return $schema->schema([
            SchemaComponents\Section::make('Datos de la Cuenta')
                ->schema([
                    Components\Select::make('banco_id')->label('Banco')
                        ->relationship('banco', 'nombre')->searchable()->preload()->required(),
                    Components\TextInput::make('numero_cuenta')->label('N° Cuenta')->required()->maxLength(255),
                    Components\TextInput::make('cci')->label('CCI')->maxLength(255),
                    Components\Select::make('moneda')->label('Moneda')
                        ->options(['PEN' => 'Soles (PEN)', 'USD' => 'Dólares (USD)'])->required(),
                    Components\Select::make('tipo_cuenta')->label('Tipo')
                        ->options(['corriente' => 'Corriente', 'ahorros' => 'Ahorros'])->required(),
                    Components\Toggle::make('activo')->label('Activo')->default(true),
                ])->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('banco.nombre')->label('Banco')->sortable(),
                Tables\Columns\TextColumn::make('numero_cuenta')->label('N° Cuenta')->searchable(),
                Tables\Columns\TextColumn::make('cci')->label('CCI')->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('moneda')->label('Moneda')->badge(),
                Tables\Columns\TextColumn::make('tipo_cuenta')->label('Tipo')->badge()
                    ->formatStateUsing(fn ($state) => $state === 'corriente' ? 'Corriente' : 'Ahorros'),
                Tables\Columns\IconColumn::make('activo')->label('Activo')->boolean(),
                Tables\Columns\TextColumn::make('tarjetas_count')->label('Tarjetas')->counts('tarjetas'),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('banco_id')->label('Banco')->relationship('banco', 'nombre'),
                Tables\Filters\SelectFilter::make('moneda')->options(['PEN' => 'Soles', 'USD' => 'Dólares']),
            ])
            ->headerActions([
                Actions\CreateAction::make()->modalWidth('2xl'),
            ])
            ->actions([
                Actions\EditAction::make()->modalWidth('2xl'),
                Actions\DeleteAction::make(),
            ]);
    }

    public static function getRelations(): array { return []; }

    public static function getPages(): array
    {
        return ['index' => Pages\ListCuentasBancarias::route('/')];
    }
}
