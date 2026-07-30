<?php

namespace App\Filament\Resources;

use App\Filament\Resources\NotaVentaResource\Pages;
use App\Models\MetodoPago;
use App\Models\NotaVenta;
use App\Models\ProductoPresentacion;
use App\Services\NotaVentaService;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Notifications\Notification;
use Filament\Panel;
use Filament\Resources\Resource;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Schemas\Schema;
use Filament\Tables\Table;
use Filament\Tables;
use Illuminate\Support\Facades\DB;

class NotaVentaResource extends Resource
{
    protected static ?string $model = NotaVenta::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-receipt-percent'; }
    public static function getNavigationLabel(): string { return 'Notas de Venta'; }
    public static function getPluralModelLabel(): string { return 'Notas de Venta'; }
    public static function getSlug(?Panel $panel = null): string { return 'notas-venta'; }
    public static function getNavigationGroup(): string { return 'Ventas'; }
    public static function getNavigationSort(): ?int { return 2; }
    public static function getNavigationBadge(): ?string { return (string) static::getModel()::where('estado', 'emitida')->count(); }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([

                SchemaComponents\Section::make()
                    ->compact()
                    ->schema([
                        SchemaComponents\Grid::make(12)
                            ->schema([
                                Components\DatePicker::make('fecha_emision')
                                    ->label('Fecha')
                                    ->required()
                                    ->default(now())
                                    ->columnSpan(2),

                                Components\Select::make('cliente_id')
                                    ->label('Cliente')
                                    ->relationship('cliente', 'nombre')
                                    ->searchable()
                                    ->preload()
                                    ->nullable()
                                    ->columnSpan(4),

                                Components\Select::make('almacen_id')
                                    ->label('Almacén')
                                    ->relationship('almacen', 'nombre')
                                    ->searchable()
                                    ->preload()
                                    ->required()
                                    ->live()
                                    ->afterStateUpdated(fn (callable $set) => $set('detalles', []))
                                    ->columnSpan(2),

                                Components\Select::make('vendedor_id')
                                    ->label('Vendedor')
                                    ->relationship('vendedor', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->required()
                                    ->columnSpan(2),

                                Components\Select::make('moneda')
                                    ->label('Moneda')
                                    ->options(['PEN' => 'Soles', 'USD' => 'Dólares'])
                                    ->required()
                                    ->default('PEN')
                                    ->columnSpan(2),

                                Components\Select::make('tipo_pago')
                                    ->label('Tipo de Pago')
                                    ->options(['contado' => 'Contado', 'credito' => 'Crédito'])
                                    ->required()
                                    ->default('contado')
                                    ->columnSpan(2),

                                Components\Select::make('estado')
                                    ->label('Estado')
                                    ->options([
                                        'emitida'   => 'Emitida',
                                        'en_espera' => 'En Espera',
                                        'anulada'   => 'Anulada',
                                    ])
                                    ->default('emitida')
                                    ->columnSpan(2)
                                    ->hiddenOn('create'),

                                Components\TextInput::make('serie')
                                    ->label('Serie')
                                    ->maxLength(10)
                                    ->default('NV01')
                                    ->columnSpan(1)
                                    ->hiddenOn('create'),

                                Components\TextInput::make('numero')
                                    ->label('N°')
                                    ->maxLength(10)
                                    ->columnSpan(1)
                                    ->hiddenOn('create'),

                                Components\TextInput::make('subtotal')
                                    ->label('Subtotal')
                                    ->numeric()
                                    ->prefix('S/')
                                    ->default(0)
                                    ->columnSpan(2)
                                    ->dehydrated(),

                                Components\TextInput::make('descuento_total')
                                    ->label('Descuento')
                                    ->numeric()
                                    ->default(0)
                                    ->prefix('S/')
                                    ->columnSpan(2),

                                Components\TextInput::make('total')
                                    ->label('Total')
                                    ->numeric()
                                    ->prefix('S/')
                                    ->default(0)
                                    ->columnSpan(2)
                                    ->dehydrated(),

                                Components\Textarea::make('observaciones')
                                    ->label('Observaciones')
                                    ->rows(2)
                                    ->columnSpan(12),

                                Components\Textarea::make('motivo_anulacion')
                                    ->label('Motivo de Anulación')
                                    ->rows(2)
                                    ->visible(fn ($get) => $get('estado') === 'anulada')
                                    ->columnSpan(12),
                            ]),
                    ]),

                SchemaComponents\Section::make()
                    ->compact()
                    ->description('Productos de la venta')
                    ->schema([
                        Components\Repeater::make('detalles')
                            ->relationship('detalles')
                            ->schema([
                                SchemaComponents\Grid::make(6)
                                    ->schema([
                                        Components\Select::make('producto_presentacion_id')
                                            ->label('Producto / Código')
                                            ->options(function ($get) {
                                                $almacenId = $get('../../../almacen_id');
                                                $query = ProductoPresentacion::query()
                                                    ->where('activo', true)
                                                    ->where('es_venta', true);
                                                if ($almacenId) {
                                                    $productIds = DB::table('producto_almacen_stock')
                                                        ->where('almacen_id', $almacenId)
                                                        ->where('stock_disponible', '>', 0)
                                                        ->pluck('producto_id');
                                                    $query->whereIn('producto_id', $productIds);
                                                }
                                                return $query->get()
                                                    ->mapWithKeys(fn ($pp) => [
                                                        $pp->id => $pp->nombre . ' | ' . ($pp->producto?->nombre ?? '') . ' [' . $pp->codigo_barras . ']',
                                                    ]);
                                            })
                                            ->searchable()
                                            ->required()
                                            ->live()
                                            ->afterStateUpdated(function (callable $set, $state) {
                                                $pp = ProductoPresentacion::find($state);
                                                if ($pp) {
                                                    $set('precio_unitario', $pp->precio_venta);
                                                }
                                            })
                                            ->columnSpan(2),

                                        Components\TextInput::make('cantidad')
                                            ->label('Cantidad')
                                            ->numeric()
                                            ->required()
                                            ->default(1)
                                            ->live()
                                            ->afterStateUpdated(function (callable $set, $get) {
                                                $cant = (float) $get('cantidad');
                                                $pu   = (float) $get('precio_unitario');
                                                $desc = (float) $get('descuento');
                                                $set('subtotal', round($cant * $pu - $desc, 2));
                                            })
                                            ->columnSpan(1),

                                        Components\TextInput::make('precio_unitario')
                                            ->label('Precio Unit.')
                                            ->numeric()
                                            ->required()
                                            ->default(0)
                                            ->prefix('S/')
                                            ->columnSpan(1),

                                        Components\TextInput::make('descuento')
                                            ->label('Descuento')
                                            ->numeric()
                                            ->default(0)
                                            ->prefix('S/')
                                            ->live()
                                            ->afterStateUpdated(function (callable $set, $get) {
                                                $cant = (float) $get('cantidad');
                                                $pu   = (float) $get('precio_unitario');
                                                $desc = (float) $get('descuento');
                                                $set('subtotal', round($cant * $pu - $desc, 2));
                                            })
                                            ->columnSpan(1),

                                        Components\TextInput::make('subtotal')
                                            ->label('Subtotal')
                                            ->numeric()
                                            ->required()
                                            ->default(0)
                                            ->prefix('S/')
                                            ->columnSpan(1),
                                    ]),
                            ])
                            ->defaultItems(1)
                            ->addActionLabel('+ Agregar Producto')
                            ->columnSpanFull(),
                    ]),

            ]);
    }

