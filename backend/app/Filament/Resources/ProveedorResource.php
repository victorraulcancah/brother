<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ProveedorResource\Pages;
use App\Models\Proveedor;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class ProveedorResource extends Resource
{
    protected static ?string $model = Proveedor::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-truck'; }
    public static function getNavigationLabel(): string { return 'Proveedores'; }
    public static function getPluralModelLabel(): string { return 'Proveedores'; }
    public static function getSlug(?Panel $panel = null): string { return 'proveedores'; }
    public static function getNavigationGroup(): string { return 'Compras'; }
    public static function getNavigationSort(): ?int { return 1; }
    public static function getNavigationBadge(): ?string { return (string) static::getModel()::count(); }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Section::make('Datos del Proveedor')
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
                        Components\TextInput::make('ruc')
                            ->label('RUC')
                            ->maxLength(11)
                            ->unique(ignoreRecord: true),
                        Components\TextInput::make('direccion')
                            ->label('Dirección')
                            ->maxLength(255),
                        Components\TextInput::make('telefono')
                            ->label('Teléfono')
                            ->maxLength(20),
                        Components\TextInput::make('email')
                            ->label('Email')
                            ->email()
                            ->maxLength(255),
                        Components\TextInput::make('contacto_nombre')
                            ->label('Contacto')
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
                Tables\Columns\TextColumn::make('codigo')
                    ->label('Código')
                    ->badge()
                    ->color('gray')
                    ->searchable(),
                Tables\Columns\TextColumn::make('nombre')
                    ->label('Nombre')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('ruc')
                    ->label('RUC')
                    ->searchable(),
                Tables\Columns\TextColumn::make('telefono')
                    ->label('Teléfono'),
                Tables\Columns\TextColumn::make('email')
                    ->label('Email'),
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
            'index' => Pages\ListProveedores::route('/'),
        ];
    }
}
