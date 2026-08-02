<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CuentaPorPagarResource\Pages;
use App\Models\CuentaPorPagar;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class CuentaPorPagarResource extends Resource
{
    protected static ?string $model = CuentaPorPagar::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-banknotes'; }
    public static function getNavigationLabel(): string { return 'CxP'; }
    public static function getPluralModelLabel(): string { return 'Cuentas por Pagar'; }
    public static function getSlug(?Panel $panel = null): string { return 'cuentas-por-pagar'; }
    public static function getNavigationGroup(): string { return 'Tesorería'; }
    public static function getNavigationSort(): ?int { return 9; }
    public static function getNavigationBadge(): ?string
    {
        return (string) static::getModel()::whereIn('estado', ['pendiente', 'parcial'])->count();
    }

    public static function form(Schema $schema): Schema
    {
        return $schema->schema([]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('proveedor.nombre')->label('Proveedor')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('recepcionCompra.id')->label('N° Recepción'),
                Tables\Columns\TextColumn::make('monto_total')->label('Total')->money('PEN')->sortable(),
                Tables\Columns\TextColumn::make('monto_pagado')->label('Pagado')->money('PEN')->sortable(),
                Tables\Columns\TextColumn::make('saldo')->label('Saldo')->money('PEN')
                    ->sortable()->badge()->color(fn ($state) => (float) $state > 0 ? 'danger' : 'success'),
                Tables\Columns\TextColumn::make('fecha_vencimiento')->label('Vencimiento')->date()->sortable(),
                Tables\Columns\TextColumn::make('estado')->label('Estado')->badge()
                    ->color(fn ($state) => match ($state) {
                        'pendiente' => 'warning',
                        'parcial' => 'info',
                        'pagado' => 'success',
                        'vencido' => 'danger',
                        default => 'gray',
                    }),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('estado')
                    ->options(['pendiente' => 'Pendiente', 'parcial' => 'Parcial', 'pagado' => 'Pagado', 'vencido' => 'Vencido']),
                Tables\Filters\SelectFilter::make('proveedor_id')->label('Proveedor')
                    ->relationship('proveedor', 'nombre'),
            ])
            ->actions([
                Actions\Action::make('registrar_pago')
                    ->label('Registrar Pago')
                    ->icon('heroicon-o-banknotes')
                    ->color('success')
                    ->form([
                        Components\Select::make('forma_pago')->label('Forma de Pago')
                            ->options([
                                'efectivo' => 'Efectivo',
                                'transferencia' => 'Transferencia',
                                'tarjeta' => 'Tarjeta',
                                'yape' => 'Yape',
                                'plin' => 'Plin',
                                'otro' => 'Otro',
                            ])->required(),
                        Components\TextInput::make('monto')->label('Monto')->numeric()->required()
                            ->minValue(0.01)->prefix('S/'),
                        Components\TextInput::make('referencia')->label('Referencia')->maxLength(100),
                        Components\DatePicker::make('fecha')->label('Fecha')->required()->default(now()),
                    ])
                    ->action(function (array $data, CuentaPorPagar $record): void {
                        $record->pagos()->create([
                            'forma_pago' => $data['forma_pago'],
                            'monto' => $data['monto'],
                            'referencia' => $data['referencia'] ?? null,
                            'fecha' => $data['fecha'],
                        ]);
                        $nuevoPagado = $record->monto_pagado + $data['monto'];
                        $record->update([
                            'monto_pagado' => $nuevoPagado,
                            'saldo' => $record->monto_total - $nuevoPagado,
                            'estado' => $nuevoPagado >= $record->monto_total ? 'pagado' : 'parcial',
                        ]);
                    })
                    ->visible(fn (CuentaPorPagar $record): bool => ! in_array($record->estado, ['pagado'])),
            ])
            ->defaultSort('fecha_vencimiento', 'asc');
    }

    public static function getRelations(): array { return []; }

    public static function getPages(): array
    {
        return ['index' => Pages\ListCuentasPorPagar::route('/')];
    }
}
