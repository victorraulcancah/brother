---
name: BRAVA
description: Sistema de gestión web de una distribuidora de arroz; panel claro gris y azul, con un ingreso nocturno propio.
colors:
  primary-50: "#eff6ff"
  primary-100: "#dbeafe"
  primary-200: "#bfdbfe"
  primary-300: "#93c5fd"
  primary-400: "#60a5fa"
  primary-500: "#3b82f6"
  primary: "#2563eb"
  primary-700: "#1d4ed8"
  primary-800: "#1e40af"
  primary-900: "#1e3a8a"
  warm-900: "#1f2937"
  warm-500: "#6b7280"
  cream: "#e9ecf0"
  field: "#f9fafb"
  edge: "#d4d8de"
  surface: "#ffffff"
  night-900: "#080c18"
  night-800: "#0d1326"
  night-700: "#131b36"
  night-600: "#202c52"
  deep-900: "#091648"
  deep-800: "#0b1f5c"
  wheat-200: "#efdcae"
  login-action: "#2f6df0"
typography:
  display:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "clamp(2.75rem, 3.6vw, 3.6rem)"
    fontWeight: 800
    lineHeight: 1.08
    letterSpacing: "-0.015em"
  login-title:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.75rem"
    fontWeight: 800
    lineHeight: 1.25
    letterSpacing: "-0.015em"
  page-title:
    fontFamily: "ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.5rem"
    fontWeight: 700
    lineHeight: 1.33
    letterSpacing: "-0.025em"
  title:
    fontFamily: "ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.125rem"
    fontWeight: 600
    lineHeight: 1.55
  body:
    fontFamily: "ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 400
    lineHeight: 1.43
  label:
    fontFamily: "ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 600
    lineHeight: 1.33
    letterSpacing: "0.025em"
rounded:
  sm: "6px"
  md: "8px"
  lg: "12px"
  xl: "16px"
  sheet: "24px"
  full: "9999px"
spacing:
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "24px"
  xl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface}"
    rounded: "{rounded.sm}"
    padding: "8px 12px"
  button-primary-hover:
    backgroundColor: "{colors.primary-700}"
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.warm-900}"
    rounded: "{rounded.sm}"
    padding: "8px 12px"
  input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.warm-900}"
    rounded: "{rounded.sm}"
    padding: "8px 12px"
  card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.md}"
    padding: "24px"
  table-header:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface}"
    padding: "12px 16px"
  modal-sheet:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.sheet}"
  badge:
    backgroundColor: "{colors.primary-50}"
    textColor: "{colors.primary-700}"
    rounded: "{rounded.full}"
    padding: "2px 8px"
  login-field:
    backgroundColor: "{colors.night-700}"
    textColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    height: "48px"
  login-button:
    backgroundColor: "{colors.login-action}"
    textColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    height: "48px"
---

# Design System: BRAVA

Alcance: solo la aplicación web (`backend/resources`). La app Flutter queda fuera.

## Overview

**Creative North Star: "El mostrador claro"**

