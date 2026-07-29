<?php

namespace App\Filament\Resources;

use App\Filament\Resources\EmpresaResource\Pages;
use App\Models\Empresa;
use Filament\Actions;
use Filament\Forms\Components;
use Filament\Schemas\Components as SchemaComponents;
use Filament\Panel;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class EmpresaResource extends Resource
{
    protected static ?string $model = Empresa::class;

    public static function getNavigationIcon(): string
    {
        return 'heroicon-o-building-office';
    }

    public static function getNavigationLabel(): string
    {
        return 'Empresas';
    }

    public static function getPluralModelLabel(): string
    {
        return 'Empresas';
    }

    public static function getSlug(?Panel $panel = null): string
    {
        return 'empresas';
    }

    public static function getNavigationGroup(): string
    {
        return 'Gestión';
    }

    public static function getNavigationSort(): ?int
    {
        return 2;
    }

    public static function getNavigationBadge(): ?string
    {
        return (string) static::getModel()::count();
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                SchemaComponents\Section::make('Información de la Empresa')
                    ->schema([
                        Components\TextInput::make('ruc')
                            ->label('RUC')
                            ->required()
                            ->maxLength(11)
                            ->unique(ignoreRecord: true),
                        Components\TextInput::make('razon_social')
                            ->label('Razón Social')
                            ->required()
                            ->maxLength(255),
                        Components\TextInput::make('nombre_comercial')
                            ->label('Nombre Comercial')
                            ->required()
                            ->maxLength(255),
                        Components\FileUpload::make('logo')
                            ->label('Logo')
                            ->image()
                            ->disk('public')
                            ->directory('logos')
                            ->visibility('public')
                            ->imageEditor()
                            ->maxSize(2048)
                            ->helperText('Se usa en el login, el panel y los documentos. PNG/SVG con fondo transparente, recomendado.')
                            ->columnSpanFull(),
                    ])->columns(3),

                SchemaComponents\Section::make('Contacto')
                    ->schema([
                        Components\TextInput::make('direccion')
                            ->label('Dirección')
                            ->maxLength(500),
                        Components\TextInput::make('telefono')
                            ->label('Teléfono')
                            ->maxLength(20),
                        Components\TextInput::make('email')
                            ->label('Correo Electrónico')
                            ->email()
                            ->maxLength(255),
                        Components\Toggle::make('activa')
                            ->label('Activa')
                            ->default(true),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ImageColumn::make('logo')
                    ->label('Logo')
                    ->disk('public')
                    ->height(32),
                Tables\Columns\TextColumn::make('ruc')
                    ->label('RUC')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('razon_social')
                    ->label('Razón Social')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('nombre_comercial')
                    ->label('Nombre Comercial')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('email')
                    ->label('Correo'),
                Tables\Columns\IconColumn::make('activa')
                    ->label('Activa')
                    ->boolean()
                    ->sortable(),
                Tables\Columns\TextColumn::make('users_count')
                    ->label('Usuarios')
                    ->counts('users')
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Creado')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('activa')
                    ->label('Estado'),
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
            'index' => Pages\ListEmpresas::route('/'),
        ];
    }
}
