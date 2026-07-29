<?php

namespace App\Livewire;

use App\Filament\Resources\MotivoMovimientoResource;
use App\Models\MotivoMovimiento;
use Filament\Actions\Action;
use Filament\Actions\Concerns\InteractsWithActions;
use Filament\Actions\Contracts\HasActions;
use Filament\Actions\DeleteAction;
use Filament\Schemas\Concerns\InteractsWithSchemas;
use Filament\Schemas\Contracts\HasSchemas;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Filament\Tables\Table;
use Illuminate\Contracts\View\View;
use Livewire\Component;

/**
 * Tabla de Motivos embebida dentro de la página de Ajustes (pestaña "Motivos").
 * Crear/editar reutiliza las páginas del MotivoMovimientoResource.
 */
class MotivosTable extends Component implements HasActions, HasSchemas, HasTable
{
    use InteractsWithActions;
    use InteractsWithSchemas;
    use InteractsWithTable;

    public function table(Table $table): Table
    {
        return $table
            ->query(MotivoMovimiento::query())
            ->columns([
                TextColumn::make('nombre')
                    ->label('Nombre')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('tipo')
                    ->label('Tipo')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => $state === 'entrada' ? 'Entrada' : 'Salida')
                    ->color(fn (string $state): string => $state === 'entrada' ? 'success' : 'danger'),

                IconColumn::make('es_sistema')
                    ->label('Sistema')
                    ->boolean(),

                IconColumn::make('activo')
                    ->label('Activo')
                    ->boolean(),
            ])
            ->headerActions([
                Action::make('nuevo')
                    ->label('Nuevo motivo')
                    ->icon('heroicon-o-plus')
                    ->url(fn (): string => MotivoMovimientoResource::getUrl('create')),
            ])
            ->actions([
                Action::make('editar')
                    ->label('Editar')
                    ->icon('heroicon-o-pencil')
                    ->url(fn (MotivoMovimiento $record): string => MotivoMovimientoResource::getUrl('edit', ['record' => $record])),

                DeleteAction::make()
                    ->visible(fn (MotivoMovimiento $record): bool => ! $record->es_sistema),
            ]);
    }

    public function render(): View
    {
        return view('livewire.motivos-table');
    }
}
