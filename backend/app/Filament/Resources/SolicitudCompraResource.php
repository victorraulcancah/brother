<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SolicitudCompraResource\Pages;
use App\Models\SolicitudCompra;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class SolicitudCompraResource extends Resource
{
    protected static ?string $model = SolicitudCompra::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-document-text'; }
    public static function getNavigationLabel(): string { return 'Solicitudes'; }
    public static function getPluralModelLabel(): string { return 'Solicitudes de Compra'; }
    public static function getSlug(?Panel $panel = null): string { return 'solicitudes-compra'; }
    public static function getNavigationGroup(): string { return 'Compras'; }
    public static function getNavigationSort(): ?int { return 2; }
    public static function getNavigationBadge(): ?string { return (string) static::getModel()::count(); }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Tabs::make('Solicitud')
                    ->tabs([
                        SchemaComponents\Tabs\Tab::make('Información')
                            ->icon('heroicon-o-information-circle')
                            ->schema([
                                SchemaComponents\Section::make('Datos de la Solicitud')
                                    ->schema([
                                        Components\TextInput::make('codigo')
                                            ->label('Código')
                                            ->required()
                                            ->maxLength(255)
                                            ->unique(ignoreRecord: true),
                                        Components\DateTimePicker::make('fecha_solicitud')
                                            ->label('Fecha de Solicitud')
                                            ->required(),
                                        Components\Select::make('usuario_solicita_id')
                                            ->label('Solicitado por')
                                            ->relationship('usuarioSolicita', 'name')
                                            ->searchable()
                                            ->preload()
                                            ->required(),
                                        Components\Select::make('usuario_aprueba_id')
                                            ->label('Aprobado por')
                                            ->relationship('usuarioAprueba', 'name')
                                            ->searchable()
                                            ->preload()
                                            ->nullable(),
                                        Components\Select::make('estado')
                                            ->label('Estado')
                                            ->options([
                                                'pendiente' => 'Pendiente',
                                                'aprobada' => 'Aprobada',
                                                'rechazada' => 'Rechazada',
                                                'completada' => 'Completada',
                                            ])
                                            ->required(),
                                        Components\Textarea::make('observaciones')
                                            ->label('Observaciones')
                                            ->maxLength(5000)
                                            ->columnSpanFull(),
                                    ])->columns(2),
                            ]),
                        SchemaComponents\Tabs\Tab::make('Productos')
                            ->icon('heroicon-o-cube')
                            ->schema([
                                Components\Repeater::make('detalles')
                                    ->relationship('detalles')
                                    ->schema([
                                        SchemaComponents\Grid::make(3)
                                            ->schema([
                                                Components\Select::make('producto_id')
                                                    ->label('Producto')
                                                    ->relationship('producto', 'nombre')
                                                    ->searchable()
                                                    ->preload()
                                                    ->required()
                                                    ->live()
                                                    ->afterStateUpdated(fn($set) => $set('producto_variante_id', null)),
                                                Components\Select::make('producto_variante_id')
                                                    ->label('Variante')
                                                    ->relationship('productoVariante', 'sku_variante')
                                                    ->searchable()
                                                    ->preload()
                                                    ->nullable(),
                                                Components\TextInput::make('cantidad_solicitada')
                                                    ->label('Cant. Solicitada')
                                                    ->numeric()
                                                    ->required()
                                                    ->default(0),
                                                Components\TextInput::make('cantidad_aprobada')
                                                    ->label('Cant. Aprobada')
                                                    ->numeric()
                                                    ->nullable(),
                                            ]),
                                        Components\Textarea::make('observaciones')
                                            ->label('Observaciones')
                                            ->columnSpanFull(),
                                    ])
                                    ->defaultItems(0)
                                    ->addActionLabel('Agregar Producto')
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
                Tables\Columns\TextColumn::make('codigo')
                    ->label('Código')
                    ->badge()
                    ->color('gray')
                    ->searchable(),
                Tables\Columns\TextColumn::make('fecha_solicitud')
                    ->label('Fecha')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('usuarioSolicita.name')
                    ->label('Solicitante'),
                Tables\Columns\TextColumn::make('estado')
                    ->label('Estado')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'pendiente' => 'warning',
                        'aprobada' => 'success',
                        'rechazada' => 'danger',
                        'completada' => 'info',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Creado')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('estado')
                    ->label('Estado')
                    ->options([
                        'pendiente' => 'Pendiente',
                        'aprobada' => 'Aprobada',
                        'rechazada' => 'Rechazada',
                        'completada' => 'Completada',
                    ]),
            ])
            ->actions([
                Actions\EditAction::make()->modalWidth('3xl'),
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
            'index' => Pages\ListSolicitudesCompra::route('/'),
        ];
    }
}
