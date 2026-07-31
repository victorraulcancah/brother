<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PrestamoResource\Pages;
use App\Models\Prestamo;
use App\Models\PrestamoDevolucion;
use App\Models\ProductoPresentacion;
use App\Services\StockService;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Panel;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Support\Facades\DB;

class PrestamoResource extends Resource
{
    protected static ?string $model = Prestamo::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-hand-raised'; }
    public static function getNavigationLabel(): string { return 'Préstamos'; }
    public static function getPluralModelLabel(): string { return 'Préstamos'; }
    public static function getSlug(?Panel $panel = null): string { return 'prestamos'; }
    public static function getNavigationGroup(): string { return 'Inventario'; }
    public static function getNavigationSort(): ?int { return 6; }
    public static function getNavigationBadge(): ?string { return (string) static::getModel()::count(); }

    /** Resource sin form propio: la creación y la devolución se manejan por acciones (ver ListPrestamos). */
    public static function form(Schema $schema): Schema
    {
        return $schema->components([]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')->label('#')->sortable(),
                TextColumn::make('fecha_prestamo')
                    ->label('Fecha')
                    ->dateTime('d/m/Y H:i')
                    ->placeholder('—')
                    ->sortable(),
                TextColumn::make('tipo')
                    ->label('Tipo')
                    ->badge()
                    ->formatStateUsing(fn(string $state): string => $state === 'prestado' ? 'Presté' : 'Me prestaron')
                    ->color(fn(string $state): string => $state === 'prestado' ? 'danger' : 'success'),
                TextColumn::make('tercero')
                    ->label('Tercero')
                    ->searchable()
                    ->wrap()
                    ->limit(35),
                TextColumn::make('almacen.nombre')
                    ->label('Almacén'),
                TextColumn::make('detalles_count')
                    ->label('Ítems')
                    ->counts('detalles')
                    ->badge(),
                TextColumn::make('estado')
                    ->label('Estado')
                    ->badge()
                    ->formatStateUsing(fn(string $state): string => match ($state) {
                        'pendiente' => 'Pendiente',
                        'parcial' => 'Parcial',
                        'devuelto' => 'Devuelto',
                        default => $state,
                    })
                    ->color(fn(string $state): string => match ($state) {
                        'pendiente' => 'danger',
                        'parcial' => 'warning',
                        'devuelto' => 'success',
                        default => 'gray',
                    }),
            ])
            ->filters([
                SelectFilter::make('estado')
                    ->label('Estado')
                    ->options(['pendiente' => 'Pendiente', 'parcial' => 'Parcial', 'devuelto' => 'Devuelto']),
                SelectFilter::make('tipo')
                    ->label('Tipo')
                    ->options(['prestado' => 'Presté', 'recibido' => 'Me prestaron']),
                SelectFilter::make('almacen_id')
                    ->label('Almacén')
                    ->relationship('almacen', 'nombre'),
            ])
            ->actions([
                Action::make('gestionar')
                    ->label('Devolución')
                    ->icon('heroicon-o-arrows-right-left')
                    ->color('info')
                    ->visible(fn(Prestamo $record): bool => $record->estado !== 'devuelto')
                    ->modalHeading(fn(Prestamo $record): string => "Devolución — Préstamo #{$record->id} ({$record->tercero})")
                    ->modalWidth('xl')
                    ->modalSubmitActionLabel('Registrar devolución')
                    ->form(function (Prestamo $record): array {
                        $pendientes = static::lineasPendientes($record)->filter(fn($l) => $l['pendiente'] > 0)->values();

                        return [
                            Select::make('producto_presentacion_id')
                                ->label('Producto')
                                ->options($pendientes->mapWithKeys(fn($l) => [
                                    $l['producto_presentacion_id'] => "{$l['nombre']} (pendiente: {$l['pendiente']})",
                                ])->toArray())
                                ->default($pendientes->first()['producto_presentacion_id'] ?? null)
                                ->required(),
                            TextInput::make('cantidad')
                                ->label('Cantidad a devolver')
                                ->numeric()
                                ->minValue(0.01)
                                ->required(),
                        ];
                    })
                    ->action(function (Prestamo $record, array $data): void {
                        try {
                            $estado = static::devolver($record, (int) $data['producto_presentacion_id'], (float) $data['cantidad']);
                            Notification::make()->success()
                                ->title('Devolución registrada')
                                ->body($estado === 'devuelto' ? 'Préstamo totalmente devuelto.' : 'Devolución parcial registrada.')
                                ->send();
                        } catch (\Throwable $e) {
                            Notification::make()->danger()->title('Error en devolución')->body($e->getMessage())->send();
                        }
                    }),
            ])
            ->bulkActions([])
            ->defaultSort('id', 'desc');
    }

    /** Cantidad pendiente por devolver, por línea, restando lo ya devuelto en prestamo_devoluciones. */
    public static function lineasPendientes(Prestamo $record)
    {
        $record->loadMissing('detalles.presentacion.producto');

        return $record->detalles->map(function ($detalle) use ($record) {
            $devuelto = (float) PrestamoDevolucion::where('prestamo_id', $record->id)
                ->where('producto_presentacion_id', $detalle->producto_presentacion_id)
                ->sum('cantidad');

            return [
                'producto_presentacion_id' => $detalle->producto_presentacion_id,
                'nombre' => trim(($detalle->presentacion?->producto?->nombre ?? 'Producto') . ' — ' . ($detalle->presentacion?->nombre ?? '')),
                'prestado' => (float) $detalle->cantidad_prestada,
                'pendiente' => (float) $detalle->cantidad_prestada - $devuelto,
            ];
        });
    }

    /**
     * Crea el préstamo y mueve el stock inmediatamente:
     * - "prestado" (yo presto) → SALE del almacén.
     * - "recibido" (me prestan) → ENTRA al almacén.
     */
    public static function crearPrestamo(array $data): Prestamo
    {
        return DB::transaction(function () use ($data): Prestamo {
            $prestamo = Prestamo::create([
                'almacen_id' => $data['almacen_id'],
                'tipo' => $data['tipo'],
                'tercero' => $data['tercero'],
                'estado' => 'pendiente',
                'observaciones' => $data['observaciones'] ?? null,
                'usuario_id' => auth()->id(),
                'fecha_prestamo' => now(),
            ]);

            foreach ($data['detalles'] as $linea) {
                $presentacion = ProductoPresentacion::findOrFail($linea['producto_presentacion_id']);
                $cantidad = (float) $linea['cantidad'];

                if ($data['tipo'] === 'prestado') {
                    app(StockService::class)->salida(
                        presentacion: $presentacion,
                        almacen: $prestamo->almacen,
                        cantidadPresentacion: $cantidad,
                        costoUnitario: 0,
                        origen: 'prestamo',
                        documentoTipo: 'prestamo',
                        documentoId: $prestamo->id,
                        usuarioId: auth()->id(),
                    );
                } else {
                    app(StockService::class)->entrada(
                        presentacion: $presentacion,
                        almacen: $prestamo->almacen,
                        cantidadPresentacion: $cantidad,
                        costoUnitario: 0,
                        origen: 'prestamo',
                        documentoTipo: 'prestamo',
                        documentoId: $prestamo->id,
                        usuarioId: auth()->id(),
                    );
                }

                $prestamo->detalles()->create([
                    'producto_presentacion_id' => $presentacion->id,
                    'cantidad_prestada' => $cantidad,
                ]);
            }

            return $prestamo;
        });
    }

    /**
     * Registra la devolución de una línea:
     * - Préstamo "prestado" → la devolución ENTRA al almacén.
     * - Préstamo "recibido" → la devolución SALE del almacén (yo devuelvo lo que me prestaron).
     */
    public static function devolver(Prestamo $record, int $productoPresentacionId, float $cantidad): string
    {
        return DB::transaction(function () use ($record, $productoPresentacionId, $cantidad): string {
            $prestamo = Prestamo::lockForUpdate()->findOrFail($record->id);

            if ($prestamo->estado === 'devuelto') {
                throw new \RuntimeException('Este préstamo ya está totalmente devuelto.');
            }

            $detalle = $prestamo->detalles()->where('producto_presentacion_id', $productoPresentacionId)->firstOrFail();
            $devueltoPrevio = (float) PrestamoDevolucion::where('prestamo_id', $prestamo->id)
                ->where('producto_presentacion_id', $productoPresentacionId)
                ->sum('cantidad');
            $pendiente = (float) $detalle->cantidad_prestada - $devueltoPrevio;

            if ($cantidad > $pendiente) {
                throw new \RuntimeException("No puedes devolver más de lo pendiente ({$pendiente}).");
            }

            $presentacion = $detalle->presentacion;

            if ($prestamo->tipo === 'prestado') {
                app(StockService::class)->entrada(
                    presentacion: $presentacion,
                    almacen: $prestamo->almacen,
                    cantidadPresentacion: $cantidad,
                    costoUnitario: 0,
                    origen: 'prestamo',
                    documentoTipo: 'prestamo',
                    documentoId: $prestamo->id,
                    usuarioId: auth()->id(),
                );
            } else {
                app(StockService::class)->salida(
                    presentacion: $presentacion,
                    almacen: $prestamo->almacen,
                    cantidadPresentacion: $cantidad,
                    costoUnitario: 0,
                    origen: 'prestamo',
                    documentoTipo: 'prestamo',
                    documentoId: $prestamo->id,
                    usuarioId: auth()->id(),
                );
            }

            PrestamoDevolucion::create([
                'prestamo_id' => $prestamo->id,
                'producto_presentacion_id' => $productoPresentacionId,
                'cantidad' => $cantidad,
                'fecha' => now(),
                'usuario_id' => auth()->id(),
            ]);

            $totalPrestado = (float) $prestamo->detalles()->sum('cantidad_prestada');
            $totalDevuelto = (float) PrestamoDevolucion::where('prestamo_id', $prestamo->id)->sum('cantidad');
            $estado = $totalDevuelto >= $totalPrestado ? 'devuelto' : ($totalDevuelto > 0 ? 'parcial' : 'pendiente');

            $prestamo->update([
                'estado' => $estado,
                'fecha_devolucion' => $estado === 'devuelto' ? now() : null,
            ]);

            return $estado;
        });
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPrestamos::route('/'),
        ];
    }
}
