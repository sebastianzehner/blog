---
title: "Tu propio servidor Matrix con Synapse: ¿Por qué deberías alojarlo tú mismo?"
summary: En este artículo configuro mi propio servidor Matrix con Synapse y Docker Compose. Junto a una breve introducción al protocolo descentralizado, muestro la instalación completa con PostgreSQL, Traefik y Cloudflare Tunnel.
date: 2026-04-08T11:00:00-03:00
lastmod: 2026-04-08T11:00:00-03:00
draft: false
tags:
  - matrix
  - homeserver
  - synapse
  - open-source
  - self-hosting
categories:
  - techlab

ShowToc: true
TocOpen: true

params:
  author: Sebastian Zehner
  ShowPageViews: true

cover:
  image: /img/matrix-homeserver-cover.webp
  alt: Matrix Homeserver
  hidden: false
  relative: false
  responsiveImages: false

translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: es
  date: 2026-04-08
  time: "12:53:02"
---

**Descentralización, protección de datos y control total sobre tu comunicación: con Synapse y Docker, todo es más sencillo de lo que parece.**

## ¿Qué es la Matrix y por qué es diferente?

La mayoría de las aplicaciones de mensajería que utilizamos a diario (WhatsApp, Telegram, Signal, iMessage) comparten algo en común: están organizadas de manera centralizada. Esto significa que tus mensajes circulan a través de servidores que no puedes controlar. Confías en una empresa que se encarga de mantener la infraestructura, proteger tus datos y hacer que el servicio funcione correctamente. ¿Pero qué pasa si esa empresa es vendida, cambia sus políticas de privacidad o simplemente decide dejar de ofrecer el servicio?

