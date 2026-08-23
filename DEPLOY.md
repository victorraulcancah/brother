# Despliegue en producción (VPS Ubuntu + Nginx + PHP 8.3 + MySQL)

Guía para publicar **brother** (Laravel 13 + React/Vite) en un VPS.
Todos los comandos se ejecutan como `root` (`sudo -i`) salvo donde se indique.

Sustituye estos valores por los tuyos:

| Marcador | Significado | Ejemplo |
|---|---|---|
| `TU_DOMINIO` | dominio apuntando al VPS (o la IP del servidor) | `sistema.miempresa.com` |
| `CLAVE_BD` | contraseña del usuario MySQL de la app | genérala con `openssl rand -base64 24` |
| `CLAVE_ADMIN` | contraseña del primer usuario del sistema | mínimo 12 caracteres |

---

## 0. Seguridad primero

Si la contraseña de `root` se compartió por chat, correo o captura, cámbiala ya:

```bash
passwd
```

Firewall (deja SSH abierto antes de activarlo, o te quedas fuera):

```bash
ufw allow OpenSSH && ufw allow 80/tcp && ufw allow 443/tcp && ufw --force enable && ufw status
```

---

## 1. Actualizar el sistema

```bash
apt update && apt upgrade -y
```

Comprueba la versión de Ubuntu:

```bash
lsb_release -ds
```

- **Ubuntu 24.04**: PHP 8.3 viene en los repositorios oficiales, sigue al paso 2.
- **Ubuntu 22.04 o anterior**: añade el repositorio de PHP antes del paso 2:

  ```bash
  apt install -y software-properties-common && add-apt-repository -y ppa:ondrej/php && apt update
  ```

---

## 2. Instalar Nginx, PHP 8.3, MySQL, Git y Node.js

El proyecto necesita **PHP >= 8.3** (Laravel 13) y **MySQL/MariaDB** — los reportes usan
`DATE_FORMAT`, que es sintaxis de MySQL, así que SQLite no sirve en producción.

```bash
apt install -y nginx mysql-server git curl unzip composer php8.3-fpm php8.3-cli php8.3-common php8.3-mysql php8.3-zip php8.3-gd php8.3-mbstring php8.3-curl php8.3-xml php8.3-bcmath
```

**Node.js 22 LTS** (obligatorio): los archivos compilados del frontend no están en el
repositorio, se generan en el servidor. Vite 8 exige Node 20.19+ o 22.12+.

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt install -y nodejs
```

Verifica las tres versiones:

```bash
php8.3 -v && node -v && mysql --version
```

Si el VPS tiene 1 GB de RAM o menos, crea memoria de intercambio para que la
compilación del frontend no falle:

```bash
fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile && echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

---

## 3. Base de datos

```bash
mysql_secure_installation
```

Responde: contraseña de root de MySQL → sí, quitar usuarios anónimos → sí,
prohibir login remoto de root → sí, eliminar la base `test` → sí, recargar
privilegios → sí.

Crea la base y el usuario de la aplicación (cambia `CLAVE_BD`):

```bash
mysql -e "CREATE DATABASE brother CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; CREATE USER 'brother'@'localhost' IDENTIFIED BY 'CLAVE_BD'; GRANT ALL PRIVILEGES ON brother.* TO 'brother'@'localhost'; FLUSH PRIVILEGES;"
```

---

## 4. Descargar el código

El repositorio es **privado**, así que el servidor necesita una llave de despliegue.

Genera la llave en el VPS (Enter en todas las preguntas):

```bash
ssh-keygen -t ed25519 -C "vps-brother" -f /root/.ssh/id_ed25519 -N "" && cat /root/.ssh/id_ed25519.pub
```

Copia lo que imprime y pégalo en GitHub →
`https://github.com/victorraulcancah/brother/settings/keys` → **Add deploy key**
(nombre: `VPS producción`, sin marcar *Allow write access*).

Prueba la conexión y clona:

```bash
ssh -o StrictHostKeyChecking=accept-new -T git@github.com; mkdir -p /var/www && git clone git@github.com:victorraulcancah/brother.git /var/www/brother
```

> El comando `ssh -T` responde *"successfully authenticated, but GitHub does not
> provide shell access"*. Eso es lo correcto.

---

## 5. Dependencias y compilación

```bash
cd /var/www/brother/backend
composer install --no-dev --optimize-autoloader --no-interaction
npm ci
npm run build
```

`npm run build` debe terminar con `✓ built in ...` y crear `public/build/`.

---

## 6. Configuración (.env)

Crea el archivo con los valores de producción (reemplaza `TU_DOMINIO` y `CLAVE_BD`):

