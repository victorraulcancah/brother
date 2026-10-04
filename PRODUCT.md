# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Dueño y personal de una distribuidora de arroz en Perú (vendedores, cajeros, almacén, administrador). Entran en la PC del mostrador u oficina y también desde el celular. Confirmado en la entrevista: PC y celular por igual. Interfaz en español (es-PE), moneda PEN.

## Product Purpose

BRAVA es el sistema de gestión del negocio: ventas y pedidos de clientes (que reservan stock), compras y recepciones, inventario por almacén, caja y tesorería, cuentas por cobrar y pagar, reportes. El éxito del login es entrar rápido y con confianza a un sistema que maneja dinero y mercadería.

## Positioning

Un sistema hecho a la medida de un negocio de arroz (stock en sacos, kilos y unidades derivadas, pedidos que reservan mercadería), no una plantilla de ERP genérica.

## Operating Context

Un login de uso diario y repetido, muchas veces con prisa en el mostrador. La sesión es JWT contra la API de Laravel; el formulario tiene "recordar credenciales" y mostrar/ocultar contraseña. Las rutas "¿Olvidaste tu contraseña?" (/recuperar) y "Regístrate" (/registro) existen en el formulario pero todavía no tienen página (caen en "En construcción").

## Capabilities and Constraints

- Web React + Tailwind (Vite), Laravel 13 en el servidor; hay también una app móvil Flutter con su propio login.
- Tema del sistema ya definido: fondo gris (#e9ecf0) y acento azul (primary-600 #2563eb), tarjetas blancas, fuente del sistema en la aplicación y Manrope en la pantalla de ingreso.
- Debe funcionar bien desde 320 px hasta escritorio y conservar la lógica de autenticación existente.
- Sin animaciones pesadas: entrar debe seguir siendo inmediato.

## Brand Commitments

- Marca: BRAVA, "Distribuidora de arroz". Logo vigente: espiga de arroz blanca sobre cuadrado azul + palabra BRAVA en azul (`/images/brava-horizontal.png`). Confirmado como lo que debe conservarse.
- Firma del software: "Desarrollado por" BRINTECH Technology Consulting (`/images/brintech.png` en fondos claros y `/images/brintech-oscuro.jpg` en el ingreso), confirmada antes por el usuario como crédito discreto en el login y el menú. (Supuesto: se mantiene en el nuevo login.)
- Tono: cercano y confiable, de negocio de arroz; el usuario rechaza explícitamente lo frío o corporativo.

## Evidence on Hand

- Logos en `backend/public/images/`. No hay fotografías del negocio ni de producto: no inventar testimonios, clientes ni cifras.

## Product Principles

1. Entrar primero: el formulario manda; nada decorativo compite con el correo y la contraseña.
2. Se siente de un negocio de arroz, no de un software cualquiera.
3. Una sola identidad con el resto del sistema (gris + azul), para que el login anuncie lo que viene después.
4. Mismo cuidado en celular que en escritorio.

## Accessibility & Inclusion

Contraste legible bajo luz de mostrador o almacén, objetivos táctiles cómodos y etiquetas visibles en los campos (no solo placeholders).
