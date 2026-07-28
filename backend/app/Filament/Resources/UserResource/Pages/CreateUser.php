<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use Filament\Resources\Pages\CreateRecord;

class CreateUser extends CreateRecord
{
    protected static string $resource = UserResource::class;

    protected array $tempRole = [];

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $this->tempRole = $data['role'] ?? [];
        unset($data['role']);

        return $data;
    }

    protected function afterCreate(): void
    {
        if (!empty($this->tempRole)) {
            $this->record->assignRole($this->tempRole);
        }
    }
}
