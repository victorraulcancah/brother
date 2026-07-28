<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CategoriaResource\Pages;
use App\Models\Categoria;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class CategoriaResource extends Resource
{
    protected static ?string $model = Categoria::class;

    public static function getNavigationIcon(): string
    {
        return 'heroicon-o-rectangle-group';
    }

    public static function getNavigationLabel(): string
    {
        return 'Categorías';
    }

    public static function getPluralModelLabel(): string
    {
        return 'Categorías';
    }

    public static function getSlug(?Panel $panel = null): string
    {
        return 'categorias';
    }

    public static function getNavigationGroup(): string
    {
        return 'Catálogo';
    }

    public static function getNavigationSort(): ?int
    {
        return 3;
    }

    public static function getNavigationBadge(): ?string
    {
        return (string) static::getModel()::count();
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                Components\Tabs::make('Categoría')
                    ->tabs([
                        Components\Tabs\Tab::make('Información')
                            ->icon('heroicon-o-information-circle')
                            ->schema([
                                Components\Section::make('Datos de la Categoría')
                                    ->schema([
                                        Components\TextInput::make('nombre')
                                            ->label('Nombre')
                                            ->required()
                                            ->maxLength(255),
                                        Components\Toggle::make('activo')
                                            ->label('Activo')
                                            ->default(true),
                                    ])->columns(2),
                            ]),

                        Components\Tabs\Tab::make('Sub Categorías')
                            ->icon('heroicon-o-rectangle-stack')
                            ->schema([
                                Components\Repeater::make('subCategorias')
                                    ->relationship('subCategorias')
                                    ->schema([
                                        Components\Grid::make(2)
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
                                    ->addActionLabel('Agregar Sub Categoría')
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
                Tables\Columns\TextColumn::make('sub_categorias_count')
                    ->label('Sub Categorías')
                    ->counts('subCategorias')
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
                Actions\EditAction::make(),
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
            'index' => Pages\ListCategorias::route('/'),
            'create' => Pages\CreateCategoria::route('/create'),
            'edit' => Pages\EditCategoria::route('/{record}/edit'),
        ];
    }
}
