+++
title = 'Gestión autónoma de redes sociales con Mixpost'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = 'Tuve la idea de simplificar mi participación en las redes sociales sin pagar mucho dinero ni cuotas mensuales de suscripción. Encontré Mixpost como solución autoalojada.'
date = 2024-08-25T18:07:53-04:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2024-08-25T18:07:53-04:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Social Media', 'Mixpost', 'Simple Life']
categories = ['Tech']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/self-hosted-social-media-management-with-mixpost.webp'
    alt = 'Imagen principal de Gestión autónoma de redes sociales con Mixpost'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

Tuve la idea de simplificar mi participación en las redes sociales sin tener que pagar mucho dinero ni cuotas de suscripción mensuales. Encontré Mixpost como una solución autoalojada para la gestión de redes sociales. Así que lo configuré y lo he estado probando durante los últimos días. Hoy quiero compartir mi experiencia con Mixpost en un equipo local en mi casa en Paraguay.

La instalación es fácil de manejar con contenedores Docker. Al principio, intenté instalar Mixpost en mi NAS Synology, donde los contenedores Docker suelen ejecutarse en el Synology Container Manager, pero lamentablemente Mixpost no lo hace.

Hubo un problema con el contenedor de base de datos MySQL. Como la instalación en un NAS no es compatible, creé una máquina virtual con Ubuntu en mi Mac Studio e instalé allí el entorno Docker.

Volví a hacer la misma configuración y funcionó inmediatamente. Pero no era perfecto y tuve que hacer algunas mejoras y ajustes manuales para mis necesidades.

También necesitaba un nuevo nombre de dominio y acceso externo desde Internet. No puedo reenviar ciertos puertos en mi ubicación, pero he descubierto formas alternativas y que trabajó para mí. Te mostraré exactamente lo que hice.

## ¿Cuáles son mis requisitos mínimos?

- Mixpost funciona en un ordenador local
- Migración posterior a un servidor local
- Sin restricciones ni cuotas mensuales de suscripción
- Conexión a las cuentas de las redes sociales más populares
- Nombre de dominio con acceso externo
- Nombre de dominio con acceso interno
- HTTPS seguro para todas las conexiones
- Fácil copia de seguridad y restauración de la base de datos
- Fácil de mover o utilizar un servidor diferente

## ¿Cómo instalar Mixpost?

