<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ProductoResource\Pages;
use App\Models\Producto;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class ProductoResource extends Resource
{
    protected static ?string $model = Producto::class;

    public static function getNavigationIcon(): string
    {
        return 'heroicon-o-cube';
    }

    public static function getNavigationLabel(): string
    {
        return 'Productos';
    }

    public static function getPluralModelLabel(): string
    {
        return 'Productos';
    }

    public static function getSlug(?Panel $panel = null): string
    {
        return 'productos';
    }

    public static function getNavigationGroup(): string
    {
        return 'Catálogo';
    }

    public static function getNavigationSort(): ?int
    {
        return 8;
    }

    public static function getNavigationBadge(): ?string
    {
        return (string) static::getModel()::count();
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Tabs::make('Producto')
                    ->tabs([
                        SchemaComponents\Tabs\Tab::make('Información General')
                            ->icon('heroicon-o-information-circle')
                            ->schema([
                                SchemaComponents\Section::make('Identificación')
                                    ->schema([
                                        Components\TextInput::make('codigo')
                                            ->label('Código / SKU')
                                            ->required()
                                            ->maxLength(255)
                                            ->unique(ignoreRecord: true),
                                        Components\TextInput::make('nombre')
                                            ->label('Nombre')
                                            ->required()
                                            ->maxLength(255),
                                    ])->columns(2),

                                SchemaComponents\Section::make('Clasificación')
                                    ->schema([
                                        Components\Select::make('marca_id')
                                            ->label('Marca')
                                            ->relationship('marca', 'nombre')
                                            ->searchable()
                                            ->preload()
                                            ->required()
                                            ->live()
                                            ->afterStateUpdated(fn(Components\Select $component) => $component->getContainer()->getComponent('sub_marca_id')?->state(null)),
                                        Components\Select::make('sub_marca_id')
                                            ->label('Sub-marca')
                                            ->relationship('subMarca', 'nombre', fn($query, Components\Get $get) => $query->where('marca_id', $get('marca_id')))
                                            ->searchable()
                                            ->preload(),
                                        Components\Select::make('categoria_id')
                                            ->label('Categoría')
                                            ->relationship('categoria', 'nombre')
                                            ->searchable()
                                            ->preload(),
                                        Components\Select::make('unidad_medida_id')
                                            ->label('Unidad de Medida')
                                            ->relationship('unidadMedida', 'nombre')
                                            ->searchable()
                                            ->preload()
                                            ->required(),
                                    ])->columns(2),

                                SchemaComponents\Section::make('Precio y Configuración')
                                    ->schema([
                                        Components\TextInput::make('precio_base')
                                            ->label('Precio Base')
                                            ->numeric()
                                            ->required()
                                            ->default(0)
                                            ->prefix('S/'),
                                        Components\Toggle::make('afecto_igv')
                                            ->label('Afecto a IGV')
                                            ->default(true),
                                        Components\Textarea::make('descripcion')
                                            ->label('Descripción')
                                            ->maxLength(5000)
                                            ->columnSpanFull(),
                                        Components\Toggle::make('activo')
                                            ->label('Producto Activo')
                                            ->default(true),
                                    ])->columns(2),
                            ]),

                        SchemaComponents\Tabs\Tab::make('Variantes')
                            ->icon('heroicon-o-variable')
                            ->schema([
                                Components\Repeater::make('variantes')
                                    ->relationship('variantes')
                                    ->schema([
                                        SchemaComponents\Grid::make(3)
                                            ->schema([
                                                Components\TextInput::make('sku_variante')
                                                    ->label('SKU Variante')
                                                    ->required()
                                                    ->maxLength(255),
                                                Components\TextInput::make('precio_diferencial')
                                                    ->label('Precio Diferencial')
                                                    ->numeric()
                                                    ->default(0)
                                                    ->prefix('S/'),
                                                Components\TextInput::make('stock')
                                                    ->label('Stock')
                                                    ->numeric()
                                                    ->default(0)
                                                    ->integer(),
                                            ]),
                                        Components\Select::make('atributoValores')
                                            ->label('Valores de Atributos')
                                            ->relationship('atributoValores', 'valor')
                                            ->multiple()
                                            ->searchable()
                                            ->preload(),
                                    ])
                                    ->defaultItems(0)
                                    ->addActionLabel('Agregar variante')
                                    ->collapsible()
                                    ->cloneable(),
                            ]),

                        SchemaComponents\Tabs\Tab::make('Imágenes')
                            ->icon('heroicon-o-photo')
                            ->schema([
                                Components\Repeater::make('imagenes')
                                    ->relationship('imagenes')
                                    ->schema([
                                        SchemaComponents\Grid::make(3)
                                            ->schema([
                                                Components\TextInput::make('url')
                                                    ->label('URL de la Imagen')
                                                    ->required()
                                                    ->maxLength(255),
                                                Components\TextInput::make('orden')
                                                    ->label('Orden')
                                                    ->numeric()
                                                    ->default(0)
                                                    ->integer(),
                                                Components\Checkbox::make('es_principal')
                                                    ->label('Imagen Principal'),
                                            ]),
                                    ])
                                    ->defaultItems(0)
                                    ->addActionLabel('Agregar imagen')
                                    ->collapsible()
                                    ->reorderable()
                                    ->cloneable(),
                            ]),
                    ])->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('codigo')
                    ->label('Código')
                    ->searchable()
                    ->sortable()
                    ->badge()
                    ->color('gray'),
                Tables\Columns\TextColumn::make('nombre')
                    ->label('Nombre')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('marca.nombre')
                    ->label('Marca')
                    ->sortable(),
                Tables\Columns\TextColumn::make('categoria.nombre')
                    ->label('Categoría')
                    ->sortable(),
                Tables\Columns\TextColumn::make('precio_base')
                    ->label('Precio Base')
                    ->money('PEN')
                    ->sortable(),
                Tables\Columns\IconColumn::make('afecto_igv')
                    ->label('IGV')
                    ->boolean()
                    ->sortable(),
                Tables\Columns\IconColumn::make('activo')
                    ->label('Activo')
                    ->boolean()
                    ->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('marca_id')
                    ->relationship('marca', 'nombre')
                    ->label('Marca'),
                Tables\Filters\SelectFilter::make('categoria_id')
                    ->relationship('categoria', 'nombre')
                    ->label('Categoría'),
                Tables\Filters\TernaryFilter::make('activo')
                    ->label('Estado'),
                Tables\Filters\TernaryFilter::make('afecto_igv')
                    ->label('Afecto a IGV'),
            ])
            ->actions([
                Actions\EditAction::make()->modalWidth('screen'),
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
            'index' => Pages\ListProductos::route('/'),
        ];
    }
}
