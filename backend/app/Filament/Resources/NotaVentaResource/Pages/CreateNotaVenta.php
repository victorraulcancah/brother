<?php

namespace App\Filament\Resources\NotaVentaResource\Pages;

use App\Filament\Resources\NotaVentaResource;
use App\Models\Cliente;
use App\Models\MetodoPago;
use App\Models\ProductoPresentacion;
use App\Services\NotaVentaService;
use Filament\Actions\Action;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Hidden;
use Filament\Forms\Components\Placeholder;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Repeater\TableColumn;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\CreateRecord;
use Filament\Schemas\Components\Actions;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Group;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\HtmlString;

class CreateNotaVenta extends CreateRecord
{
    protected static string $resource = NotaVentaResource::class;

    protected static ?string $title = 'Nueva Nota de Venta';

    public function form(Schema $schema): Schema
    {
        return $schema->components([
            Grid::make(['default' => 1, 'xl' => 3])
                ->columnSpanFull()
                ->schema([

                    // ── COLUMNA IZQUIERDA (2/3): buscador + productos + pagos ──
                    Group::make([
                        // ── Productos ──────────────────────────────────────────
                        Section::make('Productos')
                            ->compact()
                            ->schema([
                                TextInput::make('buscador_producto')
                                    ->hiddenLabel()
                                    ->placeholder('🔍 Buscar producto por nombre o código…')
                                    ->autocomplete(false)
                                    ->dehydrated(false)
                                    ->live(debounce: 300),

                                Placeholder::make('resultados_busqueda')
                                    ->hiddenLabel()
                                    ->visible(fn (callable $get): bool => filled($get('buscador_producto')))
                                    ->content(function (callable $get): HtmlString {
                                        $busqueda = trim((string) $get('buscador_producto'));
                                        if ($busqueda === '') {
                                            return new HtmlString('');
                                        }

                                        $almacenId = $get('almacen_id');

                                        $presentaciones = ProductoPresentacion::query()
                                            ->where('activo', true)
                                            ->where('es_venta', true)
                                            ->whereHas('producto', fn ($q) => $q
                                                ->where('nombre', 'like', "%{$busqueda}%")
                                                ->orWhere('codigo', 'like', "%{$busqueda}%"))
                                            ->with('producto');

                                        if ($almacenId) {
                                            $productIds = DB::table('producto_almacen_stock')
                                                ->where('almacen_id', $almacenId)
                                                ->where('stock_disponible', '>', 0)
                                                ->pluck('producto_id');

                                            $presentaciones->whereIn('producto_id', $productIds);
                                        }

                                        $presentaciones = $presentaciones->limit(8)->get();

                                        if ($presentaciones->isEmpty()) {
                                            return new HtmlString(
                                                '<div style="padding:10px 12px;opacity:.5;font-size:.875rem">Sin coincidencias para "'
                                                . e($busqueda) . '"</div>'
                                            );
                                        }

                                        $filas = $presentaciones->map(fn (ProductoPresentacion $pp): string =>
                                            '<button type="button" wire:click="agregarProducto(' . $pp->id . ')"'
                                            . ' style="display:flex;justify-content:space-between;gap:12px;width:100%;text-align:left;'
                                            . 'padding:9px 12px;border-bottom:1px solid rgba(128,128,128,.15);cursor:pointer;font-size:.875rem">'
                                            . '<span style="font-weight:600">' . e($pp->nombre . ' - ' . ($pp->producto?->nombre ?? '')) . '</span>'
                                            . '<span style="white-space:nowrap;opacity:.65">S/ ' . number_format((float) $pp->precio_venta, 2)
                                            . ' · ' . e($pp->codigo_barras) . '</span>'
                                            . '</button>'
                                        )->implode('');

                                        return new HtmlString(
                                            '<div style="border:1px solid rgba(128,128,128,.25);border-radius:10px;overflow:hidden;margin-top:4px">'
                                            . $filas . '</div>'
                                        );
                                    }),

                                Placeholder::make('tabla_vacia')
                                    ->hiddenLabel()
                                    ->visible(fn (callable $get): bool => blank($get('detalles')))
                                    ->content(new HtmlString(
                                        '<table style="width:100%;border-collapse:collapse;font-size:.875rem">'
                                        . '<thead><tr style="border-bottom:1px solid rgba(128,128,128,.25);text-align:left;opacity:.6">'
                                        . '<th style="padding:8px 12px;font-weight:600">Producto</th>'
                                        . '<th style="padding:8px 12px;font-weight:600;width:90px">Cant.</th>'
                                        . '<th style="padding:8px 12px;font-weight:600;width:130px">Precio</th>'
                                        . '<th style="padding:8px 12px;font-weight:600;width:80px">Dto.</th>'
                                        . '<th style="padding:8px 12px;font-weight:600;width:130px">Subtotal</th>'
                                        . '</tr></thead>'
                                        . '<tbody><tr><td colspan="5" style="padding:18px 12px;text-align:center;opacity:.45">'
                                        . 'Sin productos — use el buscador de arriba'
                                        . '</td></tr></tbody></table>'
                                    )),

                                Repeater::make('detalles')
                                    ->hiddenLabel()
                                    ->minItems(0)
                                    ->defaultItems(0)
                                    ->addable(false)
                                    ->reorderable(false)
                                    ->live()
                                    ->table([
                                        TableColumn::make('Producto'),
                                        TableColumn::make('Cant.')->width('90px'),
                                        TableColumn::make('Precio')->width('130px'),
                                        TableColumn::make('Dto.')->width('80px'),
                                        TableColumn::make('Subtotal')->width('130px'),
                                    ])
                                    ->schema([
                                        Hidden::make('producto_presentacion_id'),

                                        TextInput::make('nombre_producto')
                                            ->hiddenLabel()
                                            ->readOnly()
                                            ->dehydrated(false),

                                        TextInput::make('cantidad')
                                            ->hiddenLabel()
                                            ->numeric()
                                            ->minValue(0.01)
                                            ->default(1)
                                            ->live(onBlur: true)
                                            ->afterStateUpdated(fn ($state, callable $set, callable $get) =>
                                                $set('subtotal', round(
                                                    (float) ($state ?? 1) * (float) ($get('precio_unitario') ?? 0)
                                                    - (float) ($get('descuento') ?? 0), 2)))
                                            ->required(),

                                        TextInput::make('precio_unitario')
                                            ->hiddenLabel()
                                            ->numeric()
                                            ->minValue(0)
                                            ->prefix('S/')
                                            ->live(onBlur: true)
                                            ->afterStateUpdated(fn ($state, callable $set, callable $get) =>
                                                $set('subtotal', round(
                                                    (float) ($get('cantidad') ?? 1) * (float) ($state ?? 0)
                                                    - (float) ($get('descuento') ?? 0), 2)))
                                            ->required(),

                                        TextInput::make('descuento')
                                            ->hiddenLabel()
                                            ->numeric()
                                            ->minValue(0)
                                            ->default(0)
                                            ->prefix('S/')
                                            ->live(onBlur: true)
                                            ->afterStateUpdated(fn ($state, callable $set, callable $get) =>
                                                $set('subtotal', round(
                                                    (float) ($get('cantidad') ?? 1) * (float) ($get('precio_unitario') ?? 0)
                                                    - (float) ($state ?? 0), 2))),

                                        TextInput::make('subtotal')
                                            ->hiddenLabel()
                                            ->prefix('S/')
                                            ->readOnly()
                                            ->dehydrated(false),
                                    ]),
                            ]),

                        // ── Pago al contado ──────────────────────────────────
                        Section::make('Pago')
                            ->compact()
                            ->description('Cómo se cobra esta venta')
                            ->schema([
                                Toggle::make('pago_mixto')
                                    ->label('Pago mixto (varios métodos)')
                                    ->helperText('Activalo si el cliente paga con más de un método.')
                                    ->live()
                                    ->default(false)
                                    ->columnSpanFull(),

                                // Un solo método
                                Grid::make(2)
                                    ->visible(fn (callable $get): bool => ! ($get('pago_mixto') ?? false))
                                    ->schema([
                                        Select::make('metodo_pago_id')
                                            ->label('Método de pago')
                                            ->options(fn () => MetodoPago::where('activo', true)->pluck('nombre', 'id'))
                                            ->searchable()
                                            ->default(fn () => MetodoPago::where('activo', true)->value('id'))
                                            ->live()
                                            ->columnSpanFull(),

                                        TextInput::make('pago_referencia')
                                            ->label('N° de operación')
                                            ->placeholder('Código que figura en el comprobante del pago')
                                            ->maxLength(100)
                                            ->columnSpanFull(),

                                        Hidden::make('pago_monto'),
                                    ]),

                                // Pago mixto
                                Group::make([
                                    Repeater::make('pagos_mixto')
                                        ->hiddenLabel()
                                        ->columns(2)
                                        ->defaultItems(1)
                                        ->minItems(1)
                                        ->addActionLabel('Agregar método')
                                        ->reorderable(false)
                                        ->live()
                                        ->schema([
                                            Select::make('metodo_pago_id')
                                                ->label('Método')
                                                ->options(fn () => MetodoPago::where('activo', true)->pluck('nombre', 'id'))
                                                ->searchable()
                                                ->required()
                                                ->live(),

                                            TextInput::make('monto')
                                                ->label('Monto (S/)')
                                                ->numeric()
                                                ->minValue(0.01)
                                                ->prefix('S/')
                                                ->required(),

                                            TextInput::make('referencia')
                                                ->label('N° de operación')
                                                ->placeholder('Código del comprobante del pago')
                                                ->maxLength(100)
                                                ->columnSpanFull(),
                                        ]),
                                ])
                                    ->visible(fn (callable $get): bool => $get('pago_mixto') ?? false),
                            ]),
                    ])->columnSpan(['default' => 1, 'xl' => 2]),

                    // ── COLUMNA DERECHA (1/3): comprobante + resumen ──
                    Group::make([
                        Section::make('Comprobante')
                            ->compact()
                            ->columns(2)
                            ->schema([
                                Select::make('cliente_id')
                                    ->label('Cliente')
                                    ->placeholder('Buscar por nombre…')
                                    ->searchable()
                                    ->required()
                                    ->columnSpanFull()
                                    ->getSearchResultsUsing(fn (string $search): array => Cliente::query()
                                        ->where('nombre', 'like', "%{$search}%")
                                        ->limit(20)
                                        ->get()
                                        ->mapWithKeys(fn (Cliente $c) => [
                                            $c->id => $c->nombre . ($c->numero_documento ? " — {$c->numero_documento}" : ''),
                                        ])
                                        ->toArray())
                                    ->getOptionLabelUsing(fn ($value): ?string => Cliente::find($value)?->nombre)
                                    ->createOptionForm([
                                        TextInput::make('nombre')
                                            ->label('Nombre / Razón Social')
                                            ->required()
                                            ->maxLength(255),
                                        TextInput::make('numero_documento')
                                            ->label('RUC / DNI')
                                            ->maxLength(15),
                                        TextInput::make('direccion')
                                            ->label('Dirección')
                                            ->maxLength(255),
                                        TextInput::make('telefono')
                                            ->label('Teléfono')
                                            ->tel()
                                            ->maxLength(20),
                                        TextInput::make('email')
                                            ->label('Email')
                                            ->email()
                                            ->maxLength(255),
                                    ])
                                    ->createOptionUsing(fn (array $data): int => Cliente::create($data)->id),

                                Select::make('almacen_id')
                                    ->label('Almacén')
                                    ->relationship('almacen', 'nombre')
                                    ->searchable()
                                    ->preload()
                                    ->required()
                                    ->live()
                                    ->afterStateUpdated(fn (callable $set) => $set('detalles', []))
                                    ->columnSpanFull(),

                                Select::make('vendedor_id')
                                    ->label('Vendedor')
                                    ->relationship('vendedor', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->required()
                                    ->columnSpanFull(),

                                DatePicker::make('fecha_emision')
                                    ->label('Fecha emisión')
                                    ->required()
                                    ->default(now()),

                                Select::make('moneda')
                                    ->label('Moneda')
                                    ->options(['PEN' => 'Soles (PEN)', 'USD' => 'Dólares (USD)'])
                                    ->required()
                                    ->default('PEN'),

                                Select::make('tipo_pago')
                                    ->label('Forma de pago')
                                    ->options(['contado' => 'Contado', 'credito' => 'Crédito'])
                                    ->required()
                                    ->default('contado')
                                    ->live(),

                                TextInput::make('observaciones')
                                    ->label('Observación')
                                    ->placeholder('Opcional')
                                    ->maxLength(500)
                                    ->columnSpanFull(),

                                Hidden::make('serie'),
                                Hidden::make('numero'),
                                Hidden::make('estado'),
                                Hidden::make('subtotal'),
                                Hidden::make('descuento_total'),
                                Hidden::make('total'),
                            ]),

                        Section::make('Resumen')
                            ->compact()
                            ->schema([
                                Placeholder::make('resumen')
                                    ->hiddenLabel()
                                    ->content(function (callable $get): HtmlString {
                                        $items  = $get('detalles') ?? [];
                                        $total  = collect($items)->sum(fn (array $l): float => (float) ($l['subtotal'] ?? 0));
                                        $bruto  = collect($items)->sum(
                                            fn (array $l): float => (float) ($l['cantidad'] ?? 0) * (float) ($l['precio_unitario'] ?? 0)
                                        );
                                        $desc   = collect($items)->sum(fn (array $l): float => (float) ($l['descuento'] ?? 0));
                                        $pagos  = $get('pagos_mixto') ?? [];
                                        $sumaP  = collect($pagos)->sum(fn (array $p): float => (float) ($p['monto'] ?? 0));

                                        $html = '<div style="line-height:1.7">'
                                            . '<div style="display:flex;justify-content:space-between;opacity:.7">'
                                            . '<span>Op. Gravadas:</span><span style="font-weight:600">S/ ' . number_format($bruto, 2) . '</span></div>';

                                        if ($desc > 0) {
                                            $html .= '<div style="display:flex;justify-content:space-between;opacity:.7">'
                                                . '<span>Descuento:</span><span style="font-weight:600;color:#dc2626">− S/ ' . number_format($desc, 2) . '</span></div>';
                                        }

                                        $html .= '<div style="display:flex;justify-content:space-between;opacity:.7">'
                                            . '<span>Subtotal:</span><span style="font-weight:600">S/ ' . number_format($total, 2) . '</span></div>'
                                            . '<div style="display:flex;justify-content:space-between;align-items:center;'
                                            . 'border-top:1px solid rgba(128,128,128,.25);margin-top:10px;padding-top:10px">'
                                            . '<span style="font-weight:700">IMPORTE TOTAL:</span>'
                                            . '<span style="font-weight:800;font-size:1.35rem;color:rgb(59,130,246)">S/ '
                                            . number_format($total, 2) . '</span></div>';

                                        if ($sumaP > 0) {
                                            $dif = round($total - $sumaP, 2);
                                            $colorDif = abs($dif) < 0.01 ? '#16a34a' : '#dc2626';
                                            $html .= '<div style="border-top:1px dashed rgba(128,128,128,.2);margin-top:8px;padding-top:8px">'
                                                . '<div style="display:flex;justify-content:space-between;font-size:.8rem;opacity:.7">'
                                                . '<span>Total métodos pago:</span><span style="font-weight:600">S/ ' . number_format($sumaP, 2) . '</span></div>'
                                                . '<div style="display:flex;justify-content:space-between;font-size:.8rem;color:' . $colorDif . ';font-weight:600">'
                                                . '<span>' . (abs($dif) < 0.01 ? '✓ Cuadra' : ($dif > 0 ? 'Falta S/ ' . number_format($dif, 2) : 'Excede S/ ' . number_format(abs($dif), 2))) . '</span></div>'
                                                . '</div>';
                                        }

                                        $html .= '</div>';

                                        return new HtmlString($html);
                                    }),
                            ]),
                    ])->columnSpan(1),
                ]),
        ]);
    }

    public function agregarProducto(int $presentacionId): void
    {
        $pp = ProductoPresentacion::with('producto')->find($presentacionId);
        if (! $pp) {
            return;
        }

        $items = $this->data['detalles'] ?? [];

        foreach ($items as $key => $item) {
            if ((int) ($item['producto_presentacion_id'] ?? 0) === $pp->id) {
                $cant = (float) ($items[$key]['cantidad'] ?? 1) + 1;
                $pu   = (float) ($items[$key]['precio_unitario'] ?? $pp->precio_venta);
                $desc = (float) ($items[$key]['descuento'] ?? 0);
                $items[$key]['cantidad'] = $cant;
                $items[$key]['subtotal'] = round($cant * $pu - $desc, 2);
                $this->data['detalles'] = $items;
                $this->data['buscador_producto'] = null;

                return;
            }
        }

        $items[] = [
            'producto_presentacion_id' => $pp->id,
            'nombre_producto'          => $pp->nombre . ' - ' . ($pp->producto?->nombre ?? ''),
            'cantidad'                 => 1,
            'precio_unitario'          => (float) $pp->precio_venta,
            'descuento'                => 0,
            'subtotal'                 => round((float) $pp->precio_venta, 2),
        ];

        $this->data['detalles'] = $items;
        $this->data['buscador_producto'] = null;
    }

    protected function handleRecordCreation(array $data): Model
    {
        $detalles = $data['detalles'] ?? [];

        $total = collect($detalles)->sum(fn (array $l): float => (float) ($l['subtotal'] ?? 0));
        $subtotal = collect($detalles)->sum(
            fn (array $l): float => (float) ($l['cantidad'] ?? 0) * (float) ($l['precio_unitario'] ?? 0)
        );
        $descuento = collect($detalles)->sum(fn (array $l): float => (float) ($l['descuento'] ?? 0));

        // Build pagos from simple or mixed
        $pagos = [];
        if ($data['pago_mixto'] ?? false) {
            foreach ($data['pagos_mixto'] ?? [] as $p) {
                if ((float) ($p['monto'] ?? 0) > 0) {
                    $mp = MetodoPago::find($p['metodo_pago_id']);
                    $pagos[] = [
                        'metodo_pago_id' => $p['metodo_pago_id'],
                        'forma_pago'     => $mp?->nombre ?? '',
                        'monto'          => (float) $p['monto'],
                        'fecha'          => $data['fecha_emision'],
                        'referencia'     => $p['referencia'] ?? null,
                    ];
                }
            }
        } elseif ($data['metodo_pago_id'] ?? null) {
            $mp = MetodoPago::find($data['metodo_pago_id']);
            $pagos[] = [
                'metodo_pago_id' => $data['metodo_pago_id'],
                'forma_pago'     => $mp?->nombre ?? '',
                'monto'          => $total,
                'fecha'          => $data['fecha_emision'],
                'referencia'     => $data['pago_referencia'] ?? null,
            ];
        }

        $payload = [
            'fecha_emision'   => $data['fecha_emision'],
            'cliente_id'      => $data['cliente_id'] ?? null,
            'almacen_id'      => $data['almacen_id'],
            'vendedor_id'     => $data['vendedor_id'],
            'moneda'          => $data['moneda'] ?? 'PEN',
            'tipo_pago'       => $data['tipo_pago'] ?? 'contado',
            'subtotal'        => $subtotal,
            'descuento_total' => $descuento,
            'total'           => $total,
            'observaciones'   => $data['observaciones'] ?? null,
            'detalles'        => array_map(fn ($d) => [
                'producto_presentacion_id' => $d['producto_presentacion_id'],
                'cantidad'                 => (float) $d['cantidad'],
                'precio_unitario'          => (float) $d['precio_unitario'],
                'descuento'                => (float) ($d['descuento'] ?? 0),
                'subtotal'                 => (float) $d['subtotal'],
            ], $detalles),
            'pagos'           => $pagos,
        ];

        return app(NotaVentaService::class)->crear($payload);
    }

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
