@props(['items' => [], 'formato' => 'a4'])

@php
    // Solo pares con valor real.
    $items = collect($items)->filter(fn ($v) => $v !== null && $v !== '')->all();
@endphp

@if ($formato === 'ticket')
    <table class="row">
        @foreach ($items as $label => $valor)
            <tr>
                <td class="muted">{{ $label }}</td>
                <td class="right">{{ $valor }}</td>
            </tr>
        @endforeach
    </table>
    <div class="sep"></div>
@else
    <table class="box" style="margin: 6px 0;">
        @foreach (array_chunk($items, 2, true) as $par)
            <tr>
                @foreach ($par as $label => $valor)
                    <td style="width: 12%;" class="muted">{{ $label }}:</td>
                    <td class="strong">{{ $valor }}</td>
                @endforeach
                @if (count($par) === 1)<td></td><td></td>@endif
            </tr>
        @endforeach
    </table>
@endif
