<?php

namespace App\Filament\Resources;

use App\Filament\Resources\TomaInventarioResource\Pages;
use App\Models\TomaInventario;
use App\Services\StockService;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Notifications\Notification;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Facades\DB;

class TomaInventarioResource extends Resource
{
    protected static ?string $model = TomaInventario::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-clipboard-document-list'; }
    public static function getNavigationLabel(): string { return 'Tomas de Inventario'; }
    public static function getPluralModelLabel(): string { return 'Tomas de Inventario'; }
    public static function getSlug(?Panel $panel = null): string { return 'tomas-inventario'; }
    public static function getNavigationGroup(): string { return 'Inventario'; }
    public static function getNavigationSort(): ?int { return 5; }
    public static function getNavigationBadge(): ?string { return (string) static::getModel()::count(); }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Tabs::make('Toma de Inventario')
                    ->tabs([
                        SchemaComponents\Tabs\Tab::make('Información')
                            ->icon('heroicon-o-information-circle')
                            ->schema([
                                SchemaComponents\Section::make('Datos de la Toma')
                                    ->schema([
                                        Components\Select::make('almacen_id')
                                            ->label('Almacén')
                                            ->relationship('almacen', 'nombre')
                                            ->searchable()
                                            ->preload()
                                            ->required(),
                                        Components\DateTimePicker::make('fecha')
                                            ->label('Fecha')
                                            ->required(),
                                        Components\Select::make('estado')
                                            ->label('Estado')
                                            ->options([
                                                'en_proceso' => 'En Proceso',
                                                'cerrado' => 'Cerrado',
                                            ])
                                            ->required(),
                                        Components\Select::make('usuario_id')
                                            ->label('Responsable')
                                            ->relationship('usuario', 'name')
                                            ->searchable()
                                            ->preload()
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
                                                Components\Select::make('producto_presentacion_id')
                                                    ->label('Producto / Presentación')
                                                    ->relationship('presentacion', 'nombre')
                                                    ->getOptionLabelFromRecordUsing(fn($record) => trim(($record->producto?->nombre ?? '') . ' — ' . $record->nombre, ' —'))
                                                    ->searchable()
                                                    ->preload()
                                                    ->required()
                                                    ->columnSpanFull(),
                                                Components\TextInput::make('stock_sistema')
                                                    ->label('Stock en Sistema')
                                                    ->numeric()
                                                    ->required()
                                                    ->default(0)
                                                    ->live()
                                                    ->afterStateUpdated(fn($state, callable $set, callable $get) => $set('diferencia', (float) $get('stock_contado') - (float) $state)),
                                                Components\TextInput::make('stock_contado')
                                                    ->label('Stock Contado')
                                                    ->numeric()
                                                    ->required()
                                                    ->default(0)
                                                    ->live()
                                                    ->afterStateUpdated(fn($state, callable $set, callable $get) => $set('diferencia', (float) $state - (float) $get('stock_sistema'))),
                                                Components\TextInput::make('diferencia')
                                                    ->label('Diferencia')
                                                    ->numeric()
                                                    ->default(0)
                                                    ->disabled()
                                                    ->dehydrated(),
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
                Tables\Columns\TextColumn::make('id')
                    ->label('#')
                    ->sortable(),
                Tables\Columns\TextColumn::make('almacen.nombre')
                    ->label('Almacén')
                    ->sortable(),
                Tables\Columns\TextColumn::make('fecha')
                    ->label('Fecha')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('estado')
                    ->label('Estado')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'en_proceso' => 'warning',
                        'cerrado' => 'success',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('usuario.name')
                    ->label('Responsable'),
                Tables\Columns\TextColumn::make('detalles_count')
                    ->label('Productos')
                    ->counts('detalles'),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Creado')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('estado')
                    ->label('Estado')
                    ->options(['en_proceso' => 'En Proceso', 'cerrado' => 'Cerrado']),
                Tables\Filters\SelectFilter::make('almacen_id')
                    ->label('Almacén')
                    ->relationship('almacen', 'nombre'),
            ])
            ->actions([
                Actions\Action::make('cerrar')
                    ->label('Cerrar conteo')
                    ->icon('heroicon-o-lock-closed')
                    ->color('success')
                    ->visible(fn(TomaInventario $record): bool => $record->estado === 'en_proceso')
                    ->requiresConfirmation()
                    ->modalDescription('Se aplicará la diferencia de cada línea contada al stock del almacén. Esta acción no se puede deshacer.')
                    ->action(function (TomaInventario $record): void {
                        try {
                            DB::transaction(function () use ($record): void {
                                $record->loadMissing(['detalles.presentacion', 'almacen']);

                                foreach ($record->detalles as $detalle) {
                                    $diferencia = (float) $detalle->diferencia;
                                    if ($diferencia === 0.0 || ! $detalle->presentacion) {
                                        continue;
                                    }

                                    $service = app(StockService::class);
                                    $factor = (float) $detalle->presentacion->factor_conversion ?: 1;
                                    $cantidadPresentacion = abs($diferencia) / $factor;

                                    if ($diferencia > 0) {
                                        $service->entrada(
                                            presentacion: $detalle->presentacion,
                                            almacen: $record->almacen,
                                            cantidadPresentacion: $cantidadPresentacion,
                                            costoUnitario: 0,
                                            origen: 'toma_inventario',
                                            documentoTipo: 'toma_inventario',
                                            documentoId: $record->id,
                                            usuarioId: auth()->id(),
                                        );
                                    } else {
                                        $service->salida(
                                            presentacion: $detalle->presentacion,
                                            almacen: $record->almacen,
                                            cantidadPresentacion: $cantidadPresentacion,
                                            costoUnitario: 0,
                                            origen: 'toma_inventario',
                                            documentoTipo: 'toma_inventario',
                                            documentoId: $record->id,
                                            usuarioId: auth()->id(),
                                        );
                                    }
                                }

                                $record->update(['estado' => 'cerrado']);
                            });

                            Notification::make()->success()->title('Conteo cerrado')->body('El stock se actualizó según las diferencias contadas.')->send();
                        } catch (\Throwable $e) {
                            Notification::make()->danger()->title('No se pudo cerrar')->body($e->getMessage())->send();
                        }
                    }),
                Actions\EditAction::make()
                    ->modalWidth('3xl')
                    ->visible(fn(TomaInventario $record): bool => $record->estado === 'en_proceso'),
                Actions\DeleteAction::make()
                    ->visible(fn(TomaInventario $record): bool => $record->estado === 'en_proceso'),
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
            'index' => Pages\ListTomasInventario::route('/'),
        ];
    }
}
