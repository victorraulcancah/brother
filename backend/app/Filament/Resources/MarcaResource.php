<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MarcaResource\Pages;
use App\Models\Marca;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class MarcaResource extends Resource
{
    protected static ?string $model = Marca::class;

    public static function getNavigationIcon(): string
    {
        return 'heroicon-o-tag';
    }

    public static function getNavigationLabel(): string
    {
        return 'Marcas';
    }

    public static function getPluralModelLabel(): string
    {
        return 'Marcas';
    }

    public static function getSlug(?Panel $panel = null): string
    {
        return 'marcas';
    }

    public static function getNavigationGroup(): string
    {
        return 'Catálogo';
    }

    public static function getNavigationSort(): ?int
    {
        return 1;
    }

    public static function getNavigationBadge(): ?string
    {
        return (string) static::getModel()::count();
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Tabs::make('Marca')
                    ->tabs([
                        SchemaComponents\Tabs\Tab::make('Información')
                            ->icon('heroicon-o-information-circle')
                            ->schema([
                                SchemaComponents\Section::make('Datos de la Marca')
                                    ->schema([
                                        Components\TextInput::make('nombre')
                                            ->label('Nombre')
                                            ->required()
                                            ->maxLength(255),
                                        Components\TextInput::make('logo')
                                            ->label('Logo (URL)')
                                            ->maxLength(255),
                                        Components\Toggle::make('activo')
                                            ->label('Activo')
                                            ->default(true),
                                    ])->columns(2),
                            ]),

                        SchemaComponents\Tabs\Tab::make('Sub Marcas')
                            ->icon('heroicon-o-tag')
                            ->schema([
                                Components\Repeater::make('subMarcas')
                                    ->relationship('subMarcas')
                                    ->schema([
                                        SchemaComponents\Grid::make(2)
                                            ->schema([
                                                Components\TextInput::make('nombre')
                                                    ->label('Nombre')
                                                    ->required()
                                                    ->maxLength(255),
                                                Components\Toggle::make('activo')
                                                    ->label('Activo')
                                                    ->default(true),
                                            ]),
                                    ])
                                    ->defaultItems(0)
                                    ->addActionLabel('Agregar Sub Marca')
                                    ->collapsible()
                                    ->cloneable(),
                            ]),
                    ])->columnSpanFull(),
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
                Tables\Columns\TextColumn::make('sub_marcas_count')
                    ->label('Sub-marcas')
                    ->counts('subMarcas')
                    ->sortable(),
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
            'index' => Pages\ListMarcas::route('/'),
        ];
    }
}
