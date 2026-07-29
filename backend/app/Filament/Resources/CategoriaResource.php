<?php
namespace App\Filament\Resources;

use App\Filament\Resources\CategoriaResource\Pages;
use App\Models\Categoria;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class CategoriaResource extends Resource
{
    protected static ?string $model = Categoria::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-rectangle-group'; }
    public static function getNavigationLabel(): string { return 'Categorías'; }
    public static function getPluralModelLabel(): string { return 'Categorías'; }
    public static function getSlug(?Panel $panel = null): string { return 'categorias'; }
    public static function getNavigationGroup(): string { return 'Catálogo'; }
    public static function getNavigationSort(): ?int { return 3; }
    public static function getNavigationBadge(): ?string { return (string) static::getModel()::count(); }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Section::make('Datos de la Categoría')
                    ->schema([
                        Components\TextInput::make('nombre')
                            ->label('Nombre')
                            ->required()
                            ->maxLength(255),
                        Components\Select::make('categoria_padre_id')
                            ->label('Categoría padre')
                            ->relationship('padre', 'nombre')
                            ->searchable()
                            ->preload(),
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
                Tables\Columns\TextColumn::make('padre.nombre')
                    ->label('Categoría padre')
                    ->sortable()
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('hijos_count')
                    ->label('Sub-categorías')
                    ->counts('hijos')
                    ->sortable(),
                Tables\Columns\IconColumn::make('activo')
                    ->label('Activo')
                    ->boolean()
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('activo')->label('Estado'),
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

    public static function getRelations(): array { return []; }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCategorias::route('/'),
        ];
    }
}
