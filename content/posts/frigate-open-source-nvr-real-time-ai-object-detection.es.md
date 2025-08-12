+++
title = 'Frigate: NVR Open Source con Detección de Objetos por IA en Tiempo Real'
summary = 'Frigate es un grabador de video en red (NVR) de código abierto que combina la videovigilancia tradicional con detección en tiempo real, impulsada por inteligencia artificial, de personas, vehículos, animales y otros objetos.'
date = 2025-08-12T18:35:10-03:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2025-08-12T18:35:10-03:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Linux', 'Frigate', 'AI', 'Coral', 'TPU', 'NVR', 'Docker', 'Videovigilancia']
categories = ['TechLab']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/frigate-open-source-nvr-real-time-ai-object-detection.webp'
    alt = 'Imagen destacada de Frigate: Open Source NVR with Real-Time AI Object Detection'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

**Frigate** es un Network Video Recorder (NVR) de código abierto, diseñado específicamente para la detección de objetos en tiempo real mediante inteligencia artificial. No solo ofrece grabación y reproducción de video tradicional, sino que también detecta automáticamente personas, vehículos, animales y otros objetos utilizando aprendizaje automático.

## Por qué Frigate se convirtió en la solución para mi sistema de videovigilancia

Antes de mudarme a Paraguay en 2019, trabajé en Alemania planificando e instalando sistemas de videovigilancia. Apliqué ese conocimiento también aquí: desde el principio, nuestra casa fue equipada con un sistema de vigilancia tradicional compuesto por varias cámaras de red y un grabador NVR con disco duro.

Sin embargo, hace un tiempo comencé a buscar una solución más flexible. Quería una plataforma central que me permitiera acceder fácilmente a mis cámaras IP. Fue entonces cuando descubrí **Frigate**, y rápidamente quedó claro: puede hacer mucho más que solo almacenar videos. Combinado con un **Coral TPU** para detección de objetos con IA, podría incluso reemplazar completamente mi NVR convencional.

## Primeras pruebas en mi servidor doméstico

La primera instalación de **Frigate** la realicé en mi servidor `sumpfgeist.lan` para evaluar qué tan bien funcionaba el sistema en el uso diario. El plan original era usar un **M.2 Dual Coral**, siempre que funcionara en la ranura M.2 para Wi-Fi de mi Lenovo ThinkCentre. De todas formas no necesito Wi-Fi, y la ranura estaba disponible.

Sin embargo, en la práctica resultó que la mayoría de las ranuras M.2 para Wi-Fi no soportan Corals de doble chip. Estas ranuras suelen estar diseñadas exclusivamente para módulos Wi-Fi y no proporcionan una línea PCIe utilizable. Si tienes suerte, hay una línea PCIe disponible, lo que permite instalar un Coral TPU en lugar del módulo Wi-Fi.

Este fue el caso del ThinkCentre, donde pude usar sin problema un Coral de un solo chip en la ranura M.2 para Wi-Fi. En el **EQ14** (`eq14.lan`), sin embargo, la ranura solo soporta Wi-Fi, por lo que el Coral TPU no fue detectado.

El **EQ14** sí tiene dos ranuras M.2 de tamaño completo para discos NVMe. Como solo tenía instalada una SSD NVMe, la segunda ranura estaba libre — lo que me permitió instalar y usar un chip Coral TPU de un solo módulo mediante una placa adaptadora.

## Configuración de cámaras y migración al EQ14

Actualmente, tengo cinco cámaras IP distribuidas por nuestra propiedad, todas ellas integradas sin problemas en **Frigate**. Es probable que en el futuro se añadan más.

Después de que las pruebas iniciales fueran satisfactorias, migré la instalación de Frigate de `sumpfgeist.lan` a `eq14.lan`. Gracias a **Docker Compose**, la mudanza fue casi sin inconvenientes — solo fue necesario un pequeño ajuste en el archivo `.env`: cambiar el soporte de GPU de AMD a Intel, lo que implicó simplemente eliminar una variable de entorno.

