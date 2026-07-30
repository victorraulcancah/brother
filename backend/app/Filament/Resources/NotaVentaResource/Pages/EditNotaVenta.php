<?php

namespace App\Filament\Resources\NotaVentaResource\Pages;

use App\Filament\Resources\NotaVentaResource;
use App\Models\NotaVenta;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;
use Filament\Notifications\Notification;

class EditNotaVenta extends EditRecord
{
    protected static string $resource = NotaVentaResource::class;

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }

    protected function mutateFormDataBeforeFill(array $data): array
    {
        $data['pagos'] = $this->record->pagos()
            ->get()
            ->map(fn ($p) => [
                'id'             => $p->id,
                'metodo_pago_id' => $p->metodo_pago_id,
                'forma_pago'     => $p->forma_pago,
                'monto'          => $p->monto,
                'fecha'          => $p->fecha,
                'referencia'     => $p->referencia,
            ])
            ->toArray();

        return $data;
    }

    protected function mutateFormDataBeforeSave(array $data): array
    {
        unset($data['pagos']);
        return $data;
    }

    protected function afterSave(): void
    {
        $data = $this->form->getRawState();
        $pagos = $data['pagos'] ?? [];

        if (!empty($pagos)) {
            $this->record->pagos()->delete();
            foreach ($pagos as $pago) {
                $this->record->pagos()->create([
                    'metodo_pago_id' => $pago['metodo_pago_id'],
                    'forma_pago'     => $pago['forma_pago'] ?? '',
                    'monto'          => $pago['monto'],
                    'fecha'          => $pago['fecha'],
                    'referencia'     => $pago['referencia'] ?? null,
                ]);
            }
        }
    }

    protected function getHeaderActions(): array
    {
        return [
            Actions\Action::make('registrarPago')
                ->label('Registrar Pago')
                ->color('success')
                ->icon('heroicon-o-credit-card')
                ->modalHeading('Pagar - Métodos de Pago')
                ->modalWidth('5xl')
                ->modalSubmitActionLabel('Guardar')
                ->modalCancelActionLabel('Cancelar')
                ->form(NotaVentaResource::pagosSchema())
                ->fillForm(function (NotaVenta $record): array {
                    $total  = (float) $record->total;
                    $pagado = (float) $record->pagos()->sum('monto');
                    return [
                        'total'  => $total,
                        'pagado' => $pagado,
                        'saldo'  => $total - $pagado,
                        'pagos'  => $record->pagos()
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

                    Notification::make()
                        ->success()
                        ->title('Pagos guardados correctamente')
                        ->send();
                }),

            Actions\DeleteAction::make(),
        ];
    }
}
