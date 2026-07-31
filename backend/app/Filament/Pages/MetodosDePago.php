<?php

namespace App\Filament\Pages;

use App\Models\Banco;
use App\Models\BilleteraDigital;
use App\Models\CuentaBancaria;
use App\Models\TarjetaBancaria;
use Filament\Actions\Action;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Filament\Tables\Table;

class MetodosDePago extends Page implements HasTable
{
    use InteractsWithTable;

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-credit-card';
    protected static ?string $navigationLabel = 'Cuentas y Medios de Pago';
    protected static ?string $title = 'Cuentas y Medios de Pago';
    protected static string|\UnitEnum|null $navigationGroup = 'Tesorería';
    protected static ?int $navigationSort = 2;
    protected string $view = 'filament.pages.metodos-de-pago';

    public static function getSlug(?\Filament\Panel $panel = null): string
    {
        return 'metodos-de-pago';
    }

    public string $tab = 'bancos';

    public function updatedTab(): void
    {
        $this->resetTable();
    }

    public function table(Table $table): Table
    {
        return match ($this->tab) {
            'cuentas' => $this->cuentasTable($table),
            'tarjetas' => $this->tarjetasTable($table),
            'billeteras' => $this->billeterasTable($table),
            default => $this->bancosTable($table),
        };
    }

    // ── Bancos ──────────────────────────────────────────────────────────────

    protected function bancoForm(): array
    {
        return [
            TextInput::make('nombre')->label('Nombre')->required()->maxLength(255),
        ];
    }

    protected function bancosTable(Table $table): Table
    {
        return $table
            ->query(Banco::query())
            ->columns([
                TextColumn::make('nombre')->label('Nombre')->searchable()->sortable(),
                TextColumn::make('cuentas_count')->label('Cuentas')->counts('cuentas'),
            ])
            ->actions([
                EditAction::make('editar')
                    ->icon('heroicon-o-pencil')->color('primary')
                    ->modalWidth('lg')
                    ->form($this->bancoForm())
                    ->fillForm(fn (Banco $record): array => ['nombre' => $record->nombre])
                    ->action(function (Banco $record, array $data): void {
                        $record->update($data);
                        Notification::make()->success()->title('Banco actualizado')->send();
                    }),
                DeleteAction::make('eliminar'),
            ]);
    }

    // ── Cuentas Bancarias ───────────────────────────────────────────────────

    protected function cuentaForm(): array
    {
        return [
            Select::make('banco_id')->label('Banco')->required()
                ->options(fn () => Banco::orderBy('nombre')->pluck('nombre', 'id'))
                ->searchable(),
            Select::make('tipo_cuenta')->label('Tipo')->required()
                ->options(['corriente' => 'Corriente', 'ahorros' => 'Ahorros']),
            Select::make('moneda')->label('Moneda')->required()
                ->options(['PEN' => 'Soles (PEN)', 'USD' => 'Dólares (USD)']),
            TextInput::make('numero_cuenta')->label('N° Cuenta')->required()->maxLength(255),
            TextInput::make('cci')->label('CCI')->maxLength(255),
            Toggle::make('activo')->label('Activo')->default(true),
        ];
    }

    protected function cuentasTable(Table $table): Table
    {
        return $table
            ->query(CuentaBancaria::query()->with('banco'))
            ->columns([
                TextColumn::make('banco.nombre')->label('Banco')->sortable(),
                TextColumn::make('numero_cuenta')->label('N° Cuenta')->searchable(),
                TextColumn::make('cci')->label('CCI')->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('moneda')->label('Moneda')->badge(),
                TextColumn::make('tipo_cuenta')->label('Tipo')->badge()
                    ->formatStateUsing(fn ($state) => $state === 'corriente' ? 'Corriente' : 'Ahorros'),
                IconColumn::make('activo')->label('Activo')->boolean(),
                TextColumn::make('tarjetas_count')->label('Tarjetas')->counts('tarjetas'),
            ])
            ->filters([
                \Filament\Tables\Filters\SelectFilter::make('banco_id')->label('Banco')->relationship('banco', 'nombre'),
                \Filament\Tables\Filters\SelectFilter::make('moneda')->options(['PEN' => 'Soles', 'USD' => 'Dólares']),
            ])
            ->actions([
                EditAction::make('editar')
                    ->icon('heroicon-o-pencil')->color('primary')
                    ->modalWidth('2xl')
                    ->form($this->cuentaForm())
                    ->fillForm(fn (CuentaBancaria $record): array => [
                        'banco_id' => $record->banco_id,
                        'tipo_cuenta' => $record->tipo_cuenta,
                        'moneda' => $record->moneda,
                        'numero_cuenta' => $record->numero_cuenta,
                        'cci' => $record->cci,
                        'activo' => (bool) $record->activo,
                    ])
                    ->action(function (CuentaBancaria $record, array $data): void {
                        $record->update($data);
                        Notification::make()->success()->title('Cuenta actualizada')->send();
                    }),
                DeleteAction::make('eliminar'),
            ]);
    }

