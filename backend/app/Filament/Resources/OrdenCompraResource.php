<?php

namespace App\Filament\Resources;

use App\Filament\Resources\OrdenCompraResource\Pages;
use App\Models\OrdenCompra;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class OrdenCompraResource extends Resource
{
    protected static ?string $model = OrdenCompra::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-shopping-cart'; }
    public static function getNavigationLabel(): string { return 'Órdenes'; }
    public static function getPluralModelLabel(): string { return 'Órdenes de Compra'; }
    public static function getSlug(?Panel $panel = null): string { return 'ordenes-compra'; }
    public static function getNavigationGroup(): string { return 'Compras'; }
    public static function getNavigationSort(): ?int { return 3; }
    public static function getNavigationBadge(): ?string { return (string) static::getModel()::count(); }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Tabs::make('Orden de Compra')
                    ->tabs([
                        SchemaComponents\Tabs\Tab::make('Información')
                            ->icon('heroicon-o-information-circle')
                            ->schema([
                                SchemaComponents\Section::make('Datos de la Orden')
                                    ->schema([
                                        Components\TextInput::make('codigo')
                                            ->label('Código')
                                            ->required()
                                            ->maxLength(255)
                                            ->unique(ignoreRecord: true),
                                        Components\Select::make('proveedor_id')
                                            ->label('Proveedor')
                                            ->relationship('proveedor', 'nombre')
                                            ->searchable()
                                            ->preload()
                                            ->required(),
                                        Components\Select::make('solicitud_id')
                                            ->label('Solicitud de Compra')
                                            ->relationship('solicitud', 'codigo')
                                            ->searchable()
                                            ->preload()
                                            ->nullable(),
                                        Components\DateTimePicker::make('fecha_emision')
                                            ->label('Fecha de Emisión')
                                            ->required(),
                                        Components\DateTimePicker::make('fecha_entrega_estimada')
                                            ->label('Fecha Entrega Estimada')
                                            ->nullable(),
                                        Components\Select::make('estado')
                                            ->label('Estado')
                                            ->options([
                                                'pendiente' => 'Pendiente',
                                                'aprobada' => 'Aprobada',
                                                'enviada' => 'Enviada',
                                                'parcial' => 'Parcial',
                                                'completada' => 'Completada',
                                                'anulada' => 'Anulada',
                                            ])
                                            ->required(),
                                        Components\Select::make('usuario_crea_id')
                                            ->label('Creado por')
                                            ->relationship('usuarioCrea', 'name')
                                            ->searchable()
                                            ->preload()
                                            ->required(),
                                        Components\Select::make('condicion_pago')
                                            ->label('Condición de Pago')
                                            ->options([
                                                'contado' => 'Contado',
                                                'credito_15' => 'Crédito 15 días',
                                                'credito_30' => 'Crédito 30 días',
                                                'credito_60' => 'Crédito 60 días',
                                            ]),
                                        Components\Select::make('moneda')
                                            ->label('Moneda')
                                            ->options([
                                                'PEN' => 'Soles (PEN)',
                                                'USD' => 'Dólares (USD)',
                                            ])
                                            ->required()
                                            ->live(),
                                        Components\TextInput::make('tipo_cambio')
                                            ->label('Tipo de Cambio')
                                            ->numeric()
                                            ->required()
                                            ->default(1),
                                        Components\Textarea::make('observaciones')
                                            ->label('Observaciones')
                                            ->maxLength(5000)
                                            ->columnSpanFull(),
                                    ])->columns(3),
                            ]),
                        SchemaComponents\Tabs\Tab::make('Productos')
                            ->icon('heroicon-o-cube')
                            ->schema([
                                Components\Repeater::make('detalles')
                                    ->relationship('detalles')
                                    ->schema([
                                        SchemaComponents\Grid::make(4)
                                            ->schema([
                                                Components\Select::make('producto_presentacion_id')
                                                    ->label('Producto / Presentación')
                                                    ->relationship('presentacion', 'nombre')
                                                    ->getOptionLabelFromRecordUsing(fn($record) => trim(($record->producto?->nombre ?? '') . ' — ' . $record->nombre, ' —'))
                                                    ->searchable()
                                                    ->preload()
                                                    ->required()
                                                    ->columnSpan(2),
                                                Components\TextInput::make('cantidad')
                                                    ->label('Cantidad')
                                                    ->numeric()
                                                    ->required()
                                                    ->default(1),
                                                Components\TextInput::make('precio_unitario')
                                                    ->label('Precio Unit.')
                                                    ->numeric()
                                                    ->required()
                                                    ->default(0)
                                                    ->prefix('S/'),
                                            ]),
                                        SchemaComponents\Grid::make(3)
                                            ->schema([
                                                Components\TextInput::make('descuento')
                                                    ->label('Descuento')
                                                    ->numeric()
                                                    ->default(0)
                                                    ->prefix('S/'),
                                                Components\TextInput::make('subtotal')
                                                    ->label('Subtotal')
                                                    ->numeric()
                                                    ->required()
                                                    ->default(0)
                                                    ->prefix('S/'),
                                            ]),
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
                Tables\Columns\TextColumn::make('proveedor.nombre')
                    ->label('Proveedor')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('fecha_emision')
                    ->label('Emisión')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('estado')
                    ->label('Estado')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'pendiente' => 'warning',
                        'aprobada' => 'success',
                        'enviada' => 'info',
                        'parcial' => 'warning',
                        'completada' => 'success',
                        'anulada' => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('moneda')
                    ->label('Moneda')
                    ->badge()
                    ->color('gray'),
                Tables\Columns\TextColumn::make('usuarioCrea.name')
                    ->label('Creado por'),
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
                        'enviada' => 'Enviada',
                        'parcial' => 'Parcial',
                        'completada' => 'Completada',
                        'anulada' => 'Anulada',
                    ]),
                Tables\Filters\SelectFilter::make('proveedor_id')
                    ->label('Proveedor')
                    ->relationship('proveedor', 'nombre'),
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
            'index' => Pages\ListOrdenesCompra::route('/'),
        ];
    }
}
