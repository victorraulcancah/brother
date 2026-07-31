<?php

namespace App\Providers\Filament;

use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\AuthenticateSession;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Navigation\MenuItem;
use Filament\Navigation\NavigationGroup;
use Filament\Pages\Dashboard;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\Support\Enums\Width;
use Filament\View\PanelsRenderHook;
use Filament\Widgets\AccountWidget;
use Filament\Widgets\FilamentInfoWidget;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\PreventRequestForgery;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\View\Middleware\ShareErrorsFromSession;

class AdminPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->default()
            ->id('admin')
            ->path('admin')
            ->login()
            ->passwordReset()
            ->profile()
            ->darkMode(false)
            ->colors([
                'primary' => Color::Amber,
                'gray' => Color::Slate,
            ])
            ->brandName(fn(): string => \App\Models\Empresa::activa()?->nombre_comercial ?? 'BRAVA')
            ->brandLogo(fn() => view('filament.brand'))
            ->brandLogoHeight('2.5rem')
            ->favicon(fn(): string => \App\Models\Empresa::activa()?->favicon_url ?? asset('favicon.ico'))
            ->font('Inter')
            ->sidebarCollapsibleOnDesktop()
            ->sidebarWidth('16rem')
            ->collapsibleNavigationGroups(true)
            ->maxContentWidth(Width::Full)
            ->navigationGroups([
                NavigationGroup::make('Escritorio')
                    ->icon('heroicon-o-home')
                    ->collapsed(true),
                NavigationGroup::make('Inventario')
                    ->icon('heroicon-o-archive-box')
                    ->collapsed(true),
                NavigationGroup::make('Catálogo')
                    ->icon('heroicon-o-book-open')
                    ->collapsed(true),
                NavigationGroup::make('Ventas')
                    ->icon('heroicon-o-receipt-percent')
                    ->collapsed(true),
                NavigationGroup::make('Tesorería')
                    ->icon('heroicon-o-currency-dollar')
                    ->collapsed(true),
                NavigationGroup::make('Compras')
                    ->icon('heroicon-o-shopping-cart')
                    ->collapsed(true),
                NavigationGroup::make('Gestión')
                    ->icon('heroicon-o-building-office-2')
                    ->collapsed(true),
            ])
            ->userMenuItems([
                MenuItem::make()
                    ->label('Mi Perfil')
                    ->url(fn() => \Filament\Auth\Pages\EditProfile::getUrl())
                    ->icon('heroicon-o-user'),
            ])
            ->renderHook(
                PanelsRenderHook::HEAD_START,
                function (): string {
                    $path = public_path('css/filament-custom.css');
                    $version = is_file($path) ? filemtime($path) : null;
                    return '<link rel="stylesheet" href="' . asset('css/filament-custom.css') . ($version ? '?v=' . $version : '') . '">';
                },
            )
            ->discoverResources(in: app_path('Filament/Resources'), for: 'App\Filament\Resources')
            ->discoverPages(in: app_path('Filament/Pages'), for: 'App\Filament\Pages')
            ->pages([
                Dashboard::class,
            ])
            ->discoverWidgets(in: app_path('Filament/Widgets'), for: 'App\Filament\Widgets')
            ->widgets([
                AccountWidget::class,
                FilamentInfoWidget::class,
            ])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                PreventRequestForgery::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
            ]);
    }
}
