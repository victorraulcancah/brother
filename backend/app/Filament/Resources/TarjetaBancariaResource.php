<?php

namespace App\Filament\Resources;

use App\Filament\Resources\TarjetaBancariaResource\Pages;
use App\Models\TarjetaBancaria;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Panel;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class TarjetaBancariaResource extends Resource
{
    protected static ?string $model = TarjetaBancaria::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-identification'; }
    public static function getNavigationLabel(): string { return 'Tarjetas Bancarias'; }
    public static function getPluralModelLabel(): string { return 'Tarjetas Bancarias'; }
    public static function getSlug(?Panel $panel = null): string { return 'tarjetas-bancarias'; }
    public static function getNavigationGroup(): string { return 'Tesorería'; }
    public static function getNavigationSort(): ?int { return 4; }

    public static function form(Schema $schema): Schema
    {
        return $schema->schema([
            SchemaComponents\Section::make('Datos de la Tarjeta')
                ->schema([
                    Components\Select::make('cuenta_bancaria_id')->label('Cuenta Bancaria')
                        ->relationship('cuentaBancaria', 'numero_cuenta', fn ($q) => $q->where('activo', true))
                        ->searchable()->preload()->required()
                        ->getOptionLabelFromRecordUsing(fn ($r) => $r->banco->nombre . ' - ' . $r->numero_cuenta),
                    Components\Select::make('tipo_tarjeta')->label('Tipo')
                        ->options(['debito' => 'Débito', 'credito' => 'Crédito'])->required(),
                    Components\TextInput::make('nombre_referencial')->label('Nombre Referencial')->required()->maxLength(255),
                    Components\TextInput::make('numero_enmascarado')->label('N° Tarjeta (últ. 4 díg.)')
                        ->required()->maxLength(20)->helperText('Solo los últimos 4 dígitos'),
                    Components\Select::make('marca')->label('Marca')
                        ->options(['Visa' => 'Visa', 'Mastercard' => 'Mastercard', 'Amex' => 'American Express', 'Diners' => 'Diners'])->required(),
                    Components\TextInput::make('fecha_vencimiento')->label('Vencimiento')->placeholder('mm/aaaa')->maxLength(10),
                    Components\TextInput::make('titular')->label('Titular')->maxLength(255),
                    Components\TextInput::make('limite_credito')->label('Límite de Crédito')->numeric()->prefix('S/')
                        ->visible(fn ($get) => $get('tipo_tarjeta') === 'credito'),
                    Components\Select::make('estado')->label('Estado')
                        ->options(['activa' => 'Activa', 'bloqueada' => 'Bloqueada', 'vencida' => 'Vencida'])->required(),
                ])->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('nombre_referencial')->label('Nombre')->searchable(),
                Tables\Columns\TextColumn::make('numero_enmascarado')->label('N° Tarjeta')->searchable(),
                Tables\Columns\TextColumn::make('marca')->label('Marca')->badge(),
                Tables\Columns\TextColumn::make('tipo_tarjeta')->label('Tipo')->badge()
                    ->color(fn ($state) => $state === 'debito' ? 'info' : 'warning'),
                Tables\Columns\TextColumn::make('cuentaBancaria.banco.nombre')->label('Banco'),
                Tables\Columns\TextColumn::make('cuentaBancaria.numero_cuenta')->label('Cuenta'),
                Tables\Columns\TextColumn::make('estado')->label('Estado')->badge()
                    ->color(fn ($state) => match ($state) { 'activa' => 'success', 'bloqueada' => 'danger', 'vencida' => 'gray', default => 'gray' }),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('tipo_tarjeta')->options(['debito' => 'Débito', 'credito' => 'Crédito']),
                Tables\Filters\SelectFilter::make('estado')->options(['activa' => 'Activa', 'bloqueada' => 'Bloqueada', 'vencida' => 'Vencida']),
            ])
            ->headerActions([
                Actions\CreateAction::make()->modalWidth('3xl'),
            ])
            ->actions([
                Actions\EditAction::make()->modalWidth('3xl'),
                Actions\DeleteAction::make(),
            ]);
    }

    public static function getRelations(): array { return []; }

    public static function getPages(): array
    {
        return ['index' => Pages\ListTarjetasBancarias::route('/')];
    }
}
