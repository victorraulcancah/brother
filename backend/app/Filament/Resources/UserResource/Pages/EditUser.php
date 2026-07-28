<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditUser extends EditRecord
{
    protected static string $resource = UserResource::class;

    protected array $tempRole = [];

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }

    protected function mutateFormDataBeforeSave(array $data): array
    {
        $this->tempRole = $data['role'] ?? [];
        unset($data['role']);

        return $data;
    }

    protected function afterSave(): void
    {
        if (!empty($this->tempRole)) {
            $this->record->syncRoles($this->tempRole);
        }
    }
}