    public static function pagosSchema(): array
    {
        return [
            SchemaComponents\View::make('filament.pagos.cards-totales')
                ->viewData(function ($get) {
                    $total  = (float) ($get('total') ?? 0);
                    $pagado = (float) ($get('pagado') ?? 0);
                    $saldo  = $total - $pagado;
                    return [
                        'total'  => max($total, 0),
                        'pagado' => max($pagado, 0),
                        'saldo'  => max($saldo, 0),
                    ];
                }),

            Components\Repeater::make('pagos')
                ->relationship('pagos')
                ->label('Agregar Método de Pago')
                ->schema([
                    SchemaComponents\Grid::make(4)
                        ->schema([
                            Components\Select::make('metodo_pago_id')
                                ->label('Tipo de Pago')
                                ->options(fn () => MetodoPago::where('activo', true)->pluck('nombre', 'id'))
                                ->searchable()
                                ->preload()
                                ->required()
                                ->live()
                                ->afterStateUpdated(function (callable $set, $state) {
                                    $mp = MetodoPago::find($state);
                                    $set('forma_pago', $mp?->nombre ?? '');
                                })
                                ->columnSpan(1),

                            Components\Hidden::make('forma_pago'),

                            Components\DatePicker::make('fecha')
                                ->label('Fecha Pago Ref.')
                                ->required()
                                ->default(now())
                                ->columnSpan(1),

                            Components\TextInput::make('monto')
                                ->label('Monto Recibe')
                                ->numeric()
                                ->required()
                                ->prefix('S/.')
                                ->default(0)
                                ->columnSpan(1),

                            Components\TextInput::make('referencia')
                                ->label('Referencia')
                                ->placeholder('N° operación (opcional)')
                                ->maxLength(100)
                                ->columnSpan(1),
                        ]),
                ])
                ->defaultItems(1)
                ->addActionLabel('+ Agregar')
                ->reorderable(false)
                ->collapsible()
                ->collapsed(false)
                ->itemLabel(fn (array $state): ?string =>
                    isset($state['forma_pago']) && isset($state['monto'])
                        ? $state['forma_pago'] . ' - S/. ' . number_format($state['monto'], 2)
                        : null
                )
                ->columnSpanFull(),

            SchemaComponents\View::make('filament.pagos.vuelto-total')
                ->viewData(function ($get) {
                    $total  = (float) ($get('total') ?? 0);
                    $pagado = (float) ($get('pagado') ?? 0);
                    return ['vuelto' => max($pagado - $total, 0)];
                }),
        ];
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('serie')
                    ->label('Serie')
                    ->badge()
                    ->color('gray')
                    ->searchable(),
                Tables\Columns\TextColumn::make('numero')
                    ->label('Número')
                    ->searchable(),
                Tables\Columns\TextColumn::make('cliente.nombre')
                    ->label('Cliente')
                    ->searchable(),
                Tables\Columns\TextColumn::make('fecha_emision')
                    ->label('Fecha')
                    ->date()
                    ->sortable(),
                Tables\Columns\TextColumn::make('total')
                    ->label('Total')
                    ->money('PEN')
                    ->sortable(),
                Tables\Columns\TextColumn::make('tipo_pago')
                    ->label('Pago')
                    ->badge()
                    ->formatStateUsing(fn ($state) => $state === 'contado' ? 'Contado' : 'Crédito')
                    ->color(fn ($state) => $state === 'contado' ? 'success' : 'warning'),
                Tables\Columns\TextColumn::make('estado')
                    ->label('Estado')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'emitida'   => 'success',
                        'en_espera' => 'warning',
                        'anulada'   => 'danger',
                        default     => 'gray',
                    }),
                Tables\Columns\TextColumn::make('vendedor.name')
                    ->label('Vendedor'),
                Tables\Columns\TextColumn::make('almacen.nombre')
                    ->label('Almacén')
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('estado')
                    ->options(['en_espera' => 'En Espera', 'emitida' => 'Emitida', 'anulada' => 'Anulada']),
                Tables\Filters\SelectFilter::make('tipo_pago')
                    ->options(['contado' => 'Contado', 'credito' => 'Crédito']),
                Tables\Filters\SelectFilter::make('almacen_id')
                    ->label('Almacén')
                    ->relationship('almacen', 'nombre'),
                Tables\Filters\Filter::make('fecha_emision')
                    ->form([
                        Components\DatePicker::make('desde')->label('Desde'),
                        Components\DatePicker::make('hasta')->label('Hasta'),
                    ])
                    ->query(fn ($query, array $data) => $query
                        ->when($data['desde'], fn ($q) => $q->whereDate('fecha_emision', '>=', $data['desde']))
                        ->when($data['hasta'], fn ($q) => $q->whereDate('fecha_emision', '<=', $data['hasta']))),
            ])
            ->actions([
                Actions\EditAction::make()
                    ->url(fn (NotaVenta $record): string => static::getUrl('edit', ['record' => $record])),
                Actions\Action::make('anular')
                    ->label('Anular')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->modalHeading('Anular Nota de Venta')
                    ->modalDescription('¿Estás seguro de anular esta nota de venta? Se revertirá el stock.')
                    ->form([
                        Components\Textarea::make('motivo_anulacion')
                            ->label('Motivo de Anulación')
                            ->required()
                            ->maxLength(500),
                    ])
                    ->action(function (array $data, NotaVenta $record): void {
                        try {
                            app(NotaVentaService::class)->anular($record, $data['motivo_anulacion']);
                            Notification::make()
                                ->success()
                                ->title('Nota de venta anulada')
                                ->body('Stock repuesto correctamente.')
                                ->send();
                        } catch (\InvalidArgumentException $e) {
                            Notification::make()
                                ->danger()
                                ->title($e->getMessage())
                                ->send();
                        }
                    })
                    ->visible(fn (NotaVenta $record): bool =>
                        $record->estado === 'emitida' || $record->estado === 'en_espera'
                    ),
                Actions\DeleteAction::make()
                    ->visible(fn (NotaVenta $record): bool => $record->estado === 'en_espera'),
            ])
            ->bulkActions([
                Actions\BulkActionGroup::make([
                    Actions\DeleteBulkAction::make()
                        ->visible(fn () => false),
                ]),
            ])
            ->defaultSort('id', 'desc');
    }

    public static function getRelations(): array { return []; }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListNotasVenta::route('/'),
            'create' => Pages\CreateNotaVenta::route('/create'),
            'edit'   => Pages\EditNotaVenta::route('/{record}/edit'),
        ];
    }
}
