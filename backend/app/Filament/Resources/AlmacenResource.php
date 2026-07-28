<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AlmacenResource\Pages;
use App\Models\Almacen;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class AlmacenResource extends Resource
{
    protected static ?string $model = Almacen::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-building-storefront'; }
    public static function getNavigationLabel(): string { return 'Almacenes'; }
    public static function getPluralModelLabel(): string { return 'Almacenes'; }
    public static function getSlug(?Panel $panel = null): string { return 'almacenes'; }
    public static function getNavigationGroup(): string { return 'Inventario'; }
    public static function getNavigationSort(): ?int { return 1; }
    public static function getNavigationBadge(): ?string { return (string) static::getModel()::count(); }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Section::make('Datos del Almacén')
                    ->schema([
                        Components\TextInput::make('nombre')
                            ->label('Nombre')
                            ->required()
                            ->maxLength(255),
                        Components\TextInput::make('codigo')
                            ->label('Código')
                            ->required()
                            ->maxLength(255)
                            ->unique(ignoreRecord: true),
                        Components\Select::make('tipo')
                            ->label('Tipo')
                            ->options([
                                'principal' => 'Principal',
                                'tienda' => 'Tienda',
                                'transito' => 'Tránsito',
                                'mermas' => 'Mermas',
                            ])
                            ->required(),
                        Components\TextInput::make('direccion')
                            ->label('Dirección')
                            ->maxLength(255),
                        Components\Toggle::make('activo')
                            ->label('Activo')
                            ->default(true),
                    ])->columns(2),
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
                Tables\Columns\TextColumn::make('codigo')
                    ->label('Código')
                    ->badge()
                    ->color('gray')
                    ->searchable(),
                Tables\Columns\TextColumn::make('tipo')
                    ->label('Tipo')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'principal' => 'success',
                        'tienda' => 'info',
                        'transito' => 'warning',
                        'mermas' => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\IconColumn::make('activo')
                    ->label('Activo')
                    ->boolean()
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Creado')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('tipo')
                    ->label('Tipo')
                    ->options([
                        'principal' => 'Principal',
                        'tienda' => 'Tienda',
                        'transito' => 'Tránsito',
                        'mermas' => 'Mermas',
                    ]),
                Tables\Filters\TernaryFilter::make('activo')
                    ->label('Estado'),
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

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListAlmacenes::route('/'),
        ];
    }
}