    // ── Tarjetas ────────────────────────────────────────────────────────────

    protected function tarjetaForm(): array
    {
        return [
            Select::make('cuenta_bancaria_id')->label('Cuenta Bancaria')->required()
                ->options(fn () => CuentaBancaria::where('activo', true)->with('banco')->get()
                    ->mapWithKeys(fn ($c) => [$c->id => ($c->banco?->nombre . ' - ' . $c->numero_cuenta)])),
            Select::make('tipo_tarjeta')->label('Tipo')->required()
                ->options(['debito' => 'Débito', 'credito' => 'Crédito'])->live(),
            TextInput::make('nombre_referencial')->label('Nombre Referencial')->required()->maxLength(255),
            TextInput::make('numero_enmascarado')->label('N° Tarjeta (últ. 4 díg.)')
                ->required()->maxLength(20)->helperText('Solo los últimos 4 dígitos'),
            Select::make('marca')->label('Marca')->required()
                ->options(['Visa' => 'Visa', 'Mastercard' => 'Mastercard', 'Amex' => 'American Express', 'Diners' => 'Diners']),
            TextInput::make('fecha_vencimiento')->label('Vencimiento')->placeholder('mm/aaaa')->maxLength(10),
            TextInput::make('titular')->label('Titular')->maxLength(255),
            TextInput::make('limite_credito')->label('Límite de Crédito')->numeric()->prefix('S/')
                ->visible(fn ($get) => $get('tipo_tarjeta') === 'credito'),
            Select::make('estado')->label('Estado')->required()
                ->options(['activa' => 'Activa', 'bloqueada' => 'Bloqueada', 'vencida' => 'Vencida'])
                ->default('activa'),
        ];
    }

    protected function tarjetasTable(Table $table): Table
    {
        return $table
            ->query(TarjetaBancaria::query()->with('cuentaBancaria.banco'))
            ->columns([
                TextColumn::make('nombre_referencial')->label('Nombre')->searchable(),
                TextColumn::make('numero_enmascarado')->label('N° Tarjeta')->searchable(),
                TextColumn::make('marca')->label('Marca')->badge(),
                TextColumn::make('tipo_tarjeta')->label('Tipo')->badge()
                    ->color(fn ($state) => $state === 'debito' ? 'info' : 'warning'),
                TextColumn::make('cuentaBancaria.banco.nombre')->label('Banco'),
                TextColumn::make('cuentaBancaria.numero_cuenta')->label('Cuenta'),
                TextColumn::make('estado')->label('Estado')->badge()
                    ->color(fn ($state) => match ($state) { 'activa' => 'success', 'bloqueada' => 'danger', 'vencida' => 'gray', default => 'gray' }),
            ])
            ->filters([
                \Filament\Tables\Filters\SelectFilter::make('tipo_tarjeta')->options(['debito' => 'Débito', 'credito' => 'Crédito']),
                \Filament\Tables\Filters\SelectFilter::make('estado')->options(['activa' => 'Activa', 'bloqueada' => 'Bloqueada', 'vencida' => 'Vencida']),
            ])
            ->actions([
                EditAction::make('editar')
                    ->icon('heroicon-o-pencil')->color('primary')
                    ->modalWidth('3xl')
                    ->form($this->tarjetaForm())
                    ->fillForm(fn (TarjetaBancaria $record): array => [
                        'cuenta_bancaria_id' => $record->cuenta_bancaria_id,
                        'tipo_tarjeta' => $record->tipo_tarjeta,
                        'nombre_referencial' => $record->nombre_referencial,
                        'numero_enmascarado' => $record->numero_enmascarado,
                        'marca' => $record->marca,
                        'fecha_vencimiento' => $record->fecha_vencimiento,
                        'titular' => $record->titular,
                        'limite_credito' => $record->limite_credito,
                        'estado' => $record->estado,
                    ])
                    ->action(function (TarjetaBancaria $record, array $data): void {
                        $record->update($data);
                        Notification::make()->success()->title('Tarjeta actualizada')->send();
                    }),
                DeleteAction::make('eliminar'),
            ]);
    }

