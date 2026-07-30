<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ClienteResource\Pages;
use App\Models\Cliente;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Panel;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class ClienteResource extends Resource
{
    protected static ?string $model = Cliente::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-users'; }
    public static function getNavigationLabel(): string { return 'Clientes'; }
    public static function getPluralModelLabel(): string { return 'Clientes'; }
    public static function getSlug(?Panel $panel = null): string { return 'clientes'; }
    public static function getNavigationGroup(): string { return 'Ventas'; }
    public static function getNavigationSort(): ?int { return 1; }

    public static function form(Schema $schema): Schema
    {
        return $schema->schema([
            SchemaComponents\Section::make('Datos del Cliente')
                ->schema([
                    Components\TextInput::make('nombre')->label('Nombre')->required()->maxLength(255),
                    Components\Select::make('tipo_documento')->label('Tipo Doc.')
                        ->options(['DNI' => 'DNI', 'RUC' => 'RUC', 'CE' => 'Carnet Extranjería', 'Pasaporte' => 'Pasaporte'])
                        ->default('DNI'),
                    Components\TextInput::make('numero_documento')->label('N° Documento')->maxLength(20),
                    Components\TextInput::make('telefono')->label('Teléfono')->maxLength(20),
                    Components\TextInput::make('email')->label('Email')->email()->maxLength(255),
                    Components\TextInput::make('direccion')->label('Dirección')->maxLength(255),
                    Components\Toggle::make('activo')->label('Activo')->default(true),
                ])->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('nombre')->label('Nombre')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('tipo_documento')->label('Tipo Doc.')->badge()->color('gray'),
                Tables\Columns\TextColumn::make('numero_documento')->label('N° Documento')->searchable(),
                Tables\Columns\TextColumn::make('telefono')->label('Teléfono'),
                Tables\Columns\TextColumn::make('email')->label('Email'),
                Tables\Columns\IconColumn::make('activo')->label('Activo')->boolean(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('tipo_documento')->label('Tipo Doc.')
                    ->options(['DNI' => 'DNI', 'RUC' => 'RUC', 'CE' => 'CE', 'Pasaporte' => 'Pasaporte']),
                Tables\Filters\Filter::make('activo')->label('Solo activos')
                    ->query(fn ($query) => $query->where('activo', true)),
            ])
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

    public static function getRelations(): array { return []; }

    public static function getPages(): array
    {
        return ['index' => Pages\ListClientes::route('/')];
    }
}
