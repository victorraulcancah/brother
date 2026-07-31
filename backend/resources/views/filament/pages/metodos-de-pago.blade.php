<x-filament-panels::page>
    @php
        $tabs = [
            'bancos'     => ['label' => 'Bancos',              'icon' => 'heroicon-o-building-library'],
            'cuentas'    => ['label' => 'Cuentas Bancarias',   'icon' => 'heroicon-o-credit-card'],
            'tarjetas'   => ['label' => 'Tarjetas',            'icon' => 'heroicon-o-identification'],
            'billeteras' => ['label' => 'Billeteras Digitales','icon' => 'heroicon-o-device-phone-mobile'],
        ];
    @endphp

    <x-filament::tabs>
        @foreach($tabs as $key => $tab)
            <x-filament::tabs.item
                :active="$this->tab === $key"
                :icon="$tab['icon']"
                wire:click="$set('tab', '{{ $key }}')"
            >
                {{ $tab['label'] }}
            </x-filament::tabs.item>
        @endforeach
    </x-filament::tabs>

    {{ $this->table }}
</x-filament-panels::page>
