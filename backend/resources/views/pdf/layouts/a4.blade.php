<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <title>@yield('titulo', 'Documento')</title>
    <style>
        @page { margin: 90px 34px 60px 34px; }
        * { box-sizing: border-box; }
        body {
            font-family: 'DejaVu Sans', sans-serif;
            font-size: 10px;
            color: #2b2b2b;
            margin: 0;
        }
        /* Cabecera y pie fijos en cada página */
        header { position: fixed; top: -70px; left: 0; right: 0; height: 70px; }
        footer { position: fixed; bottom: -44px; left: 0; right: 0; height: 44px; font-size: 8px; color: #8a8a8a; }
        .pagina:after { content: "Página " counter(page) " de " counter(pages); }

        h1, h2, h3, p { margin: 0; }
        .muted { color: #8a8a8a; }
        .strong { font-weight: bold; }
        .right { text-align: right; }
        .center { text-align: center; }

        table { width: 100%; border-collapse: collapse; }
        .items th {
            background: #ef6c00; color: #fff; font-size: 9px; text-transform: uppercase;
            letter-spacing: .3px; padding: 6px 6px; text-align: left;
        }
        .items td { padding: 5px 6px; border-bottom: 1px solid #eee; }
        .items tbody tr:nth-child(even) { background: #fafafa; }

        .box { border: 1px solid #e0dad2; border-radius: 6px; padding: 8px 10px; }
        .tag {
            display: inline-block; border: 1.5px solid #ef6c00; border-radius: 6px;
            padding: 6px 12px; color: #ef6c00; font-weight: bold;
        }
    </style>
</head>
<body>
    <header>
        <x-pdf.empresa :empresa="$empresa" formato="a4" />
    </header>

    <footer>
        <x-pdf.pie :pieLegal="$pieLegal ?? null" :generadoEn="$generadoEn ?? null" formato="a4" />
    </footer>

    <main>
        @yield('contenido')
    </main>
</body>
</html>