```bash
cat > /var/www/brother/backend/.env <<'ENV'
APP_NAME=Brother
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://TU_DOMINIO

APP_LOCALE=es
APP_FALLBACK_LOCALE=es
APP_FAKER_LOCALE=es_PE
APP_TIMEZONE=America/Lima

LOG_CHANNEL=stack
LOG_STACK=daily
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=brother
DB_USERNAME=brother
DB_PASSWORD=CLAVE_BD

SESSION_DRIVER=database
SESSION_LIFETIME=120
CACHE_STORE=database
QUEUE_CONNECTION=database
BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local

MAIL_MAILER=log
MAIL_FROM_ADDRESS="no-reply@TU_DOMINIO"
MAIL_FROM_NAME="${APP_NAME}"
ENV
```

Genera las dos claves de cifrado (la de Laravel y la de los tokens JWT):

```bash
cd /var/www/brother/backend && php artisan key:generate --force && php artisan jwt:secret --force
```

---

## 7. Migraciones y datos iniciales

```bash
cd /var/www/brother/backend
php artisan migrate --force
ADMIN_EMAIL="tu-correo@empresa.com" ADMIN_PASSWORD="CLAVE_ADMIN" EMPRESA_RUC="20123456789" EMPRESA_RAZON_SOCIAL="Mi Empresa S.A.C." php artisan db:seed --class=ProductionSeeder --force
php artisan storage:link
```

> **No ejecutes `php artisan db:seed` a secas.** El seeder por defecto
> (`DatabaseSeeder`) carga clientes, productos y ventas de demostración.
> `ProductionSeeder` crea solo roles, empresa, usuario administrador, métodos de
> pago y motivos de movimiento. Se puede repetir sin duplicar nada.

---

## 8. Permisos

```bash
chown -R www-data:www-data /var/www/brother && chmod -R 775 /var/www/brother/backend/storage /var/www/brother/backend/bootstrap/cache
```

---

## 9. Nginx

```bash
cat > /etc/nginx/sites-available/brother <<'NGINX'
server {
    listen 80;
    listen [::]:80;
    server_name TU_DOMINIO;
    root /var/www/brother/backend/public;

    index index.php;
    charset utf-8;

    # Subida de imágenes (logo de empresa, fotos de productos).
    client_max_body_size 20M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    # Cache larga para los assets con hash que genera Vite.
    location /build/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* { deny all; }

    error_page 404 /index.php;
    access_log /var/log/nginx/brother-access.log;
    error_log  /var/log/nginx/brother-error.log;
}
NGINX

Reemplaza el marcador por tu dominio real (o por la IP del VPS si aún no tienes
dominio) y activa el sitio:

```bash
sed -i 's/TU_DOMINIO/sistema.miempresa.com/' /etc/nginx/sites-available/brother
ln -sf /etc/nginx/sites-available/brother /etc/nginx/sites-enabled/brother
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
```

Sube el límite de subida también en PHP:

```bash
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 20M/; s/^post_max_size = .*/post_max_size = 20M/' /etc/php/8.3/fpm/php.ini && systemctl restart php8.3-fpm
```

---

## 10. Cachés de producción

```bash
cd /var/www/brother/backend && php artisan config:cache && php artisan route:cache && php artisan view:cache
```

Prueba: entra a `http://TU_DOMINIO`. Debe aparecer la pantalla de login.

---

## 11. HTTPS (solo si tienes dominio apuntando al VPS)

```bash
apt install -y certbot python3-certbot-nginx && certbot --nginx -d TU_DOMINIO --agree-tos -m tu-correo@empresa.com --redirect
```

Certbot renueva solo. Después, confirma que `APP_URL` en `.env` empiece con
`https://` y vuelve a ejecutar `php artisan config:cache`.

---

## 12. Después de publicar

1. Entra con el correo y la contraseña del paso 7 y **cámbiala desde el perfil**.
2. Carga los **costos reales** de los productos (Inventario → Existencias o vía
   compras). Sin `costo_promedio` los reportes de Ganancias y Utilidades muestran
   márgenes irreales.
3. Si usas la app móvil (`app_abarrotes`), actualiza `apiBaseUrl` en
   `lib/config/app_config.dart` a `https://TU_DOMINIO/api` y recompila.

---

## Actualizaciones posteriores

Cada vez que subas cambios a GitHub:

```bash
cd /var/www/brother/backend && git pull && composer install --no-dev --optimize-autoloader --no-interaction && npm ci && npm run build && php artisan migrate --force && php artisan optimize && chown -R www-data:www-data /var/www/brother && systemctl reload php8.3-fpm
```

---

## Si algo falla

| Síntoma | Dónde mirar |
|---|---|
| Error 500 en blanco | `tail -50 /var/www/brother/backend/storage/logs/laravel.log` |
| Error 502 Bad Gateway | `systemctl status php8.3-fpm` y `tail -50 /var/log/nginx/brother-error.log` |
| Página sin estilos | faltó `npm run build`, o `public/build/` no existe |
| "Permission denied" al guardar | repite el paso 8 (permisos) |
| Cambios del `.env` que no aplican | `php artisan config:clear && php artisan config:cache` |
| Login responde 500 | falta `php artisan jwt:secret --force` |
