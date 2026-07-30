<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MotivoMovimientoResource\Pages;
use App\Models\MotivoMovimiento;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Panel;
use Filament\Resources\Resource;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Table;

class MotivoMovimientoResource extends Resource
{
    protected static ?string $model = MotivoMovimiento::class;

    /** No aparece como menú suelto: se muestra como pestaña dentro de Ajustes. */
    public static function shouldRegisterNavigation(): bool
    {
        return false;
    }

    public static function getNavigationIcon(): string
    {
        return 'heroicon-o-tag';
    }

    public static function getNavigationLabel(): string
    {
        return 'Motivos';
    }

    public static function getModelLabel(): string
    {
        return 'Motivo';
    }

    public static function getPluralModelLabel(): string
    {
        return 'Motivos de Movimiento';
    }

    public static function getNavigationGroup(): string
    {
        return 'Inventario';
    }

    public static function getNavigationSort(): ?int
    {
        return 3;
    }

    public static function getSlug(?Panel $panel = null): string
    {
        return 'motivos';
    }

    public static function form(Schema $schema): Schema
    {
        return $schema->schema([
            SchemaComponents\Section::make('Datos del motivo')
                ->schema([
                    Components\TextInput::make('nombre')
                        ->label('Nombre')
                        ->required()
                        ->maxLength(255),
                    Components\Select::make('tipo')
                        ->label('Tipo')
                        ->required()
                        ->options([
                            'entrada' => 'Entrada (ingreso)',
                            'salida' => 'Salida',
                        ]),
                    Components\Toggle::make('es_sistema')
                        ->label('Del sistema')
                        ->helperText('Los motivos del sistema no se pueden eliminar.'),
                    Components\Toggle::make('activo')
                        ->label('Activo')
                        ->default(true),
                ])
                ->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('nombre')
                    ->label('Nombre')
                    ->searchable()
                    ->sortable(),

                Tables\Columns\TextColumn::make('tipo')
                    ->label('Tipo')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => $state === 'entrada' ? 'Entrada' : 'Salida')
                    ->color(fn (string $state): string => $state === 'entrada' ? 'success' : 'danger'),

                Tables\Columns\IconColumn::make('es_sistema')
                    ->label('Sistema')
                    ->boolean(),

                Tables\Columns\IconColumn::make('activo')
                    ->label('Activo')
                    ->boolean(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('tipo')
                    ->label('Tipo')
                    ->options([
                        'entrada' => 'Entrada',
                        'salida' => 'Salida',
                    ]),
            ])
            ->headerActions([
                Actions\CreateAction::make()
                    ->modalWidth('2xl'),
            ])
            ->actions([
                Actions\EditAction::make()
                    ->modalWidth('2xl'),
                Actions\DeleteAction::make()
                    ->visible(fn (MotivoMovimiento $record): bool => ! $record->es_sistema),
            ]);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListMotivoMovimientos::route('/'),
        ];
    }
}