Para que el chip Coral funcione en **Alpine Linux** con el **EQ14**, ya he implementado y documentado todos los pasos necesarios. Detallaré estos procedimientos en mi próximo artículo del blog.

Dado que el proxy Traefik existente se ejecuta en otro host Docker y no puede gestionar automáticamente la configuración de dominios de hosts externos, configuré un segundo proxy Traefik en el **EQ14**. A través de este, **Frigate** ahora es accesible en la red interna. Para la subdominio, solo tuve que actualizar la dirección IP en el servidor DNS Pi-hole.

Con el hardware principal y la configuración de red ya completos, el siguiente paso será instalar **Frigate** usando **Docker Compose** — desde la preparación inicial hasta la primera configuración funcional.

## Instalación de Frigate

Para ejecutar Frigate, decidí usar Docker Compose — no solo porque soy un gran fan de [Docker](https://www.docker.com/) y ejecuto múltiples contenedores en diferentes hosts en mi homelab. El tema es lo suficientemente amplio como para dedicarle probablemente un artículo de blog independiente en algún momento.

Docker Compose tiene la ventaja de que las configuraciones son fáciles de ajustar, respaldar y migrar a otros sistemas cuando es necesario. La [documentación oficial de Frigate](https://docs.frigate.video/configuration/reference) también ofrece una base sólida, que adapté a mis requisitos — especialmente la integración de múltiples cámaras IP.

Mi archivo actual `docker-compose.yaml` se ve así:

```yaml
services:
  frigate:
    container_name: frigate
    restart: unless-stopped
    image: ghcr.io/blakeblackshear/frigate:stable
    devices:
      #- /dev/bus/usb:/dev/bus/usb # USB Coral
      - /dev/apex_0:/dev/apex_0 # M.2 Coral
      #- /dev/apex_1:/dev/apex_1 # M.2 Dual Coral
      - /dev/dri/renderD128:/dev/dri/renderD128 # for intel hwaccel, needs to be updated for your hardware
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /home/sz/docker/frigate/config.yml:/config/config.yml:ro
      - /mnt/frigate/clips:/media/frigate/clips
      - /mnt/frigate/recordings:/media/frigate/recordings
      - /home/sz/docker/frigate/db-data:/media/frigate
      - type: tmpfs # Optional 1GB memory to reduce SSD/SD card wear
        target: /tmp/cache
        tmpfs:
          size: 1000000000
    networks:
      proxy:
        ipv4_address: 192.168.x.x
    ports:
      - "5000:5000" # Frigate Webinterface
      #- "1935:1935" # RTMP feeds (deprecated) ???
      - "1984:1984" # go2rtc
      - "8554:8554" # go2rtc
    env_file: .env
    security_opt:
      - no-new-privileges:true
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frigate.entrypoints=http"
      - "traefik.http.routers.frigate.rule=Host(`frigate.techlab.icu`)"
      - "traefik.http.middlewares.frigate-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.routers.frigate.middlewares=frigate-https-redirect"
      - "traefik.http.routers.frigate-secure.entrypoints=https"
      - "traefik.http.routers.frigate-secure.rule=Host(`frigate.techlab.icu`)"
      - "traefik.http.routers.frigate-secure.tls=true"
      - "traefik.http.routers.frigate-secure.service=frigate"
      - "traefik.http.services.frigate.loadbalancer.server.port=5000"
      - "traefik.docker.network=proxy"

networks:
  proxy:
    external: true
```

Para almacenar las grabaciones y clips de video, he montado un recurso compartido en red desde mi **Synology NAS** y lo he referenciado en la configuración Docker de Frigate usando los directorios `/mnt/frigate/clips` y `/mnt/frigate/recordings`.

El archivo `config.yml` actual se ve así:

```yaml
detectors:
  coral1:
    type: edgetpu
    device: pci:0
#  coral2:
#    type: edgetpu
#    device: pci:1

# Optional: Database configuration
database:
  # The path to store the SQLite DB (default: shown below)
  path: /media/frigate/frigate.db

auth:
  enabled: True

birdseye:
  # Optional: Enable birdseye view (default: shown below)
  enabled: True
  # Optional: Width of the output resolution (default: shown below)
  width: 1280
  # Optional: Height of the output resolution (default: shown below)
  height: 720
  # Optional: Encoding quality of the mpeg1 feed (default: shown below)
  # 1 is the highest quality, and 31 is the lowest. Lower quality feeds utilize less CPU resources.
  quality: 8
  # Optional: Mode of the view. Available options are: objects, motion, and continuous
  #   objects - cameras are included if they have had a tracked object within the last 30 seconds
  #   motion - cameras are included if motion was detected in the last 30 seconds
  #   continuous - all cameras are included always
  mode: continuous

ffmpeg:
  hwaccel_args: #preset-vaapi
    - -hwaccel
    - vaapi
    - -hwaccel_device
    - /dev/dri/renderD128
    - -hwaccel_output_format
    - yuv420p
  output_args:
    record: -f segment -segment_time 10 -segment_format mp4 -reset_timestamps 1 -strftime 1 -c:v copy -c:a aac

detect:
  enabled: True
  width: 640 # <---- update for your camera's resolution
  height: 480 # <---- update for your camera's resolution
  fps: 5

objects:
  track:
    - person
    - dog
    - cat
    - bird

record:
  enabled: True
  detections:
    pre_capture: 5
    post_capture: 5
    retain:
      days: 30
      mode: active_objects

snapshots:
  enabled: True
  timestamp: False
  bounding_box: True
  retain:
    default: 30

go2rtc:
  streams:
    carport:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
    carport_sub:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
    garden:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
    garden_sub:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
    office:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
    office_sub:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
    workshop:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
    workshop_sub:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1

cameras:
  carport:
    ffmpeg:
      inputs:
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
          roles:
            - record
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
          roles:
            - detect
    webui_url: "http://192.168.x.x"
    detect:
      width: 704 # <---- update for your camera's resolution
      height: 480 # <---- update for your camera's resolution
      fps: 5
  garden:
    ffmpeg:
      inputs:
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
          roles:
            - record
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
          roles:
            - detect
    webui_url: "http://192.168.x.x"
    detect:
      width: 704 # <---- update for your camera's resolution
      height: 480 # <---- update for your camera's resolution
      fps: 5
  office:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/office
          roles:
            - audio
            - record
        - path: rtsp://127.0.0.1:8554/office_sub
          roles:
            - detect
    webui_url: "http://192.168.x.x"
    onvif:
      host: 192.168.x.x
      port: 80
      user: frigate
      password: "{FRIGATE_RTSP_PASSWORD}"
  workshop:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/workshop
          roles:
            - audio
            - record
        - path: rtsp://127.0.0.1:8554/workshop_sub
          roles:
            - detect
    webui_url: http://192.168.x.x
    onvif:
      host: 192.168.x.x
      port: 80
      user: frigate
      password: "{FRIGATE_RTSP_PASSWORD}"
```

En esta configuración de Frigate, he incluido direcciones IP de ejemplo — es imprescindible que las ajustes para que coincidan con tu propia red doméstica.

Una gran ventaja de mi configuración con el EQ14 es que cuenta con dos interfaces de red separadas. Esto me permite tener las cámaras IP en una red aislada, añadiendo una capa extra de seguridad. Solo la segunda interfaz de red del EQ14 está conectada a mi homelab. De esta forma, los dispositivos de las cámaras están físicamente separados del resto de la red, minimizando las posibles superficies de ataque.

## Integración de los streams de las cámaras con go2rtc

Para integrar los streams RTSP de mis cámaras IP en Frigate de la manera más flexible y eficiente posible, utilizo **go2rtc**.

**Por qué go2rtc?**

[go2rtc](https://docs.frigate.video/guides/configuring_go2rtc/) es un servidor moderno de retransmisión de streams que puede agregar, transcodificar y reenviar streams RTSP, RTMP y WebRTC. Es especialmente útil porque asegura la compatibilidad con diversos clientes, reduce la latencia y descarga trabajo de las cámaras.

Además, go2rtc permite usar streams con diferentes protocolos (RTSP, WebRTC) de forma fluida dentro del homelab y más allá. Esto es especialmente valioso para configuraciones más complejas con múltiples cámaras y clientes. El servicio go2rtc ya está ejecutándose dentro del contenedor de Frigate.

## Enlaces RTSP para cámaras OEM Dahua

Para encontrar los enlaces RTSP correctos para mis cámaras IP OEM Dahua, utilicé [esta útil página web](https://dahuawiki.com/Remote_Access/RTSP_via_VLC), que documenta muchos formatos comunes de URL. Estos enlaces pueden abrirse y reproducirse fácilmente con [VLC](https://www.videolan.org/) u otros reproductores multimedia.

Ejemplo para mi cámara de oficina:

```bash
rtsp://192.168.x.x:554/live
rtsp://192.168.x.x:554/cam/realmonitor?channel=1&subtype=0&unicast=true&proto=Onvif
rtsp://192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
```

## Configuración actual y hardware

Recientemente compré un Coral M.2 A+E TPU en eBay.com y lo instalé en mi servidor. La detección de objetos con IA usando el chip Coral es mucho más eficiente que con la CPU, que de otro modo funciona a plena carga y no se recomienda para esta tarea. Enlazaré mi artículo del blog sobre el chip Coral TPU [aquí](/posts/coral-edge-tpu-hardware-acceleration-for-ai-object-detection/) cuando esté disponible.

Ya he integrado la GPU para aceleración por hardware con [ffmpeg](https://ffmpeg.org/) y el sistema funciona de manera estable actualmente con cuatro cámaras. Pronto agregaré una quinta cámara y, a largo plazo, planeo manejar hasta ocho cámaras. Esta configuración de hardware debería poder soportarlo sin problemas.

## Variable de entorno importante para soporte GPU

Para que Frigate detecte la GPU AMD en mi ThinkCentre (`sumpfgeist.lan`), tuve que configurar la siguiente variable de entorno en mi archivo `.env`:

```bash
FRIGATE_RTSP_USER=frigate
FRIGATE_RTSP_PASSWORD=secure_password
LIBVA_DRIVER_NAME=radeonsi
```

Tras migrar al **EQ14** (`eq14.lan`), que usa GPU Intel, eliminé la variable `LIBVA_DRIVER_NAME` porque los controladores AMD no son necesarios allí y causaban errores.

```bash
FRIGATE_RTSP_USER=frigate
FRIGATE_RTSP_PASSWORD=secure_password
```

## Calidad de grabación y gestión de streams

Las grabaciones deben ser de la mejor calidad posible. Para ello, tuve que ajustar algunas configuraciones y, como mencioné antes, usar **go2rtc** para manejar mejor los streams. Desde el cambio, **go2rtc** funciona muy bien.

Actualmente, Frigate es accesible a través de mi servidor proxy Traefik en: https://frigate.techlab.icu

## Configuración del servidor de streaming go2rtc

Para una reproducción de video optimizada y transmisión en tiempo real, se recomienda usar el **servidor integrado go2rtc**.

La configuración es bastante sencilla: solo hay que ampliar el archivo `config.yml` con los streams que **go2rtc** debe gestionar.

```yaml
go2rtc:
  streams:
    office:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
    office_sub:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
```

Estos streams se pueden acceder y supervisar a través de la **interfaz web de go2rtc** en `http://192.168.x.x:1984`.

Para usar los streams en la vista en vivo y en las grabaciones de alta calidad con Frigate, las cámaras deben configurarse en el `config.yml` usando las rutas de **stream de go2rtc**:

```yaml
cameras:
  office:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/office
          roles:
            - audio
            - record
        - path: rtsp://127.0.0.1:8554/office_sub
          roles:
            - detect
```

### Solución de problemas

En mi cámara interior del taller, el stream inicialmente no se iniciaba a través de **go2rtc**, mientras que el modelo idéntico en la oficina funcionaba perfectamente.

Comprobé y comparé la configuración de video y audio de las cámaras. El problema resultó ser el códec de audio: tuve que cambiar de **AAC** a **G.711A**. Después de eso, el stream comenzó a funcionar correctamente en Frigate vía go2rtc, y ahora tanto el video como el audio funcionan sin problemas.

## Detección de objetos

La detección de objetos en Frigate se basa en reconocimiento impulsado por IA. Para la aceleración por hardware, uso un chip Coral Edge TPU con 4 TOPS (operaciones tera por segundo). Cómo instalar este chip y sus controladores ya está descrito [aquí](/posts/coral-edge-tpu-hardware-acceleration-for-ai-object-detection/).

![Image Frigate Object Detection Coral Edge TPU](/img/galleries/frigate-open-source-nvr-real-time-ai-object-detection/frigate-object-detection-coral-edge-tpu.webp)

### Ajuste de Docker Compose

Para usar el Coral Edge TPU dentro del contenedor Docker, modifico el archivo `docker-compose.yaml` en mi directorio `~/docker-compose/frigate/` de la siguiente manera, para que el dispositivo se pase al contenedor:

```yaml
devices:
  #- /dev/bus/usb:/dev/bus/usb # USB Coral
  - /dev/apex_0:/dev/apex_0 # M.2 Coral
  #- /dev/apex_1:/dev/apex_1   # M.2 Dual Coral (optional)
```

### Activación de la configuración de Frigate

En el archivo `config.yml` ubicado en mi carpeta `~/docker/frigate/`, activo los detectores añadiendo esta sección:

```yaml
detectors:
  coral1:
    type: edgetpu
    device: pci:0
```

### Configuración de la detección de objetos

La detección de objetos se habilita y configura en la sección `detect`:

```yaml
detect:
  enabled: True
  width: 640 # <---- update for your camera's resolution
  height: 480 # <---- update for your camera's resolution
  fps: 5
```

**Nota:** Los parámetros `width`, `height` y `fps` normalmente se sobrescriben en la configuración individual de cada cámara bajo `cámaras:` y se ajustan a cada dispositivo. Para la detección, es suficiente una resolución y tasa de fotogramas más bajas para ahorrar recursos.

### Reinicio

Después de realizar estos cambios, puedes reiniciar el contenedor Docker o, si solo cambiaste la configuración, simplemente reiniciar Frigate desde la interfaz web.

## Conclusión

La combinación de **Frigate**, **Coral Edge TPU** y el **EQ14** se ha convertido ahora en el núcleo de mi sistema de videovigilancia. Gracias a la alta precisión de detección y al rendimiento estable, ahora cuento con una solución fiable y preparada para el futuro.

Como siguiente paso, planeo afinar aún más la detección, integrar automatizaciones adicionales mediante **Home Assistant** y hacer que mi sistema sea cada vez más inteligente de forma gradual.

## Recomendaciones de hardware

- EQ14 Mini-PC [en Amazon](https://amzn.to/4oBKKcg) - equipo compacto y eficiente en consumo energético para Frigate
- Coral Edge TPU [en Amazon US](https://a.co/d/0aeVsKY) - acelerador de IA para detección rápida y precisa de objetos
- Coral Dual Edge TPU [en Amazon](https://amzn.to/3Hxq83Y) - potente acelerador de IA (no cabe en el EQ14)

_Algunos de los enlaces anteriores son enlaces de afiliados. Como asociado de Amazon, recibo una comisión por compras que califican._

**Herramientas utilizadas:**

- [Frigate](https://frigate.video/)
- [Docker](https://www.docker.com/)
- [Traefik](https://traefik.io/traefik)
- [Pi-Hole](https://pi-hole.net/)
- [Coral Edge TPU](https://coral.ai/products/)

{{< chat Frigate >}}