[Matrix](https://matrix.org) resuelve este problema desde una perspectiva diferente: se trata de un **protocolo de comunicación abierto y descentralizado**. Al igual que ocurría con el correo electrónico en el pasado, cada persona puede mantener su propio servidor, y todos los servidores pueden comunicarse entre sí; a esto se le llama **federación**. Tu cuenta en `@tu:tu-servidor.es` puede enviar mensajes sin problemas a alguien en `@otro:matrix.org`, de la misma manera que puedes enviar un correo desde Gmail a una dirección de Outlook.

Esto significa:

- **Ninguna dependencia** de un único proveedor.
- **Cifrado completo de extremo a extremo** (opcional, pero recomendado).
- **Autodeterminación**: Tú decides quién puede crear una cuenta en tu servidor.
- **Puentes (Bridges):** Matrix puede conectarse con servicios como WhatsApp, Telegram, Discord, Signal y muchos otros, y todo ello desde un único cliente.

El servidor de hogares de Matrix más conocido es Synapse, desarrollado por Element (anteriormente New Vector). Está escrito en Python, está bien documentado y se puede instalar y configurar fácilmente utilizando Docker.

## ¿Por qué alojarlo tú mismo?

Quien gestiona su propio servidor de Synapse gana varias cosas a la vez:

**Protección de datos**: Tus mensajes y archivos multimediales se encuentran en tu propia infraestructura. No obstante, gracias a la tecnología de federación, es posible replicarlos también en los servidores de otros participantes. De esta manera, mantienes el control total sobre tus datos y no te conviertes en un “producto” de un proveedor comercial.

**Control de las copias de seguridad**: Ya no existen soluciones de respaldo específicas para cada aplicación. Usted se encarga de proteger la base de datos PostgreSQL y el directorio de medios de acuerdo con sus propias reglas, por ejemplo, utilizando [restic](https://restic.net/).

**Cuentas de usuario propias**: Puedes crear cuentas para tu familia, amigos o una comunidad en particular. El servidor te pertenece.

**Los puentes como núcleo central**: En lugar de abrir cinco aplicaciones diferentes, puedes integrar WhatsApp, Telegram o Discord en tu cliente Matrix preferido a través de los puentes (bridges) de Matrix. Un único cliente que lo abarca todo.

**Longevidad**: Mientras tu servidor esté en funcionamiento, tus salas de chat y su historial permanecerán disponibles. Ningún proveedor podrá quitártelos.

## Requisitos previos

Para seguir esta guía, necesitarás:

- Un servidor Linux (utilizo Alpine Linux) con Docker y Docker Compose.
- Un proxy inverso; yo utilizo **Traefik**.
- Un dominio; yo uso `matrix.techlab.icu`.
- Opcional: Un túnel de Cloudflare para el acceso externo.

## Instalación con Docker Compose

### Creación de la estructura del índice

Primero, crearemos los directorios necesarios:

```bash
mkdir -p ~/docker-compose/synapse
mkdir -p ~/docker/synapse
mkdir -p ~/docker/synapse/files
mkdir -p ~/docker/synapse/db-data

nvim ~/docker-compose/synapse/docker-compose.yml
```

> Esto corresponde a mi estructura de directorios personal para todos los contenedores Docker: los datos relacionados con los volúmenes se encuentran en la carpeta `~/docker` y los datos de Compose, en la carpeta `~/docker-compose`. De esta manera, todo queda organizado de manera clara, y es precisamente estos dos directorios los que protejo regularmente con el herramienta restic. Quizás incluso escriba un artículo propio al respecto.

### docker-compose.yml

Aquí está mi configuración productiva con Synapse, PostgreSQL e integración de Traefik:

```yaml
services:
  synapse:
    container_name: synapse
    image: docker.io/matrixdotorg/synapse:latest
    restart: unless-stopped
    environment:
      - SYNAPSE_CONFIG_PATH=/data/homeserver.yaml
      - UID=1000
      - GID=1000
    volumes:
      - /home/user/docker/synapse/files:/data
    depends_on:
      - synapse-db
    networks:
      synapse:
      proxy:
        ipv4_address: 192.168.10.70

    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy"

      # HTTP to HTTPS Redirect
      - "traefik.http.routers.synapse.entrypoints=http"
      - "traefik.http.routers.synapse.rule=Host(`matrix.techlab.icu`)"
      - "traefik.http.middlewares.synapse-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.routers.synapse.middlewares=synapse-https-redirect"

      # Main Secure Router for Synapse
      - "traefik.http.routers.synapse-secure.entrypoints=https"
      - "traefik.http.routers.synapse-secure.rule=Host(`matrix.techlab.icu`)"
      - "traefik.http.routers.synapse-secure.tls=true"
      - "traefik.http.routers.synapse-secure.service=synapse"
      - "traefik.http.services.synapse.loadbalancer.server.port=8008"

      # Define middleware to block the static path
      - "traefik.http.middlewares.block-synapse-static.replacepath.path=/forbidden"
      - "traefik.http.routers.synapse-static.rule=Host(`matrix.techlab.icu`) && PathPrefix(`/_matrix/static`)"
      - "traefik.http.routers.synapse-static.entrypoints=https"
      - "traefik.http.routers.synapse-static.tls=true"
      - "traefik.http.routers.synapse-static.middlewares=block-synapse-static"
      - "traefik.http.routers.synapse-static.priority=100"

  synapse-db:
    image: docker.io/postgres:15-alpine
    container_name: synapse-db
    restart: unless-stopped
    environment:
      - POSTGRES_USER=synapse_user
      - POSTGRES_PASSWORD=secure_password
      - POSTGRES_DB=synapse
      - POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C
    volumes:
      - /home/user/docker/synapse/db-data:/var/lib/postgresql/data
    networks:
      synapse:

networks:
  synapse:
  proxy:
    external: true
```

Unas pocas observaciones sobre la configuración:

- A Synapse se le asigna una **dirección IP fija** en la red `proxy`, lo que permite que el tráfico de datos la localice de manera fiable.
- El middleware `block-synapse-static` impide que `/_matrix/static` sea accesible desde el exterior; en ese lugar solo se encuentra la página de bienvenida estándar, que nadie necesita desde afuera. La ruta de acceso es redirigida de forma interna, lo que provoca un error 404.
- PostgreSQL se inicializa utilizando los marcadores `lc-collate=C` y `lc-ctype=C`; esta es una exigencia oficial de Synapse para que las operaciones en la base de datos se realicen de manera correcta.

### Generar el archivo de configuración

Synapse incluye un generador para el código inicial `homeserver.yaml`. Iniciamos el contenedor una vez en modo de generación y proporcionamos nuestra propia dominio.

```bash
docker run -it --rm \
  --mount type=volume,src=synapse-data,dst=/data \
  -e SYNAPSE_SERVER_NAME=matrix.techlab.icu \
  -e SYNAPSE_REPORT_STATS=no \
  matrixdotorg/synapse:latest generate
```

El contenedor guarda los archivos generados en un volumen Docker. Como usuario con derechos de root, los copiamos a nuestra carpeta de trabajo.

```bash
sudo -i
cd /var/lib/docker/volumes/synapse-data/_data/
cp * /home/user/docker/synapse/files
exit

cd /home/user/docker/synapse/files
sudo chown user: *
```

### Modificar el archivo homeserver.yaml

Ahora abrimos el código ``homeserver.yaml`` y configuramos la conexión a la base de datos. Reemplazamos la configuración estándar de SQLite por el bloque correspondiente a PostgreSQL:

```yaml
database:
  name: psycopg2
  args:
    user: synapse_user
    password: secure_password
    database: synapse
    host: synapse-db
    cp_min: 5
    cp_max: 10
```

El nombre de host `synapse-db` corresponde al nombre del contenedor que se encuentra en `docker-compose.yml`; Docker lo resuelve internamente.

### Iniciar el servidor

```bash
cd ~/docker-compose/synapse
docker compose up -d
```

Tras el inicio, debajo de `https://matrix.techlab.icu` debería aparecer el siguiente mensaje:

```
It works! Synapse is running
Your Synapse server is listening on this port and is ready for messages.

To use this server you'll need a Matrix client.

Welcome to the Matrix universe :)
```

## Acceso externo a través de Cloudflare Tunnel

Para que el servidor sea accesible también desde fuera de la red doméstica, configuro un **túnel de Cloudflare**. Allí se crea un nombre de host público.

- **Nombre del host**: `matrix`
- **Dominio**: `techlab.icu`
- **Tipo de servicio**: `https`
- **URL**: `matrix.techlab.icu`

Importante nota: El tipo de servicio `https` garantiza que la conexión desde Cloudflare Edge hasta el servidor de Traefik se mantenga completamente encriptada. Internamente, Pi-hole resuelve los nombres de dominio (DNS) para obtener la dirección IP del servidor de Traefik mediante el proceso `matrix.techlab.icu`.

## Activar la Federación

Matrix funciona gracias a que varios servidores pueden comunicarse entre sí sin problemas. Para que mi servidor pueda interactuar con `matrix.org` y otros servidores, es necesario que la función de federación esté activada. Por defecto, Synapse utiliza el puerto 8448 para esta comunicación; sin embargo, yo lo redirijo al puerto 443, ya que este es el que se utiliza a través del túnel de Cloudflare.

Dentro de ``homeserver.yaml``:

```yaml
# allow room access over federation
matrix_synapse_allow_public_rooms_over_federation: true

# enable federation on port 443
serve_server_wellknown: true
```

Se puede verificar el estado utilizando el elemento [Matrix Federation Tester](https://federationtester.matrix.org/). Un informe exitoso se presenta de la siguiente manera:

```
Got 4 connection reports.
Homeserver version: Synapse 1.150.0

[IPv4-Address]:443  ✓ Success
[IPv4-Address]:443  ✓ Success
[IPv6-Address]:443  ✓ Success
[IPv6-Address]:443  ✓ Success
```

**Nota práctica**: Incluso después de que el Federation Tester muestre que todo está en orden (con indicadores verdes), puede pasar algún tiempo antes de que la comunicación con los servidores externos funcione de manera fiable. Se necesita un poco de paciencia; no obstante, después de unos minutos, todo funcionará sin problemas.

## Creación de una cuenta de administrador

El primer usuario, que a la vez será el administrador, se crea directamente dentro del contenedor en funcionamiento:

```
docker exec -it synapse register_new_matrix_user http://localhost:8008 -c /data/homeserver.yaml
```

La orden solicita de forma interactiva el nombre de usuario, la contraseña y si el cuenta debe tener derechos de administrador.

## Clientes Matrix

### Element Web y Desktop

El cliente de Matrix más conocido es **Element**. Está disponible como aplicación web en el enlace [app.element.io](https://app.element.io), así como como aplicación de escritorio para macOS, Windows y Linux.

Al iniciar sesión por primera vez en el propio servidor, es necesario configurar manualmente la dirección URL del servidor. En macOS, es posible que el cliente no funcione correctamente hasta que el sistema operativo realice una consulta de seguridad; en este caso, macOS preguntará si la aplicación puede acceder a la red local. Es necesario conceder permiso para dicho acceso y reiniciar el cliente.

### Los dispositivos se verifican

Matrix admite el proceso de cross-signing para la verificación de dispositivos. Si se desea comunicar de manera segura con alguien, se puede verificar su dispositivo: en ambos lados aparece una ventana con símbolos y términos idénticos que deben ser comparados. Si los símbolos coinciden y ambas partes lo confirman, el dispositivo del interlocutor se considera fiable y la comunicación se encripta de extremo a extremo.

### Configurar la seguridad de las llaves

Durante el primer inicio de sesión, se ofrece la opción de configurar una **seguridad basada en claves**. No se debe omitir este paso. Al hacerlo, se genera una clave de recuperación que es necesario guardar de manera segura; yo la guardo en [KeePassXC](https://keepassxc.org) tanto como un registro protegido como un archivo exportado.

Sin esta clave, los mensajes cifrados se perderán irremediablemente en caso de pérdida del dispositivo o reinicio sin una sesión activa.

### Iamb: Matrix en el terminal

Para todos aquellos que no quieran salir de su terminal: [Iamb](https://iamb.chat) es un cliente de Matrix completo, diseñado al estilo de los terminales tradicionales y inspirado en las combinaciones de teclas de Vim. Aquellos que trabajan con Neovim y Tmux se sentirán completamente a gusto con este herramienta.

## Estrategias de copia de seguridad

En Synapse, hay que asegurar dos cosas:

1. La base de datos PostgreSQL bajo `~/docker/synapse/db-data/`: Aquí se encuentran todos los eventos relacionados con la Matrix (mensajes, historial del espacio, metadatos).

2. Los archivos que se encuentran bajo `~/docker/synapse/files/` incluyen la configuración, los medios cargados y, lo que es especialmente importante, la **clave de firma** (Signing Key).

La Signing Key constituye el elemento de identificación criptográfica del servidor en la red Matrix. En caso de que se pierda, los demás servidores dejarán de confiar en él; la federación se desintegrará y será necesario reinstalar el servidor. Por esta razón, la he almacenado también en mi gestor de contraseñas, además del respaldo creado con el programa restic.

> Protejo automáticamente todo el directorio `~/docker/` con el herramienta restic; de esta manera, ambos caminos críticos siempre están incluidos en la lista de protección.

## Perspectivas futuras: Bridges y Cactus Comments

Esto es solo el comienzo. Matrix, gracias a su protocolo abierto, constituye una base excelente para futuras integraciones.

**Bridges** permiten conectar otros servicios de mensajería. Quien desee que las comunicaciones realizadas a través de WhatsApp, Telegram o Discord se enruten a través de su propio servidor Matrix puede hacerlo utilizando los contenedores de tipo Bridge correspondientes. Todo el contenido finalmente llega a un único cliente Matrix.

Actualmente no utilizo ningún tipo de Bridges (servicios que permiten la comunicación entre redes diferentes), pero estoy pensando en configurar uno para el envío de correos electrónicos. Lamentablemente, no es posible mantener un servidor de correo electrónico propio en un entorno doméstico (homelab) de manera sencilla: sin una dirección IP fija y sin la confianza de los principales proveedores de servicios de internet, los correos pueden terminar directamente en la carpeta de spam o ser rechazados por completo. Por eso me alegro mucho de poder recuperar, al menos en parte, esa libertad con Matrix.

**Cactus Comments** utiliza Matrix como plataforma de backend para los comentarios de los blogs. Para cada artículo de blog, existe un espacio de chat específico en Matrix donde los lectores pueden dejar sus comentarios, sin necesidad de tener una cuenta en un sistema de comentarios externo. Más detalles sobre esto se encuentran en un artículo separado. Cactus Comments ya está en funcionamiento en mi blog, a través de mi propio servidor Synapse.

¿Tienes alguna pregunta sobre la instalación de tus propias Synapse? No dudes en escribirme; lo mejor es hacerlo directamente a través de Matrix. Mi dirección es `@sebastian:matrix.techlab.icu` o puedes dejar un comentario; este también llegará a mi cuenta en Matrix al final.

Un cordial saludo, Sebastian.

{{< chat self-hosting-matrix-homeserver-synapse >}}