    // ── Billeteras Digitales ────────────────────────────────────────────────

    protected function billeteraForm(): array
    {
        return [
            TextInput::make('nombre')->label('Nombre')->required()->maxLength(255),
            TextInput::make('numero_asociado')->label('N° Asociado')->required()->maxLength(255),
            Toggle::make('requiere_numero_operacion')->label('Requiere n° operación'),
            Toggle::make('requiere_captura')->label('Requiere captura'),
            Toggle::make('activo')->label('Activo')->default(true),
        ];
    }

    protected function billeterasTable(Table $table): Table
    {
        return $table
            ->query(BilleteraDigital::query())
            ->columns([
                TextColumn::make('nombre')->label('Nombre')->searchable()->sortable(),
                TextColumn::make('numero_asociado')->label('N° Asociado')->searchable(),
                IconColumn::make('requiere_numero_operacion')->label('N° Oper.')->boolean(),
                IconColumn::make('requiere_captura')->label('Captura')->boolean(),
                IconColumn::make('activo')->label('Activo')->boolean(),
            ])
            ->actions([
                EditAction::make('editar')
                    ->icon('heroicon-o-pencil')->color('primary')
                    ->modalWidth('lg')
                    ->form($this->billeteraForm())
                    ->fillForm(fn (BilleteraDigital $record): array => [
                        'nombre' => $record->nombre,
                        'numero_asociado' => $record->numero_asociado,
                        'requiere_numero_operacion' => (bool) $record->requiere_numero_operacion,
                        'requiere_captura' => (bool) $record->requiere_captura,
                        'activo' => (bool) $record->activo,
                    ])
                    ->action(function (BilleteraDigital $record, array $data): void {
                        $record->update($data);
                        Notification::make()->success()->title('Billetera actualizada')->send();
                    }),
                DeleteAction::make('eliminar'),
            ]);
    }

    // ── Acción de creación (según pestaña activa) ───────────────────────────

    protected function getHeaderActions(): array
    {
        return [
            Action::make('crear')
                ->label(fn (): string => match ($this->tab) {
                    'cuentas' => 'Nueva Cuenta',
                    'tarjetas' => 'Nueva Tarjeta',
                    'billeteras' => 'Nueva Billetera',
                    default => 'Nuevo Banco',
                })
                ->icon('heroicon-o-plus')
                ->color('primary')
                ->modalWidth(fn (): string => match ($this->tab) {
                    'cuentas' => '2xl',
                    'tarjetas' => '3xl',
                    default => 'lg',
                })
                ->form(fn (): array => match ($this->tab) {
                    'cuentas' => $this->cuentaForm(),
                    'tarjetas' => $this->tarjetaForm(),
                    'billeteras' => $this->billeteraForm(),
                    default => $this->bancoForm(),
                })
                ->action(function (array $data): void {
                    match ($this->tab) {
                        'cuentas' => CuentaBancaria::create($data),
                        'tarjetas' => TarjetaBancaria::create($data),
                        'billeteras' => BilleteraDigital::create($data),
                        default => Banco::create($data),
                    };

                    Notification::make()->success()->title('Creado correctamente')->send();
                    $this->resetTable();
                }),
        ];
    }
}
