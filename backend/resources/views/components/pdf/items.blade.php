@props(['columnas' => [], 'filas' => [], 'formato' => 'a4'])

@php
    // Cada columna: ['label' => 'Cant.', 'key' => 'cantidad', 'align' => 'right', 'width' => '60px']
    // Cada fila: array asociativo con las mismas keys.
@endphp

@if ($formato === 'ticket')
    <table>
        @foreach ($filas as $fila)
            <tr>
                <td colspan="2" class="strong">{{ $fila['nombre'] ?? '' }}</td>
            </tr>
            <tr>
                <td class="muted">{{ $fila['detalle'] ?? '' }}</td>
                <td class="right">{{ $fila['importe'] ?? '' }}</td>
            </tr>
        @endforeach
    </table>
    <div class="sep"></div>
@else
    <table class="items" style="margin: 8px 0;">
        <thead>
            <tr>
                @foreach ($columnas as $col)
                    <th @if(($col['align'] ?? '') === 'right') style="text-align:right;" @endif
                        @if(!empty($col['width'])) width="{{ $col['width'] }}" @endif>
                        {{ $col['label'] }}
                    </th>
                @endforeach
            </tr>
        </thead>
        <tbody>
            @forelse ($filas as $fila)
                <tr>
                    @foreach ($columnas as $col)
                        <td @if(($col['align'] ?? '') === 'right') class="right" @endif>
                            {{ $fila[$col['key']] ?? '' }}
                        </td>
                    @endforeach
                </tr>
            @empty
                <tr><td colspan="{{ count($columnas) }}" class="center muted" style="padding: 16px;">Sin ítems</td></tr>
            @endforelse
        </tbody>
    </table>
@endif
