@extends('pdf.layouts.' . $formato)

@section('titulo', 'Nota de venta ' . $documento)

@section('contenido')
    @php
        $anulada = $venta->estado === 'anulada';
        $clienteNombre = $venta->cliente?->nombre ?? $venta->cliente?->razon_social ?? 'Clientes varios';
    @endphp

    <x-pdf.titulo
        texto="NOTA DE VENTA"
        :numero="$documento"
        :estado="$anulada ? 'ANULADA' : null"
        :formato="$formato" />

    <x-pdf.tercero
        titulo="Cliente"
        :nombre="$clienteNombre"
        :documento="$venta->cliente?->numero_documento"
        :formato="$formato" />

    <x-pdf.meta
        :items="[
            'Fecha' => optional($venta->fecha_emision)->format('d/m/Y'),
            'Vendedor' => $venta->vendedor?->name,
            'Almacén' => $venta->almacen?->nombre,
            'Pago' => ucfirst($venta->tipo_pago),
        ]"
        :formato="$formato" />

    @if ($formato === 'ticket')
        <x-pdf.items :filas="$filas" formato="ticket" />
    @else
        <x-pdf.items
            :columnas="[
                ['label' => '#', 'key' => 'n', 'width' => '24px'],
                ['label' => 'Código', 'key' => 'codigo', 'width' => '70px'],
                ['label' => 'Producto', 'key' => 'producto'],
                ['label' => 'Unidad', 'key' => 'unidad', 'width' => '80px'],
                ['label' => 'Cant.', 'key' => 'cantidad', 'align' => 'right', 'width' => '55px'],
                ['label' => 'P.Unit', 'key' => 'precio', 'align' => 'right', 'width' => '70px'],
                ['label' => 'Subtotal', 'key' => 'subtotal', 'align' => 'right', 'width' => '80px'],
            ]"
            :filas="$filas"
            formato="a4" />
    @endif

    <x-pdf.totales
        :lineas="[
            'Subtotal' => number_format((float) $venta->subtotal, 2),
            'Descuento' => (float) $venta->descuento_total > 0 ? '-' . number_format((float) $venta->descuento_total, 2) : null,
        ]"
        :total="number_format((float) $venta->total, 2)"
        :moneda="$moneda"
        :enLetras="$enLetras"
        :formato="$formato" />

    {{-- Pagos --}}
    @if (count($pagos))
        @if ($formato === 'ticket')
            <table class="row">
                @foreach ($pagos as $p)
                    <tr><td class="muted">{{ $p['metodo'] }}</td><td class="right">{{ $moneda }} {{ $p['monto'] }}</td></tr>
                @endforeach
            </table>
            <div class="sep"></div>
        @else
            <div class="muted" style="margin: 2px 0 6px;">
                Pago:
                @foreach ($pagos as $p){{ $p['metodo'] }} {{ $moneda }} {{ $p['monto'] }}@if(!$loop->last) · @endif @endforeach
            </div>
        @endif
    @endif

    @if ($venta->observaciones)
        @if ($formato === 'ticket')
            <div class="muted">Obs.: {{ $venta->observaciones }}</div>
        @else
            <div class="box" style="margin-top: 6px;"><span class="muted">Observaciones:</span> {{ $venta->observaciones }}</div>
        @endif
    @endif

    @if ($anulada && $venta->motivo_anulacion)
        <div class="box" style="margin-top: 6px; border-color: #d32f2f; color: #d32f2f;">
            <span class="strong">ANULADA:</span> {{ $venta->motivo_anulacion }}
        </div>
    @endif
@endsection
