+++
title = 'Docker Compose en el Homelab: Mi viaje hacia una infraestructura de contenedores conectada'
summary = '''Con volúmenes claramente estructurados, redes dedicadas y un poco de automatización, mis servicios funcionan de manera confiable en varios sistemas Linux. Son rápidos de desplegar, fáciles de actualizar y estables.'''
date = 2025-08-15T09:04:00-03:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2025-08-15T09:04:00-03:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Linux', 'Docker', 'Compose', 'Container', 'Homelab', 'IPvlan', 'Networking']
categories = ['TechLab']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/docker-compose-homelab-my-journey-connected-container-infrastructure.webp'
    alt = 'Imagen destacada de Docker Compose in the Homelab: My Journey to a Connected Container Infrastructure'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

Ya sea que estés gestionando una pequeña red doméstica o un homelab completo, Docker con Docker Compose ofrece una manera flexible y ordenada de ejecutar, conectar y administrar servicios.

Cuando inicié mi primer **contenedor Docker** hace unos años, nunca imaginé que se convertiría en un pilar central de mi **homelab**. Inicialmente, Docker era solo una herramienta práctica para desplegar rápidamente un solo servicio.

Hoy en día, ejecuto docenas de servicios. Están distribuidos en cuatro sistemas Linux, organizados y gestionados con **Docker Compose**, y conectados a través de su propia **red Docker**.

Docker se ha integrado tan profundamente en mi flujo de trabajo diario que no quisiera ejecutar muchos de mis servicios de otra manera. Hace que los despliegues sean reproducibles, las actualizaciones controlables y la gestión mucho más sencilla, ya sea en un mini-PC, un servidor en rack o una pequeña máquina virtual.

## Cómo instalar Docker en diferentes distribuciones de Linux

Una de las razones por las que me gusta tanto usar Docker es la flexibilidad de instalación. En mi homelab utilizo varias distribuciones de Linux, y Docker funciona en todas:

- **Alpine Linux:** Ideal para configuraciones mínimas, se instala mediante `apk` en solo unos segundos.
- **Arch Linux:** Gracias a `pacman` y al paquete oficial de Docker, la instalación es rápida y sencilla.
- **Debian / Ubuntu:** Usando el repositorio de Docker, puedo obtener las versiones más recientes directamente vía `apt`.

Además, instalo **Docker Compose** para gestionar todos los sistemas con la misma sintaxis.

> **Nota:** En mis ejemplos en Alpine Linux, utilizo el comando `doas` (similar a `sudo`) porque Alpine no incluye `sudo` por defecto. En todos los demás sistemas, uso `sudo`.

### Alpine Linux

```bash
doas apk add docker docker-compose
```

Habilita el servicio de Docker para que se inicie automáticamente al arrancar y agrega tu usuario al grupo `docker`:

```bash
doas rc-update add docker default
doas /etc/init.d/docker start
doas addgroup $USER docker
```

### Arch Linux

```bash
sudo pacman -S docker docker-compose
```

### Debian / Ubuntu

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install the Docker packages
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

En Arch Linux y Ubuntu, el servicio Docker se inicia automáticamente, pero puedes iniciarlo manualmente con:

```bash
sudo systemctl start docker
```

También deberías agregar tu usuario al grupo `docker`:

```bash
sudo usermod -aG docker $USER
```

Después de la instalación, puedes probar si todo funciona correctamente con:

```bash
docker info
docker ps
```

## Organización de Datos y Volúmenes

**Uno de mis principios fundamentales en el homelab:** separar la configuración y los datos del contenedor.
Organizo mis volúmenes claramente por servicio, por ejemplo:

```bash
# Configuración
~/docker-compose/
   ├── traefik/
   ├── komodo/
   ├── jellyfin/
   ├── frigate/

# Datos y volúmenes
~/docker/
   ├── traefik/
   ├── komodo/
   ├── jellyfin/
   ├── frigate/
```

De esta manera, no solo puedo crear backups rápidamente, sino también mover o reinstalar servicios sin perder datos.

Planeo escribir un artículo aparte sobre backups, en el que **Restic** será el protagonista.

## Networking de Docker - La Columna Vertebral Invisible

Uno de los mayores cambios para mí fue el networking de Docker.

En lugar de que cada servicio flote aleatoriamente en la red, creé una red interna dedicada para mis contenedores. Esto permite que los servicios se comuniquen directamente entre sí sin exponer puertos innecesarios al exterior.

