---
title: "Cactus Comments: discusiones en el blog a través de tu propio servidor Matrix"
summary: "Cómo integré Cactus Comments en mi blog Hugo – un sistema de comentarios descentralizado y sin rastreo basado en mi propio servidor Matrix – incluyendo la compilación del cliente, la configuración del appservice y el diseño con Catppuccin."
date: 2026-04-18T17:10:00-03:00
lastmod: 2026-04-18T17:10:00-03:00
draft: false
tags:
  - matrix
  - cactus
  - homeserver
  - hugo
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
  image: /img/cactus-comments-cover.webp
  alt: Comentarios sobre los cactus
  hidden: false
  relative: false
  responsiveImages: false

translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: es
  date: 2026-04-18
  time: "18:06:31"
---

Los sistemas de comentarios como Disqus son prácticos, pero también traen consigo funciones de seguimiento de usuarios, publicidad y otras dependencias externas. Cactus Comments funciona de manera diferente: los comentarios se almacenan directamente en los espacios dedicados a los comentarios («Matrix Rooms») del propio servidor local.

En el [último artículo](https://sebastianzehner.com/de/posts/self-hosting-matrix-homeserver-synapse/) mostré cómo instalar Synapse con Docker y cómo administrar un servidor de hogares Matrix propio. Hoy continuaremos con este tema: gracias a **Cactus Comments**, cada artículo de blog dispone de su propio espacio de chat Matrix. Los lectores pueden dejar comentarios sin necesidad de registrarse en un proveedor externo, y yo mantengo el control total sobre mis datos.

## ¿Qué son los Cactus Comments?

[Cactus Comments](https://cactus.chat/) es un sistema de comentarios federado para la web abierta que utiliza el protocolo Matrix como backend. El principio es sencillo y elegante: para cada artículo de blog se crea automáticamente un espacio correspondiente en el sistema Matrix. Quien desee dejar un comentario debe iniciar sesión con su cuenta Matrix; esta puede estar almacenada en `matrix.org`, en mi propio servidor o en cualquier otro servidor que soporte el protocolo Matrix. ¡Gracias a la tecnología de federación!

El sistema consta de dos partes:

- **Cactus Appservice**: un servicio desarrollado en Python que funciona como un bot de tipo “matrix” (en este caso: `@cactusbot`) en el servidor doméstico, y se encarga de administrar las salas.
- **Cactus Client**: una aplicación web escrita en JavaScript y utilizando el framework Elm, que se integra en el blog para mostrar el campo de comentarios.

## Requisitos previos

- Un servidor doméstico de Synapse en funcionamiento (mi guía al respecto: [Servidor doméstico de Matrix propias, equipado con Synapse.](https://sebastianzehner.com/de/posts/self-hosting-matrix-homeserver-synapse/))
- Docker y Docker Compose
- Node.js y npm (para la compilación del lado del cliente).
- Una página web de Hugo

## Construir el cliente Cactus

El Cactus Client no se distribuye como un archivo completo (en formato de paquete, o “bundle”). Es necesario compilarlo uno mismo. Además, deseo guardar una copia propia en el repositorio local de Forgejo, en lugar de depender de GitLab.

Clonar el repositorio y reflejarlo en Forgejo:

```bash
git clone https://gitlab.com/cactus-comments/cactus-client.git
cd cactus-client
 
git remote rename origin gitlab
git remote add origin https://git.techlab.icu/sebastianzehner/cactus-client.git
 
git push origin --all
git push origin --tags
```

Ejecutar la compilación:

```bash
npm install
npm run build
```

> Si aún no tienes tu propio Forgejo, puedes saltarte el paso de “reflejar” (es decir, no necesitas crear una copia del mismo).

### Posible error: el paquete Elm está dañado (corrupto)

Durante el primer intento de crear una nueva versión (build), surgió el siguiente error en mi sistema:

```
🚨  CORRUPT PACKAGE DATA
I downloaded the source code for ryannhg/date-format 2.3.0 from:
    https://github.com/ryannhg/date-format/zipball/2.3.0/
But it looks like the hash of the archive has changed since publication.
```

El paquete `ryannhg/date-format` ha cambiado su valor de hash desde su publicación; este es un problema común en las dependencias de Elm cuando el autor del paquete modifica posteriormente la fecha de la versión. La solución es descargar el paquete manualmente y colocarlo en el lugar correcto.

```bash
cd ~/.elm/0.19.1/packages/ryannhg/date-format/2.3.0/
curl -L "https://github.com/ryannhg/date-format/zipball/2.3.0/" -o package.zip
unzip package.zip
mv ryan-haskell-date-format-b0e7928/* .
rm -rf ryan-haskell-date-format-b0e7928 package.zip
```

Luego, se vuelve a construir… Esta vez con éxito.

```
✨  Built in 3.73s.
 
dist/cactus.js        155.95 KB
dist/style.css          6.96 KB
```

## Configurar AppService

### Paso 1: Generación de tokens

El AppService necesita dos tokens aleatorios para la autenticación entre Synapse y Cactus.

```bash
cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 64 | head -n 2
```

La primera línea de la edición será `as_token` y la segunda, `hs_token`. Es importante anotar ambas.

### Paso 2: Crear el archivo de registro para Synapse

```bash
nvim ~/docker/synapse/files/cactus.yaml
```

Añada las siguientes líneas:

```yaml
id: "Cactus Comments"
 
url: "http://cactus:5000"
 
as_token: "YOUR_AS_TOKEN"
hs_token: "YOUR_HS_TOKEN"
 
sender_localpart: "cactusbot"
 
namespaces:
  aliases:
    - exclusive: true
      regex: "#comments_.*"
```

Este archivo informa a Synapse de que existe un servicio de aplicación (AppService) llamado `cactusbot`, el cual gestiona todas las alias de espacio (room aliases) que comienzan con el prefijo `#comments_`.

### Paso 3: Completar el archivo homeserver.yaml

```bash
nvim ~/docker/synapse/files/homeserver.yaml
```

Añada las siguientes líneas:

```yaml
app_service_config_files:
  - "/data/cactus.yaml"
 
allow_guest_access: true
use_appservice_legacy_authorization: true
enable_authenticated_media: false
 
public_baseurl: "https://matrix.your-domain.com"
```

> **Importante nota:** La ruta `/data/cactus.yaml` se encuentra *dentro* del contenedor Synapse. En mi caso, `~/docker/synapse/files/` está montado en la posición de `/data`.

> **Nota de seguridad:** Las configuraciones `allow_guest_access: true`, `use_appservice_legacy_authorization: true` y `enable_authenticated_media: false` son requisitos impuestos por el servicio Cactus Appservice y relajan algunas de las medidas de seguridad establecidas por Synapse. Quien desee evitar esto debería modificar el cliente Cactus de forma correspondiente; no obstante, esta tarea está fuera del alcance de esta guía.

### Paso 4: Variables de entorno para Cactus

```bash
nvim ~/docker-compose/synapse/cactus.env
```

Añada las siguientes líneas:

```env
CACTUS_HS_TOKEN=YOUR_HS_TOKEN
CACTUS_AS_TOKEN=YOUR_AS_TOKEN
CACTUS_HOMESERVER_URL=http://synapse:8008
CACTUS_USER_ID=@cactusbot:matrix.your-domain.com
```

### Paso 5: Ampliar las funcionalidades de Docker Compose

En el código `docker-compose.yml` existente para Synapse, agregaré el servicio Cactus.

```yaml
  cactus:
    image: cactuscomments/cactus-appservice:latest
    container_name: cactus
    env_file: cactus.env
    restart: unless-stopped
    networks:
      - synapse
```

El cactus se conecta a la red `synapse` para poder llegar directamente al contenedor de sinapsis que se encuentra de `http://synapse:8008`.

### Paso 6: Iniciar

```bash
cd ~/docker-compose/synapse
docker compose down
docker compose up -d synapse
# wait for Synapse to become healthy
docker compose up -d cactus
```

Para comprobar:

```bash
docker logs cactus --tail 50
docker logs synapse --tail 50
```

## Registrar el sitio web en Cactus

Antes de que Cactus pueda crear espacios para comentarios para mi blog, debo registrar mi sitio web en `cactusbot`. Esto se puede hacer directamente a través de [Elemento](https://app.element.io).

Abra un nuevo chat con `@cactusbot:matrix.your-domain.com` e introduzca lo siguiente:

```
register <websitename>
```

Si todo se configura correctamente, el bot responde con una confirmación. En los registros del contenedor, el proceso que se ha llevado a cabo con éxito se muestra de la siguiente manera:

```
INFO in app: Registration complete
INFO in app: Created site    name='websitename' owner='@your_name:matrix.your-domain.com'
INFO in app: Power level changed, replicating    room='#comments_websitename:matrix.your-domain.com'
```

## Integración con Hugo

### Copiar los archivos del cliente

```bash
cd ~/hugo/cactus-client
cp dist/cactus.js ~/hugo/blog/static/
cp dist/style.css ~/hugo/blog/static/cactus.css
```

### Creación de códigos cortos

```bash
nvim ~/hugo/blog/layouts/shortcodes/chat.html
```

Mi código corto carga el cliente Cactus e inicia la zona de comentarios. Además, lo he adaptado a mi esquema de colores **Catppuccin**, tanto para el modo “Latte” claro como para el modo “Mocha” oscuro.

```html
<script type="text/javascript" src="/cactus.js"></script>
<link rel="stylesheet" href="/cactus.css" type="text/css" />
<style>
  /* Fix avatar image distortion */
  .cactus-comment-avatar img {
    max-width: unset;
    width: 40px;
    height: 40px;
    object-fit: cover;
  }
  /* Catppuccin Latte (Light) */
  :root[data-theme="light"] {
    --cactus-text-color: #4c4f69;
    --cactus-text-color--soft: #6c6f85;
    --cactus-background-color: transparent;
    --cactus-background-color--strong: #e6e9ef;
    --cactus-border-color: #ccd0da;
    --cactus-border-width: 1px;
    --cactus-border-radius: 0.5em;
    --cactus-box-shadow-color: rgba(30, 102, 245, 0.15);
    --cactus-button-text-color: #4c4f69;
    --cactus-button-color: #dce0e8;
    --cactus-button-color--strong: #ccd0da;
    --cactus-button-color--stronger: #bcc0cc;
    --cactus-login-form-text-color: #4c4f69;
    --cactus-error-color: #d20f39;
  }
  /* Catppuccin Mocha (Dark) */
  :root[data-theme="dark"] {
    --cactus-text-color: #cdd6f4;
    --cactus-text-color--soft: #a6adc8;
    --cactus-background-color: transparent;
    --cactus-background-color--strong: #313244;
    --cactus-border-color: #45475a;
    --cactus-box-shadow-color: rgba(137, 180, 250, 0.18);
    --cactus-button-text-color: #cdd6f4;
    --cactus-button-color: #45475a;
    --cactus-button-color--strong: #585b70;
    --cactus-button-color--stronger: #6c7086;
    --cactus-login-form-text-color: #cdd6f4;
    --cactus-error-color: #f38ba8;
  }
</style>
<br />
<div id="comment-section"></div>
<script>
  initComments({
    node: document.getElementById("comment-section"),
    defaultHomeserverUrl: "https://matrix.your-domain.com",
    serverName: "matrix.your-domain.com",
    siteName: "websitename",
    commentSectionId: "{{ index .Params 0 }}",
  });
</script>
```

Todas las opciones de configuración disponibles para `initComments` se describen en [Documentación del Cactus Client](https://cactus.chat/docs/client/introduction/#configuration).

### Incluir un área de comentarios en un artículo

A partir de ahora, basta con una sola línea para agregar un área de comentarios debajo de un artículo.

```
{{</* chat cactus-comments */>}}
```

El parámetro ``cactus-comments`` es el nombre del espacio de matrices correspondiente a este artículo. Cada espacio recibe automáticamente el alias ``#comments_websitename_cactus-comments:matrix.your-domain.com``. Puedo utilizar un nombre de espacio diferente para cada artículo o el mismo para todos; esto depende de si se desea agrupar los comentarios por artículo o de manera global.

### Publicamos los cambios realizados

```bash
git add layouts/shortcodes/chat.html static/cactus.css static/cactus.js
git commit -m "migrate Cactus Comments to self-hosted matrix.your-domain.com"
git push origin
```

## En resumen

Lo que me convence de Cactus Comments: no hay base de datos externa, no hay rastreo de terceros, no hay cargas de JavaScript de dominios ajenos.

Los comentarios se almacenan como eventos Matrix ordinarios en mi propio Synapse – respaldados con mi copia de seguridad habitual de restic, versionados y portátiles.

Al mismo tiempo, cualquier persona con una cuenta Matrix puede comentar de inmediato, sin importar en qué servidor esté alojada su cuenta. Y quien aún no tenga una, puede crearse una en `matrix.org` en cuestión de minutos.

Así es como debería ser la web.

---

¿Preguntas o comentarios? Escríbeme directamente a través de Matrix: `@sebastian:matrix.techlab.icu`; o simplemente deja un comentario abajo. Este será enviado rápidamente a mi Matrix.

Un cordial saludo de Sebastian.

{{< chat self-hosting-matrix-homeserver-synapse >}}
