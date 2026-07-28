<x-filament::page>
    <div>
        <div class="flex gap-0 border-b border-gray-200 mb-6">
            <button
                wire:click="$set('tab', 'marcas')"
                @class([
                    'inline-flex items-center gap-2 px-6 py-3 text-sm font-medium border-b-2 transition-colors duration-200',
                    'border-primary-600 text-primary-600' => $tab === 'marcas',
                    'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300' => $tab !== 'marcas',
                ])>
                <x-filament::icon name="heroicon-o-tag" class="w-5 h-5" />
                Marcas
            </button>
            <button
                wire:click="$set('tab', 'submarcas')"
                @class([
                    'inline-flex items-center gap-2 px-6 py-3 text-sm font-medium border-b-2 transition-colors duration-200',
                    'border-primary-600 text-primary-600' => $tab === 'submarcas',
                    'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300' => $tab !== 'submarcas',
                ])>
                <x-filament::icon name="heroicon-o-circle-stack" class="w-5 h-5" />
                Submarcas
            </button>
        </div>

        {{ $this->table }}
    </div>
</x-filament::page>
