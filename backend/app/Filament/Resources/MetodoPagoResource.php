<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MetodoPagoResource\Pages;
use App\Models\MetodoPago;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Panel;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class MetodoPagoResource extends Resource
{
    protected static ?string $model = MetodoPago::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-credit-card'; }
    public static function getNavigationLabel(): string { return 'Métodos de Pago'; }
    public static function getPluralModelLabel(): string { return 'Métodos de Pago'; }
    public static function getSlug(?Panel $panel = null): string { return 'metodos-pago'; }
    public static function getNavigationGroup(): string { return 'Tesorería'; }
    public static function getNavigationSort(): ?int { return 1; }

    public static function form(Schema $schema): Schema
    {
        return $schema->schema([
            SchemaComponents\Section::make('Datos del Método de Pago')
                ->schema([
                    Components\TextInput::make('nombre')->label('Nombre')->required()->maxLength(255),
                    Components\Select::make('tipo')->label('Tipo')
                        ->options([
                            'efectivo' => 'Efectivo',
                            'banco' => 'Banco / Transferencia',
                            'tarjeta' => 'Tarjeta',
                            'billetera' => 'Billetera Digital',
                        ])->required(),
                    Components\Toggle::make('es_sistema')->label('Del sistema')
                        ->helperText('Los métodos del sistema no se pueden eliminar.'),
                    Components\Toggle::make('requiere_cuenta_bancaria')->label('Requiere cuenta bancaria'),
                    Components\Toggle::make('requiere_tarjeta')->label('Requiere tarjeta'),
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
                Tables\Columns\TextColumn::make('tipo')->label('Tipo')->badge()
                    ->formatStateUsing(fn ($state) => match ($state) {
                        'efectivo' => 'Efectivo',
                        'banco' => 'Transferencia',
                        'tarjeta' => 'Tarjeta',
                        'billetera' => 'Billetera',
                        default => $state,
                    })->color(fn ($state) => match ($state) {
                        'efectivo' => 'success',
                        'banco' => 'info',
                        'tarjeta' => 'warning',
                        'billetera' => 'purple',
                        default => 'gray',
                    }),
                Tables\Columns\IconColumn::make('es_sistema')->label('Sistema')->boolean(),
                Tables\Columns\IconColumn::make('requiere_cuenta_bancaria')->label('Cta. Banc.')->boolean(),
                Tables\Columns\IconColumn::make('requiere_tarjeta')->label('Tarjeta')->boolean(),
                Tables\Columns\IconColumn::make('requiere_numero_operacion')->label('N° Oper.')->boolean(),
                Tables\Columns\IconColumn::make('activo')->label('Activo')->boolean(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('tipo')
                    ->options(['efectivo' => 'Efectivo', 'banco' => 'Transferencia', 'tarjeta' => 'Tarjeta', 'billetera' => 'Billetera']),
            ])
            ->headerActions([
                Actions\CreateAction::make()->modalWidth('2xl'),
            ])
            ->actions([
                Actions\EditAction::make()->modalWidth('2xl'),
                Actions\DeleteAction::make()
                    ->visible(fn (MetodoPago $record): bool => ! $record->es_sistema),
            ]);
    }

    public static function getRelations(): array { return []; }

    public static function getPages(): array
    {
        return ['index' => Pages\ListMetodoPagos::route('/')];
    }
}
