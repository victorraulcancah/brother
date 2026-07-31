<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BilleteraDigitalResource\Pages;
use App\Models\BilleteraDigital;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Panel;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class BilleteraDigitalResource extends Resource
{
    protected static ?string $model = BilleteraDigital::class;

    public static function getNavigationIcon(): string { return 'heroicon-o-device-phone-mobile'; }
    public static function getNavigationLabel(): string { return 'Billeteras Digitales'; }
    public static function getPluralModelLabel(): string { return 'Billeteras Digitales'; }
    public static function getSlug(?Panel $panel = null): string { return 'billeteras-digitales'; }
    public static function getNavigationGroup(): string { return 'Tesorería'; }
    public static function getNavigationSort(): ?int { return 5; }
    public static function shouldRegisterNavigation(): bool { return false; } // Gestionado desde la página "Cuentas y Medios de Pago"

    public static function form(Schema $schema): Schema
    {
        return $schema->schema([
            SchemaComponents\Section::make('Datos de la Billetera')
                ->schema([
                    Components\Select::make('nombre')->label('Tipo')->required()
                        ->options(['Yape' => 'Yape', 'Plin' => 'Plin', 'Tunki' => 'Tunki', 'Agora' => 'Agora', 'BIM' => 'BIM', 'Ligo' => 'Ligo', 'Otro' => 'Otro']),
                    Components\Select::make('cuenta_bancaria_id')->label('Cuenta vinculada')
                        ->relationship('cuentaBancaria', 'numero_cuenta')->searchable()->preload()->nullable(),
                    Components\TextInput::make('numero_asociado')->label('Teléfono')->required()->maxLength(255),
                    Components\TextInput::make('titular')->label('Titular')->maxLength(255),
                    Components\FileUpload::make('qr')->label('QR de pago')
                        ->image()->imageEditor()->disk('public')->directory('qrs')->visibility('public')
                        ->maxSize(2048)->acceptedFileTypes(['image/png', 'image/jpeg', 'image/webp']),
                    Components\Toggle::make('activo')->label('Activo')->default(true),
                ])->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('nombre')->label('Tipo')->badge()->searchable()->sortable(),
                Tables\Columns\TextColumn::make('cuentaBancaria.numero_cuenta')->label('Cuenta vinculada')->placeholder('—'),
                Tables\Columns\TextColumn::make('numero_asociado')->label('Teléfono')->searchable(),
                Tables\Columns\TextColumn::make('titular')->label('Titular')->searchable()->placeholder('—'),
                Tables\Columns\ImageColumn::make('qr')->label('QR')->disk('public')->size(48)
                    ->extraImgAttributes(['style' => 'object-fit:cover;border-radius:6px']),
                Tables\Columns\TextColumn::make('activo')->label('Estado')->badge()
                    ->formatStateUsing(fn ($state) => $state ? 'Activo' : 'Inactivo')
                    ->color(fn ($state) => $state ? 'success' : 'gray'),
            ])
            ->headerActions([
                Actions\CreateAction::make(),
            ])
            ->actions([
                Actions\EditAction::make(),
                Actions\DeleteAction::make(),
            ]);
    }

    public static function getRelations(): array { return []; }

    public static function getPages(): array
    {
        return ['index' => Pages\ListBilleterasDigitales::route('/')];
    }
}
