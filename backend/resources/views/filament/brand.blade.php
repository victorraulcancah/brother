@php
    $empresa = \App\Models\Empresa::activa();
    $nombre = $empresa?->nombre_comercial ?? 'BRAVA';
    $logoUrl = $empresa?->logo_url ?? asset('img/brava-horizontal.png');
@endphp

<img src="{{ $logoUrl }}" alt="{{ $nombre }}" class="h-10 w-auto object-contain" />
