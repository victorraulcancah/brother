<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MovimientoCajaResource\Pages;
use App\Models\MovimientoCaja;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Panel;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class MovimientoCajaResource extends Resource
{
    protected static ?string $model = MovimientoCaja::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-arrows-right-left'; }
    public static function getNavigationLabel(): string { return 'Movimientos de Caja'; }
    public static function getPluralModelLabel(): string { return 'Movimientos de Caja'; }
    public static function getSlug(?Panel $panel = null): string { return 'movimientos-caja'; }
    public static function getNavigationGroup(): string { return 'Tesorería'; }
    public static function getNavigationSort(): ?int { return 7; }

    public static function form(Schema $schema): Schema
    {
        return $schema->schema([
            SchemaComponents\Section::make('Datos del Movimiento')
                ->schema([
                    Components\Select::make('apertura_caja_id')->label('Apertura de Caja')
                        ->relationship('apertura', 'id', fn ($q) => $q->where('estado', 'abierta'))
                        ->searchable()->preload()->required()
                        ->getOptionLabelFromRecordUsing(fn ($r) => 'Caja: ' . ($r->caja->nombre ?? '') . ' | ' . $r->fecha_apertura->format('d/m/Y H:i')),
                    Components\Select::make('tipo')->label('Tipo')
                        ->options(['ingreso' => 'Ingreso', 'egreso' => 'Egreso'])->required()->live(),
                    Components\Select::make('metodo_pago_id')->label('Método de Pago')
                        ->relationship('metodoPago', 'nombre', fn ($q) => $q->where('activo', true))
                        ->searchable()->preload()->required()->live()
                        ->afterStateUpdated(fn (callable $set) => $set('cuenta_bancaria_id', null)),
                    Components\Select::make('cuenta_bancaria_id')->label('Cuenta Bancaria')
                        ->relationship('cuentaBancaria', 'numero_cuenta', fn ($q) => $q->where('activo', true))
                        ->searchable()->preload()->nullable()
                        ->visible(fn ($get) => optional(\App\Models\MetodoPago::find($get('metodo_pago_id')))->requiere_cuenta_bancaria),
                    Components\Select::make('tarjeta_id')->label('Tarjeta')
                        ->relationship('tarjeta', 'nombre_referencial', fn ($q) => $q->where('estado', 'activa'))
                        ->searchable()->preload()->nullable()
                        ->visible(fn ($get) => optional(\App\Models\MetodoPago::find($get('metodo_pago_id')))->requiere_tarjeta),
                    Components\Select::make('billetera_id')->label('Billetera Digital')
                        ->relationship('billetera', 'nombre', fn ($q) => $q->where('activo', true))
                        ->searchable()->preload()->nullable()
                        ->visible(fn ($get) => optional(\App\Models\MetodoPago::find($get('metodo_pago_id')))->tipo === 'billetera'),
                    Components\TextInput::make('numero_operacion')->label('N° Operación')->maxLength(100)
                        ->visible(fn ($get) => optional(\App\Models\MetodoPago::find($get('metodo_pago_id')))->requiere_numero_operacion),
                    Components\TextInput::make('monto')->label('Monto')->numeric()->required()->prefix('S/'),
                    Components\DatePicker::make('fecha')->label('Fecha')->required(),
                    Components\TextInput::make('documento_referencia_tipo')->label('Doc. Referencia')->maxLength(50),
                    Components\TextInput::make('documento_referencia_id')->label('ID Referencia')->numeric()->nullable(),
                ])->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('fecha')->label('Fecha')->date()->sortable(),
                Tables\Columns\TextColumn::make('apertura.caja.nombre')->label('Caja'),
                Tables\Columns\TextColumn::make('tipo')->label('Tipo')->badge()
                    ->color(fn ($state) => $state === 'ingreso' ? 'success' : 'danger'),
                Tables\Columns\TextColumn::make('metodoPago.nombre')->label('Método Pago')->badge()->color('gray'),
                Tables\Columns\TextColumn::make('monto')->label('Monto')->money('PEN')->sortable(),
                Tables\Columns\TextColumn::make('numero_operacion')->label('N° Operación')->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('cuentaBancaria.numero_cuenta')->label('Cuenta Bancaria')->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('tarjeta.nombre_referencial')->label('Tarjeta')->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('tipo')->options(['ingreso' => 'Ingreso', 'egreso' => 'Egreso']),
                Tables\Filters\SelectFilter::make('metodo_pago_id')->label('Método Pago')
                    ->relationship('metodoPago', 'nombre'),
                Tables\Filters\SelectFilter::make('apertura_caja_id')->label('Caja')
                    ->relationship('apertura.caja', 'nombre'),
                Tables\Filters\Filter::make('fecha')->label('Fecha')->form([
                    Components\DatePicker::make('desde'),
                    Components\DatePicker::make('hasta'),
                ])->query(fn ($query, array $data) => $query
                    ->when($data['desde'], fn ($q, $d) => $q->whereDate('fecha', '>=', $d))
                    ->when($data['hasta'], fn ($q, $d) => $q->whereDate('fecha', '<=', $d))),
            ])
            ->headerActions([
                Actions\CreateAction::make()->modalWidth('3xl'),
            ])
            ->actions([
                Actions\EditAction::make()->modalWidth('3xl'),
                Actions\DeleteAction::make(),
            ])
            ->defaultSort('fecha', 'desc');
    }

    public static function getRelations(): array { return []; }

    public static function getPages(): array
    {
        return ['index' => Pages\ListMovimientosCaja::route('/')];
    }
}