En combinación con **Traefik** (más sobre esto en el próximo artículo), puedo acceder fácilmente a cualquier servicio mediante un subdominio – ya sea `komodo.midominio.com` o `jellyfin.midominio.com`.

Para mí, esto significa no tener que recordar números de puerto al azar y disponer de un enrutamiento limpio y centralizado.

### Configurando Macvlan o IPvlan para Docker

Finalmente, elegí **IPvlan** para construir mi red Docker. Cubriré más detalles en el artículo sobre Traefik, pero aquí están los comandos para crear la red proxy:

```bash
sudo docker network create -d ipvlan --subnet 192.168.x.x/24 --gateway 192.168.x.x -o parent=enp1s0f0 proxy
```

Encuentra el nombre de la interfaz de red de tu servidor con:

```bash
ip address show
```

La interfaz de red del servidor `sumpfgeist.lan` se llama `enp1s0f0`, y la utilicé para configurar el IPvlan de Docker.

**Nota importante al usar esta configuración:**

Asigno las direcciones IP de los contenedores Docker manualmente en los archivos `docker-compose.yaml` para evitar conflictos de IP, ya que de lo contrario Docker asignaría las IP automáticamente sin considerar mi servidor DHCP.

Aquí hay un ejemplo de una aplicación web Meshtastic sencilla con una IP asignada manualmente y etiquetas para el reverse proxy Traefik usando la red IPvlan externa `proxy`:

```bash
services:
  meshtastic-web:
    image: ghcr.io/meshtastic/web
    container_name: meshtastic
    restart: unless-stopped
    networks:
      proxy:
        ipv4_address: 192.168.x.x
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.meshtastic.entrypoints=http"
      - "traefik.http.routers.meshtastic.rule=Host(`meshtastic.techlab.icu`)"
      - "traefik.http.middlewares.meshtastic-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.routers.meshtastic.middlewares=meshtastic-https-redirect"
      - "traefik.http.routers.meshtastic-secure.entrypoints=https"
      - "traefik.http.routers.meshtastic-secure.rule=Host(`meshtastic.techlab.icu`)"
      - "traefik.http.routers.meshtastic-secure.tls=true"
      - "traefik.http.routers.meshtastic-secure.service=meshtastic"
      - "traefik.http.services.meshtastic.loadbalancer.server.port=8080"
      - "traefik.docker.network=proxy"
networks:
  proxy:
    external: true
```

También configuré la red Docker en otros servidores, como `eq14.lan` con **Alpine Linux**:

```bash
doas docker network create -d ipvlan --subnet 192.168.x.x/24 --gateway 192.168.x.x -o parent=eth0 proxy
```

### Por Qué Uso IPvlan en Lugar de Macvlan

Una de las razones clave fue la **compatibilidad de red**:

- **Solo una dirección MAC por interfaz física** - con Macvlan, cada contenedor obtiene su propia dirección MAC. Esto puede causar problemas con algunos switches, routers o, especialmente, dispositivos de consumo que no manejan bien múltiples MAC en un solo puerto.
- **Manejo más simple de la capa 2** - IPvlan aparece como una única interfaz para la red y distribuye internamente las IP, reduciendo el riesgo de problemas con broadcasts o ARP.
- **Mejor rendimiento en algunos escenarios** - IPvlan evita la capa de drivers de red virtual que puede ralentizar Macvlan, siendo más eficiente cuando se ejecutan muchos contenedores.
- **Más compatible con firewalls y VLANs** - algunos sistemas de seguridad o gestión funcionan de manera más confiable cuando solo se usa una MAC por puerto.

## Gestión: CLI en Lugar de Interfaces Gráficas

Aunque existen herramientas como Komodo que me dan una vista central de mis cuatro hosts Docker, casi todo mi trabajo real ocurre en la terminal.

Prefiero el control directo, por ejemplo, con:

```bash
docker ps
docker compose up -d
docker compose down
```

Cada servicio tiene su propio archivo `docker-compose.yaml`, manteniendo las configuraciones transparentes y bien organizadas.

También amo mi terminal y, deliberadamente, prefiero los comandos CLI (`docker` y `docker compose`) para scripts, automatización, backups, acceso SSH y más.

### Por Qué Uso Komodo en Lugar de Portainer

