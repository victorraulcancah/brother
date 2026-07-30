<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CajaResource\Pages;
use App\Models\Caja;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Panel;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class CajaResource extends Resource
{
    protected static ?string $model = Caja::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-calculator'; }
    public static function getNavigationLabel(): string { return 'Cajas'; }
    public static function getPluralModelLabel(): string { return 'Cajas'; }
    public static function getSlug(?Panel $panel = null): string { return 'cajas'; }
    public static function getNavigationGroup(): string { return 'Tesorería'; }
    public static function getNavigationSort(): ?int { return 6; }

    public static function form(Schema $schema): Schema
    {
        return $schema->schema([
            SchemaComponents\Section::make('Datos de la Caja')
                ->schema([
                    Components\TextInput::make('nombre')->label('Nombre')->required()->maxLength(255),
                    Components\Select::make('almacen_id')->label('Almacén')
                        ->relationship('almacen', 'nombre')->searchable()->preload()->nullable(),
                    Components\Toggle::make('activo')->label('Activo')->default(true),
                ])->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('nombre')->label('Nombre')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('almacen.nombre')->label('Almacén'),
                Tables\Columns\IconColumn::make('activo')->label('Activo')->boolean(),
                Tables\Columns\TextColumn::make('aperturas_count')->label('Aperturas')->counts('aperturas'),
            ])
            ->headerActions([
                Actions\CreateAction::make(),
            ])
            ->actions([
                Actions\EditAction::make(),
                Actions\Action::make('aperturar')
                    ->label('Aperturar')
                    ->icon('heroicon-o-lock-open')
                    ->color('success')
                    ->form([
                        Components\Select::make('usuario_id')->label('Usuario')
                            ->relationship('usuario', 'name')->required(),
                        Components\TextInput::make('monto_inicial')->label('Monto Inicial')->numeric()->default(0)->prefix('S/'),
                        Components\DateTimePicker::make('fecha_apertura')->label('Fecha Apertura')->required()->default(now()),
                    ])
                    ->action(function (array $data, Caja $record): void {
                        $record->aperturas()->create([
                            'usuario_id' => $data['usuario_id'],
                            'monto_inicial' => $data['monto_inicial'],
                            'fecha_apertura' => $data['fecha_apertura'],
                            'estado' => 'abierta',
                        ]);
                    }),
                Actions\DeleteAction::make(),
            ]);
    }

    public static function getRelations(): array { return []; }

    public static function getPages(): array
    {
        return ['index' => Pages\ListCajas::route('/')];
    }
}
