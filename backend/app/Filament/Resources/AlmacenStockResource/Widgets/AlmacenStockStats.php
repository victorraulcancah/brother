<?php

namespace App\Filament\Resources\AlmacenStockResource\Widgets;

use App\Models\Almacen;
use App\Models\ProductoAlmacenStock;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class AlmacenStockStats extends StatsOverviewWidget
{
    protected ?string $pollingInterval = null;

    protected int|array|null $columns = 3;

    protected function getStats(): array
    {
        $almacenes = Almacen::where('activo', true)->count();

        $conStock = ProductoAlmacenStock::where('stock_actual', '>', 0)
            ->distinct('producto_id')
            ->count('producto_id');

        $bajoStock = ProductoAlmacenStock::where('stock_actual', '>', 0)
            ->where('stock_actual', '<=', 5)
            ->count();

        return [
            Stat::make('Almacenes Activos', number_format($almacenes))
                ->description('Registrados en el sistema')
                ->icon('heroicon-o-building-storefront')
                ->color('info'),

            Stat::make('Productos con Stock', number_format($conStock))
                ->description('Con cantidad > 0')
                ->icon('heroicon-o-archive-box')
                ->color('success'),

            Stat::make('Stock Bajo', number_format($bajoStock))
                ->description('Productos con ≤ 5 unidades')
                ->icon('heroicon-o-exclamation-triangle')
                ->color('danger'),
        ];
    }
}