Muchos usuarios de homelab dependen de Portainer para gestionar contenedores mediante una interfaz web. Sin embargo, para mi flujo de trabajo, Komodo es totalmente suficiente: un panel ligero y de código abierto que me ofrece una visión general de todos los sistemas conectados de un vistazo.

De todas formas, la gestión real la hago desde la terminal, por lo que Komodo me proporciona el equilibrio adecuado entre claridad y minimalismo.

## Ventajas de Docker Compose en el Homelab

- **Despliegue rápido:** ¿Nuevo servicio? `docker compose up` y listo.
- **Menos caos:** Sin conflictos de paquetes ni dependencias en el host.
- **Portabilidad:** Los contenedores se pueden mover fácilmente a otros sistemas.
- **Consistencia:** Los servicios se comportan de la misma manera en Arch, Debian o Alpine.

## Perspectivas

En un próximo artículo profundizaré en **Traefik**, mi proxy inverso central que conecta mi red Docker con el mundo exterior.

El acceso externo se realiza, entre otros métodos, mediante un **Cloudflare Tunnel** o **Twingate**, ambos ejecutándose como contenedores Docker en la red y que merecen, sin duda, su propio artículo en el blog.

También planeo escribir un artículo sobre backups usando **Restic**, para asegurar que no se pierdan datos en el homelab. Mis backups se ejecutan automáticamente mediante un script programado con Cron.

## Estrategia de Contenedores: Cómo Distribuyo los Servicios Docker en el Homelab

Para finalizar, aquí hay una pequeña lista de los contenedores Docker que actualmente funcionan en mi homelab:

- Traefik (2x)
- Frigate
- Meshtastic
- Komodo Core
- Komodo Periphery (4x)
- Searxng
- Twingate
- Mixpost
- Cloudflare Tunnel
- Gluetun
- Linkwarden
- PeaNUT
- Baikal
- IT-Tools
- Home Assistant
- Synapse
- Gotify
- Stirling PDF
- Glance
- Uptime Kuma
- Wordpress
- n8n
- Wiki.js
- Jellyfin

Todos estos contenedores funcionan 24/7, distribuidos en varios sistemas, por ejemplo:

- **Synology NAS:** Jellyfin (servidor de medios) – óptimo, ya que los medios están almacenados allí.
- **EQ14 Mini-PC con dos puertos LAN:** Frigate (NVR), proxy inverso Traefik separado – los puertos de red dedicados y la potencia de cálculo extra son ideales para procesamiento de vídeo asistido por IA.
- **Lenovo ThinkCentre M715q:** Todos los demás servicios de producción como Mixpost, Wiki.js, Searxng, Home Assistant, etc.
- **Cuarto host:** Se inicia solo cuando es necesario para pruebas temporales de contenedores o proyectos especiales.

Inicialmente, Frigate también se ejecutaba en el ThinkCentre, lo que funcionaba pero consumía más recursos. Al moverlo al EQ14, la carga del servidor principal se reduce significativamente. Puedes leer mi artículo sobre Frigate [aquí](/es/posts/frigate-open-source-nvr-real-time-ai-object-detection/).

Decidí no usar Docker Swarm de manera deliberada: con mi número manejable de hosts, la combinación de distribución de contenedores específica y un segundo proxy Traefik en el EQ14 es una solución más sencilla y robusta. Pero quién sabe qué traerá el futuro.

## Conclusión

Para mí, Docker Compose es mucho más que una simple herramienta: es la base de mi homelab. Con una organización clara, una red bien estructurada y un poco de automatización, puedo construir un entorno robusto, flexible y fácil de mantener, que facilita enormemente las operaciones diarias.

¿Usas **Docker** o **Docker Compose** en tu homelab? ¡Siéntete libre de compartir en los comentarios cómo organizas tus contenedores!

## Recomendaciones de Hardware

- EQ14 Mini-PC [en Amazon](https://amzn.to/4oBKKcg) - un equipo compacto y eficiente energéticamente para Docker
- Lenovo ThinkCentre M715q [en RAM-KÖNIG](https://www.ram-koenig.de/lenovo-thinkcentre-m715q-ryzen5pro2400ge-8gbddr4) - PC pequeño de segunda mano como servidor Docker

_Algunos de estos son enlaces de afiliados. Como asociado de Amazon, gano una comisión por compras que cumplan los requisitos._

**Herramientas utilizadas:**

- [Docker](https://www.docker.com/)
- [Traefik](https://traefik.io/traefik)
- [Komodo](https://komo.do/)

{{< chat Docker >}}