Dos mundos conviven y no se mezclan. La aplicación es un mostrador de trabajo: fondo gris de página (#e9ecf0), tarjetas blancas con borde fino, un solo acento azul y texto gris oscuro. Es denso pero legible, pensado para PC de oficina y celular por igual. La pantalla de ingreso es un mundo propio y nocturno: pantalla partida con un panel de marca azul profundo y un panel de formulario casi negro. El azul de marca es el hilo que une ambos.

La aplicación es plana: la profundidad viene del contraste blanco sobre gris y de bordes `edge`, con sombra mínima. La tipografía es la del sistema; Manrope vive solo en el ingreso. En celular los componentes cambian de forma (tabla a tarjetas, modal a hoja inferior), no solo de tamaño.

**Key Characteristics:**
- Un solo acento: azul `primary-600`; el resto es gris neutro.
- Tarjetas blancas con borde `edge` sobre fondo `cream`.
- Móvil con forma propia: hoja inferior, tarjetas de fila, tarjetas de línea.
- Ingreso nocturno con granos de arroz en contorno como textura de marca.

## Colors

Paleta de un solo acento azul sobre grises fríos; el ingreso añade una escala nocturna y un trigo cálido.

### Primary
- **Azul BRAVA** (primary, #2563eb): botón primario, cabecera de tablas, cabecera de la hoja inferior móvil, foco, indicadores.
- **Escala azul** (primary-50 a primary-900): 50 y 100 para fondos suaves (ítem activo del menú, resúmenes, badges), 700 para hover y texto sobre fondo suave, 400 y 300 para enlaces sobre fondo oscuro.

### Neutral
- **Texto gris oscuro** (warm-900, #1f2937): títulos y texto principal.
- **Texto gris medio** (warm-500, #6b7280): descripciones y etiquetas secundarias.
- **Fondo de página** (cream, #e9ecf0): fondo de toda la aplicación.
- **Borde** (edge, #d4d8de): bordes de tarjetas, tablas, menú lateral y pie de modal.
- **Campo** (field, #f9fafb): fondo de campos cuando se usa.
- **Superficie** (surface, #ffffff): tarjetas, modales, menú lateral.

### Ingreso (mundo propio)
- **Noche** (night-900 #080c18, 800, 700 #131b36, 600 #202c52): fondo del panel de formulario, campos y bordes de campo.
- **Azul profundo** (deep-900 #091648, deep-800 #0b1f5c): panel de marca, con degradado 160deg de #0a1a52 a #0e2a7e y un resplandor azul en la esquina inferior izquierda.
- **Trigo** (wheat-200, #efdcae): únicamente los dos datos de cifra del panel de marca.
- **Acción de ingreso** (login-action, #2f6df0): botón Iniciar sesión.

### Named Rules
**The One Voice Rule.** El azul es el único acento de la aplicación; estados usan verde, ámbar y rojo solo en Badge, Button success/danger y errores.
**The Gray-Page Rule.** La página es gris y la tarjeta es blanca; una tarjeta nunca va sobre blanco.
**The Wheat Is Login's Rule.** El trigo no sale del ingreso.

## Typography

**Aplicación:** fuente del sistema (`ui-sans-serif, system-ui, sans-serif`).
**Ingreso:** Manrope vía `font-display`, con la pila del sistema de respaldo.

**Character:** neutra y de trabajo en la aplicación; en el ingreso, titulares muy pesados (800) y apretados que dan firma.

### Hierarchy
- **Display** (800, clamp(2.75rem, 3.6vw, 3.6rem), 1.08): titular del panel de marca, solo escritorio; 1.75rem en celular y 2.25rem desde sm.
- **Login title** (800, 1.75rem, 1.25): "Bienvenido de nuevo".
- **Page title** (700, 1.5rem, tracking-tight): título de página en PageHeader.
- **Title** (600, 1.125rem): títulos de modal; 1rem en Card.
- **Body** (400, 0.875rem): texto de tablas, campos y botones.
- **Label** (600, 0.75rem, 0.025em, mayúsculas): solo cabeceras de tabla y títulos de menú desplegable. Campos usan etiqueta 0.875rem 500 (aplicación) o 13px 600 (ingreso).

### Named Rules
**The Manrope Stays Home Rule.** Manrope no se usa fuera del ingreso.

## Layout

Menú lateral fijo de 256px (64px contraído a iconos en escritorio, con submenú flotante); en celular es un cajón que sale por la izquierda. Barra superior de 64px en celular y 56px en escritorio, alineada a la derecha con campana de alertas y menú de usuario. Contenido con padding 16px, 24px desde sm y 32px desde lg. Breakpoints de Tailwind; `md` (768px) es el corte que cambia tabla por tarjetas y modal por hoja.

Ritmo: tarjetas 16px (celular) a 24px (sm), separación de tarjetas 12px, gaps de acciones 8px. El ingreso es una cuadrícula de dos columnas 1.04fr y 1fr desde lg; apilado en celular. El formulario tiene ancho máximo 22.5rem.

## Elevation & Depth

Casi plano. La separación sale del tono (blanco sobre #e9ecf0) y del borde `edge`. Sombra estándar `shadow-sm` en tarjetas, botones y campos. Capas flotantes (menús desplegables) usan `shadow-xl` con borde; la hoja o diálogo modal usa `shadow-2xl` sobre un velo negro al 50%. En el ingreso hay dos brillos azules difusos: logo (`0 8px 20px -6px rgba(59,130,246,0.7)`) y botón (`0 10px 24px -10px rgba(59,130,246,0.75)`).

### Named Rules
**The Flat-By-Default Rule.** Las superficies en reposo no llevan sombra más allá de `shadow-sm`; la sombra grande solo marca capas que flotan.

## Shapes

Esquinas suaves y consistentes. Botones, campos y menús: 6px. Tarjetas y tablas: 8px. Tarjetas de fila móvil, resúmenes y logo del ingreso: 12px. Diálogo en escritorio: 16px. Hoja inferior móvil: 24px arriba. Badges y asas: píldora. Bordes de 1px en `edge`. Las tarjetas de línea llevan franja izquierda de 4px en primary-500 y separador punteado.

## Components

### Buttons
- **Shape:** 6px, `shadow-sm`, anillo de foco de 2px con separación.
- **Primary:** fondo #2563eb, texto blanco, 8px 12px, 14px 500; hover primary-700.
- **Variantes:** secondary (blanco con anillo gris), danger (rojo 600), success (verde 600), ghost (sin fondo, hover gris 100). Tamaños sm, md, lg. Estado cargando con spinner y 60% de opacidad al deshabilitar.

### Inputs / Fields
- **Style:** fondo blanco, sin borde, anillo interior gris 1px, 6px, 8px 12px, etiqueta encima.
- **Focus:** anillo de 2px en primary-600. **Error:** anillo rojo y mensaje rojo 12px debajo.
- **Ingreso:** 48px de alto, 12px, fondo night-700 al 70%, borde night-600, ícono de 18px a la izquierda, foco con borde primary-500 y halo de 4px al 20%.

### Cards / Containers
- Blanca, 8px, borde fino, `shadow-sm`; cabecera opcional con borde inferior; padding 16px a 24px.

### Modal
- Hoja inferior en celular: sube desde abajo, ancho completo, 24px arriba, cabecera azul primary-600 con asa y botón cerrar, alto máximo 92dvh, pie con botones a ancho repartido. Desde sm: diálogo centrado, cabecera blanca, ícono en recuadro primary-50. Tamaños sm a 3xl.

### DataTable
- Tarjeta blanca con barra de búsqueda y botones de filtros y columnas. Desde md: tabla con cabecera fija primary-600 texto blanco en mayúsculas pequeñas, filas separadas por líneas gray-100, hover suave. En celular: tarjetas de 12px sobre fondo gris 50, primera columna como título y resto como pares etiqueta-valor.

### LineCards y DetalleSheet
- LineCards: líneas de documento como tarjetas (solo móvil) con franja azul, ícono en recuadro primary-50 y total en bloque primary-50. DetalleSheet: Modal en celular con resumen de datos con íconos en bloque primary-50.

### Badge
- Píldora con anillo interior: gray, green, red, amber y blue (primary-50 con primary-700).

### Navigation
- Menú lateral blanco con borde `edge`, logo `brava-horizontal.png` de 56px de alto, ítems con ícono de 20px; activo en primary-50 con texto primary-700, inactivo gris 500 con hover gris 100. Grupos contraíbles con memoria en el navegador.

### Pantalla de ingreso
- Panel de marca: logo en recuadro azul de 40px con espiga de arroz, titular, dos cifras en trigo, textura de granos de arroz en contorno al 7% en diagonal. Panel de formulario: casilla propia con palomita blanca, enlaces en primary-400, firma BRINTECH de 64px de alto con mezcla `screen`. Entrada única de 0.7s al cargar, desactivada con movimiento reducido.

## Do's and Don'ts

### Do:
- **Do** usar `primary-600` como único acento de la aplicación y `cream` como fondo de página.
- **Do** poner tarjetas blancas con borde `edge` y `shadow-sm`.
- **Do** dar a cada componente su forma móvil: hoja inferior en Modal, tarjetas en DataTable y líneas.
- **Do** usar íconos de lucide-react en SVG, con etiqueta visible en los campos.
- **Do** respetar `motion-reduce` en toda animación de entrada.
- **Do** mantener el ingreso en su mundo nocturno con tokens night, deep y wheat.

### Don't:
- **Don't** usar Manrope, night, deep ni wheat fuera del ingreso.
- **Don't** introducir un segundo acento de color en la aplicación.
- **Don't** mostrar una tabla de muchas columnas en celular; usar tarjetas.
- **Don't** usar cabecera de tabla en otro color que `primary-600`.
