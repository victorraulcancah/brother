<?php

namespace App\Filament\Resources\NotaVentaResource\Pages;

use App\Filament\Resources\NotaVentaResource;
use App\Models\NotaVenta;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditNotaVenta extends EditRecord
{
    protected static string $resource = NotaVentaResource::class;

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }

    protected function getHeaderActions(): array
    {
        return [
            // ── Modal de Pago ─────────────────────────────────────────────
            Actions\Action::make('registrarPago')
                ->label('Registrar Pago')
                ->color('success')
                ->icon('heroicon-o-credit-card')
                ->modalHeading('Pagar - Métodos de Pago')
                ->modalDescription('')
                ->modalWidth('5xl')
                ->modalSubmitActionLabel('Guardar')
                ->modalCancelActionLabel('Cancelar')
                ->form(NotaVentaResource::pagosSchema())
                ->fillForm(function (NotaVenta $record): array {
                    return [
                        'pagos' => $record->pagos()
                            ->get()
                            ->map(fn ($p) => [
                                'id'             => $p->id,
                                'metodo_pago_id' => $p->metodo_pago_id,
                                'forma_pago'     => $p->forma_pago,
                                'monto'          => $p->monto,
                                'fecha'          => $p->fecha,
                                'referencia'     => $p->referencia,
                            ])
                            ->toArray(),
                    ];
                })
                ->action(function (array $data, NotaVenta $record): void {
                    // Eliminar pagos anteriores y recrear
                    $record->pagos()->delete();
                    foreach ($data['pagos'] ?? [] as $pago) {
                        $record->pagos()->create([
                            'metodo_pago_id' => $pago['metodo_pago_id'],
                            'forma_pago'     => $pago['forma_pago'] ?? '',
                            'monto'          => $pago['monto'],
                            'fecha'          => $pago['fecha'],
                            'referencia'     => $pago['referencia'] ?? null,
                        ]);
                    }
                }),

            Actions\DeleteAction::make(),
        ];
    }
}