La [documentación de Mixpost](https://docs.mixpost.app/) es muy útil a la hora de instalar Mixpost en una máquina Linux con Docker. Yo empecé con la versión gratuita Mixpost Lite. Sí, la versión Mixpost Pro implica un pago único, pero creo que merece la pena.

Empecé con la instalación de Docker después de configurar mi máquina virtual con Ubuntu y conectarme con SSH a través de mi terminal. Simplemente seguí los cinco sencillos pasos de la [documentación](https://docs.mixpost.app/lite/installation/docker) para instalar Docker y Mixpost en mi máquina virtual local.

Nunca he usado Traefik antes y fue un poco confuso para mí, pero ahora está bien y funciona bien.

## Mi configuración para los contenedores Docker

En este momento mi archivo docker-compose.yml tiene este aspecto:

```YAML
version: '3.1'

services:
    traefik:
      image: "traefik"
      restart: unless-stopped
      command:
        - "--api=true"
        - "--api.insecure=true"
        - "--providers.docker=true"
        - "--providers.docker.exposedbydefault=false"
        - "--entrypoints.web.address=:80"
        - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
        - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
        - "--entrypoints.websecure.address=:443"
        - "--providers.file.directory=/etc/traefik/dynamic" # for dynamic configuration
        - "--providers.file.watch=true" # for dynamic configuration
      ports:
        - "80:80"
        - "443:443"
        # - "8080:8080" # traefik dashboard disabled
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock:ro
        # Mount the dynamic configuration
        - ./certs-traefik.yml:/etc/traefik/dynamic/certs-traefik.yml
        # Mount the directory containing the certs for mixpost.lan
        - ../certs:/etc/certs/
    mixpost:
        image: inovector/mixpost:latest
        env_file:
            - .env
        ports:
            - "127.0.0.1:9000:80"
        labels:
          - traefik.enable=true
          - traefik.http.routers.mixpost.rule=Host(`${APP_DOMAIN}`) || Host(`${APP_DOMAIN_WEB}`)
          - traefik.http.routers.mixpost.tls=true
          - traefik.http.routers.mixpost.entrypoints=web,websecure
          - traefik.http.routers.mixpost.tls.certresolver=mytlschallenge
          - traefik.http.middlewares.mixpost.headers.SSLRedirect=true
          - traefik.http.middlewares.mixpost.headers.STSSeconds=315360000
          - traefik.http.middlewares.mixpost.headers.browserXSSFilter=true
          - traefik.http.middlewares.mixpost.headers.contentTypeNosniff=true
          - traefik.http.middlewares.mixpost.headers.forceSTSHeader=true
          - traefik.http.middlewares.mixpost.headers.SSLHost=`${APP_DOMAIN}`
          - traefik.http.middlewares.mixpost.headers.STSIncludeSubdomains=true
          - traefik.http.middlewares.mixpost.headers.STSPreload=true
          - traefik.http.routers.mixpost.middlewares=mixpost@docker
        volumes:
            - storage:/var/www/html/storage/app
            - logs:/var/www/html/storage/logs
        depends_on:
            - mysql
            - redis
        restart: unless-stopped
    mysql:
        image: 'mysql/mysql-server:8.0'
        environment:
            MYSQL_DATABASE: ${DB_DATABASE}
            MYSQL_USER: ${DB_USERNAME}
            MYSQL_PASSWORD: ${DB_PASSWORD}
        volumes:
            - 'mysql:/var/lib/mysql'
        healthcheck:
            test: ["CMD", "mysqladmin", "ping", "-p ${DB_PASSWORD}"]
            retries: 3
            timeout: 5s
        restart: unless-stopped
    redis:
        image: 'redis:latest'
        command: redis-server --appendonly yes --replica-read-only no
        volumes:
            - 'redis:/data'
        healthcheck:
            test: ["CMD", "redis-cli", "ping"]
            retries: 3
            timeout: 5s
        restart: unless-stopped

volumes:
    traefik_data:
      driver: local
    mysql:
        driver: local
    redis:
        driver: local
    storage:
        driver: local
    logs:
        driver: local
```

He hecho algunos cambios para el cifrado ya que mi instalación es local y no puedo utilizar Letsencrypt. He eliminado la configuración para Letsencrypt en el contenedor Traefik y en su lugar he utilizado una configuración dinámica.

Esto me permite instalar mis propios certificados y montar las unidades para la configuración dinámica y mi certificado con archivo de claves.

He escrito un [blogpost](/es/posts/how-do-we-sign-our-ssl-certificates-with-openssl-for-local-web-services/) en el pasado describiendo como firmo mis propios certificados SSL con OpenSSL para servicios web locales.

También añadí un segundo dominio para el acceso externo al Mixpost Conatiner. Así que `APP_DOMAIN` es mi dominio local y `APP_DOMAIN_WEB` es mi dominio externo.

Mi archivo .env:

```YAML
# The name of your application.
APP_NAME=Mixpost

# Key used to encrypt and decrypt sensitive data. Generate this using the following tool:
# https://mixpost.app/tools/encryption-key-generator
APP_KEY=keyfrommixpostwebsite

# Debug mode setting. Set to `false` for production environments.
APP_DEBUG=false

# Your app's domain or subdomain, without the 'http://' or 'https://' prefix.
APP_DOMAIN=domain.local
APP_DOMAIN_WEB=external.domain.com

# Full application URL is automatically configured; no modification required.
APP_URL=https://${APP_DOMAIN}

# MySQL connection setup.
DB_DATABASE=mixpost_db
DB_USERNAME=mixpost_user
DB_PASSWORD=astrongpassword

# Specify the email address to be used for SSL certificate registration and notifications.
SSL_EMAIL=myemal@gmail.com
```

Aquí sólo he añadido una nueva variable para mi nombre de dominio externo.

Mi archivo certs-traefik.yml:

```YAML
tls:
  certificates:
    - certFile: /etc/certs/mixpost.lan.crt
      keyFile: /etc/certs/mixpost.lan.key
```

Utilizo mis propios certificados SSL autofirmados y por ello he integrado el archivo .crt y .key en el contenedor Traefik.

Con esta configuración puedo acceder al panel de Mixpost con mi dominio local y HTTPS funciona con mi certificado autofirmado. ¿Qué he tenido que cambiar para el acceso externo?

## Túnel Cloudflare Zero Trust

En primer lugar, conecté mi nuevo dominio a Cloudflare y creé un túnel para llegar a mi panel local de Mixpost. También instalé el conector en mi máquina virtual y la configuración fue realmente fácil con sólo un contenedor Docker más.

Los certificados SSL son configurados automáticamente por Cloudflare y la conexión HTTPS funciona cuando le digo a Cloudflare que ignore el certificado local.

Ahora mi tablero local Mixpost es accesible a través de Internet y puedo configurar las cuentas de redes sociales en el siguiente paso.

## Configurar cuentas de redes sociales

En la versión Mixpost Lite autoalojada, sólo son posibles las conexiones con páginas de Facebook, X y cuentas de Mastodon. En los [Docs](https://docs.mixpost.app/services/) se describen las instrucciones para los servicios de terceros y son fáciles de seguir.

He configurado todas las conexiones posibles con mis cuentas de redes sociales y he probado algunos posts. Posts individuales y múltiples posts en tres plataformas simultáneamente y todo funcionó como se esperaba. Es posible crear diferentes versiones en un post y eso es bueno porque X sólo permite 280 caracteres y otros 500 o 5000 caracteres.

También quiero usar Youtube, TikTok, Instagram y Pinterest con Mixpost. Para eso necesito comprar la licencia Pro y lo haré más adelante.

## Copia de seguridad de la base de datos MySQL

He hecho una copia de seguridad de la base de datos con el siguiente comando:

```BASH
docker exec CONTAINERNAME /usr/bin/mysqldump -u root --password=ROOTPASSWORD DATABASE > backup.sql
```

O lo mismo pero comprimido con este comando:

```BASH
docker exec CONTAINERNAME /usr/bin/mysqldump -u root --password=ROOTPASSWORD DATABASE | gzip > backup.sql.gz
```

> Consejo: Guarde el archivo .sql o .sql.gz en un lugar seguro.

## Restaurar la base de datos MySQL

Para restaurar la base de datos utilice el siguiente comando:

```BASH
cat backup.sql | docker exec -i CONTAINERNAME /usr/bin/mysql -u root --password=ROOTPASSWORD DATABASENAME
```

O si se comprime con este comando:

```BASH
zcat backup.sql.gz | docker exec -i CONTAINERNAME /usr/bin/mysql -u root --password=ROOTPASSWORD DATABASENAME
```

## ¿Y ahora qué?

A continuación quiero crear una nueva máquina virtual y restaurar la instalación de Mixpost para comprobar si todo funciona como esperaba.

Después compraré la versión Pro y actualizaré mi instalación local.

Más tarde, me trasladaré a otro servidor local y ejecutaré mi instalación de Mixpost como aplicación de producción y seguiré publicando posts en varias cuentas de redes sociales utilizando Mixpost.

Si tienes alguna pregunta, por favor házmelo saber en los comentarios.

Saludos Sebastian

{{< chat self-hosted-social-media-management-with-mixpost >}}
