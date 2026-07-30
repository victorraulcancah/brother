<div class="grid grid-cols-3 gap-4 mb-6">
    {{-- Total a Pagar --}}
    <div class="pago-total-card">
        <div class="text-xs font-semibold uppercase tracking-wide mb-1" style="color: #1e40af;">
            TOTAL A PAGAR
        </div>
        <div class="text-2xl font-bold" style="color: #1e3a8a;">
            S/. {{ number_format($total ?? 0, 2) }}
        </div>
    </div>

    {{-- Total Pagado --}}
    <div class="pago-pagado-card">
        <div class="text-xs font-semibold uppercase tracking-wide mb-1" style="color: #065f46;">
            TOTAL PAGADO
        </div>
        <div class="text-2xl font-bold" style="color: #047857;">
            S/. {{ number_format($pagado ?? 0, 2) }}
        </div>
    </div>

    {{-- Saldo Pendiente --}}
    <div class="pago-saldo-card">
        <div class="text-xs font-semibold uppercase tracking-wide mb-1" style="color: #9a3412;">
            SALDO PENDIENTE
        </div>
        <div class="text-2xl font-bold" style="color: #c2410c;">
            S/. {{ number_format($saldo ?? 0, 2) }}
        </div>
    </div>
</div>
