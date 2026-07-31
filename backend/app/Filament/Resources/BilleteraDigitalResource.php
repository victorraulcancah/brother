<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BilleteraDigitalResource\Pages;
use App\Models\BilleteraDigital;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Panel;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class BilleteraDigitalResource extends Resource
{
    protected static ?string $model = BilleteraDigital::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-device-phone-mobile'; }
    public static function getNavigationLabel(): string { return 'Billeteras Digitales'; }
    public static function getPluralModelLabel(): string { return 'Billeteras Digitales'; }
    public static function getSlug(?Panel $panel = null): string { return 'billeteras-digitales'; }
    public static function getNavigationGroup(): string { return 'Tesorería'; }
    public static function getNavigationSort(): ?int { return 5; }
    public static function shouldRegisterNavigation(): bool { return false; } // Gestionado desde la página "Cuentas y Medios de Pago"

    public static function form(Schema $schema): Schema
    {
        return $schema->schema([
            SchemaComponents\Section::make('Datos de la Billetera')
                ->schema([
                    Components\TextInput::make('nombre')->label('Nombre')->required()->maxLength(255),
                    Components\TextInput::make('numero_asociado')->label('N° Asociado')->required()->maxLength(255),
                    Components\Toggle::make('requiere_numero_operacion')->label('Requiere n° operación'),
                    Components\Toggle::make('requiere_captura')->label('Requiere captura'),
                    Components\Toggle::make('activo')->label('Activo')->default(true),
                ])->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('nombre')->label('Nombre')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('numero_asociado')->label('N° Asociado')->searchable(),
                Tables\Columns\IconColumn::make('requiere_numero_operacion')->label('N° Oper.')->boolean(),
                Tables\Columns\IconColumn::make('requiere_captura')->label('Captura')->boolean(),
                Tables\Columns\IconColumn::make('activo')->label('Activo')->boolean(),
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
        return ['index' => Pages\ListBilleterasDigitales::route('/')];
    }
}
