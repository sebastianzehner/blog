+++
title = 'NUT en el Homelab: Control centralizado y monitoreo de sistemas UPS'
summary = 'En mi homelab utilizo varias unidades de alimentación ininterrumpida (SAI), incluyendo modelos de **Eaton** y **CyberPower**. Estas protegen de forma fiable mis servidores, sistemas NAS y dispositivos de red durante un apagón.'
date = 2025-08-06T20:35:10-03:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2025-08-06T20:35:10-03:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Linux', 'SAI', 'NUT', 'Docker', 'Apagón']
categories = ['TechLab']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/nut-in-the-homelab-central-ups-monitoring-and-automation.webp'
    alt = 'Imagen destacada de NUT en el Homelab: Control centralizado y monitoreo de sistemas UPS'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

## Cómo automatizo mi homelab en caso de un corte de energía?

En mi homelab utilizo varias unidades de alimentación ininterrumpida (SAI), incluyendo modelos de **Eaton** y **CyberPower**. Estas protegen de forma fiable mis servidores, sistemas NAS y dispositivos de red durante un apagón. Hasta ahora, cada SAI funcionaba más o menos de forma aislada, sin supervisión central ni apagado automático de los equipos.

Ahora quiero cambiar eso: con la ayuda de **Network UPS Tools (NUT)**, mi infraestructura debería volverse más inteligente y segura. [NUT](https://networkupstools.org/) es un proyecto de código abierto que admite una amplia variedad de dispositivos de alimentación, como SAIs, unidades de distribución de energía (PDU), controladores solares y fuentes de alimentación. Proporciona una plataforma central para la supervisión, el control y la automatización, tanto localmente como a través de la red.

**Mi objetivo:**

- Supervisión central de todos los dispositivos SAI
- Apagado automático de los servidores en caso de corte de energía
- Integración en **Home Assistant** para conectarlo con mi sistema domótico
- Visualización opcional con herramientas como **Uptime Kuma**
- Interfaz web con **PeaNUT** mediante Docker

En el siguiente artículo documento paso a paso cómo instalé, configuré y amplié **NUT** en mi homelab.

## Instalar NUT

En mi homelab utilizo varias SAIs, entre ellas una **SAI de Eaton** conectada por **USB** a una **Raspberry Pi 3B**. En esta Pi se ejecuta **Ubuntu Server** (un sistema basado en Debian), y su función es actuar como un **servidor NUT local – exclusivamente para esta SAI**.

Porque **cada SAI en mi infraestructura tendrá su propio servidor NUT**, ubicado en un dispositivo conectado físicamente a esa unidad. Los dispositivos que estén alimentados por esa SAI se conectarán más adelante a su servidor NUT correspondiente para consultar su estado o apagarse automáticamente en caso de corte de energía.

**Paso 1: Conectarse al servidor por SSH**

```bash
ssh user@pi-server.lan
```

**Paso 2: Actualizar el sistema**

```bash
sudo apt update && sudo apt upgrade
```

**Paso 3: Instalar NUT**

La instalación de Network UPS Tools (NUT), incluyendo el servidor, cliente y herramientas de diagnóstico, se realiza con:

```bash
sudo apt install nut
```

## Configurar NUT

Después de instalar NUT correctamente, queremos detectar la SAI conectada y configurarla adecuadamente. Para ello usamos la herramienta `nut-scanner`, que detecta automáticamente los dispositivos disponibles. Sin embargo, en Ubuntu Server pueden aparecer algunos inconvenientes.

**Paso 1: Ejecutar `nut-scanner`**

```bash
sudo nut-scanner -U
```

En mis sistemas, esto muestra primero varias advertencias:

```bash
Cannot load USB library (libusb-1.0.so) : file not found. USB search disabled.
Cannot load SNMP library (libnetsnmp.so) : file not found. SNMP search disabled.
Cannot load XML library (libneon.so) : file not found. XML search disabled.
Cannot load AVAHI library (libavahi-client.so) : file not found. AVAHI search disabled.
Cannot load IPMI library (libfreeipmi.so) : file not found. IPMI search disabled.
Cannot load NUT library (libupsclient.so) : file not found. NUT search disabled.
```

Estos mensajes indican que ciertas bibliotecas no se han encontrado o no se pueden cargar correctamente. **La buena noticia:** para la detección por USB normalmente basta con crear enlaces simbólicos hacia las bibliotecas faltantes. [Aquí](https://github.com/networkupstools/nut/issues/2431) hay una discusión en GitHub que trata este tema.

**Paso 2: Hacer disponibles las bibliotecas mediante enlaces simbólicos**

Para `pi-server.lan` (Raspberry Pi, ARM64)

```bash
cd /usr/lib/aarch64-linux-gnu/
sudo ln -s libusb-1.0.so.0 libusb-1.0.so
sudo ln -s libavahi-client.so.3 libavahi-client.so
```

Für `sumpfgeist.lan` (x86_64-Server)

```bash
cd /usr/lib/x86_64-linux-gnu/
sudo ln -s libusb-1.0.so.0 libusb-1.0.so
sudo ln -s libavahi-client.so.3 libavahi-client.so
```

> **Nota:** No fue posible crear otros enlaces como `libnetsnmp.so`, `libfreeipmi.so` y `libneon.so`, ya que los archivos correspondientes no estaban presentes en mis sistemas. Sin embargo, no son necesarios para el funcionamiento básico con USB.

**Paso 3: Resultados de `nut-scanner`**

**`pi-server.lan` (Eaton Ellipse 650 PRO)**

```bash
Scanning USB bus.
[nutdev1]
        driver = "usbhid-ups"
        port = "auto"
        vendorid = "0463"
        productid = "FFFF"
        product = "Ellipse PRO"
        serial = "G355M3xxxx"
        vendor = "EATON"
        bus = "001"
        device = "004"
        busport = "005"
        ###NOTMATCHED-YET###bcdDevice = "0100"
```

**`sumpfgeist.lan` (CyberPower CP1600EPFCLCD)**

```bash
Scanning USB bus.
[nutdev1]
        driver = "usbhid-ups"
        port = "auto"
        vendorid = "0764"
        productid = "0601"
        product = "CP1600EPFCLCD"
        serial = "BHYNZ200xxxx"
        vendor = "CPS"
        bus = "003"
        device = "003"
        busport = "001"
        ###NOTMATCHED-YET###bcdDevice = "0200"
```

Ambas SAIs – **Eaton Ellipse 650 PRO** y **CyberPower CP1600EPFCLCD** – fueron detectadas correctamente. Ahora podemos pasar a la configuración real en el archivo `ups.conf`.

**Paso 4: Registrar la SAI en `/etc/nut/ups.conf`**

`pi-server.lan`

```bash
[server-room-rack]
    driver = "usbhid-ups"
    product = "Ellipse PRO"
    desc = "Server Room Rack UPS"
    port = "auto"
    vendorid = "0463"
    productid = "FFFF"
    bus = "001"
```

`sumpfgeist.lan`

```bash
[ups]
    driver = "usbhid-ups"
    product = "CP1600EPFCLCD"
    desc = "HomeLab UPS"
    port = "auto"
    vendorid = "0764"
    productid = "0601"
    bus = "003"
```

Edita este archivo con:

```bash
sudo nano /etc/nut/ups.conf
```

## Configurar el servidor NUT

Después de definir los SAI conectados en `ups.conf`, el siguiente paso es preparar el servidor NUT para el funcionamiento en red. Para ello, modificamos varios archivos de configuración, creamos usuarios y activamos el modo servidor.

**Paso 1. `upsd.conf`: Habilitar el acceso de red**

```bash
sudo nano /etc/nut/upsd.conf
```

Añadimos la siguiente línea para permitir conexiones entrantes desde todas las interfaces en el puerto 3493:

```bash
LISTEN 0.0.0.0 3493
```

Alternativamente, puedes especificar la dirección IP del host si deseas restringir el acceso.

**Paso 2. `upsd.users`: Crear usuarios para los servicios de NUT**

En este archivo definimos usuarios con diferentes niveles de permisos. Estos se usarán más adelante, por ejemplo, por `upsmon` o por una interfaz web.

```bash
sudo nano /etc/nut/upsd.users
```

`pi-server.lan`

```bash
[admin]
    password = secure_password
    actions = SET
    actions = FSD
    instcmds = ALL
    upsmon primary

[monuser]
    password = secure_password
    upsmon secondary
```

`sumpfgeist.lan`

```bash
[admin]
    password = secure_password
    actions = SET
    actions = FSD
    instcmds = ALL
    upsmon primary

[monuser]
    password = secret
    upsmon secondary
```

> **Nota:** Las contraseñas utilizadas en estos ejemplos son solo ilustrativas. Asegúrate de utilizar contraseñas seguras y personales, y considera almacenarlas en un gestor de contraseñas.

**Paso 3. `upsmon.conf`: Configurar el monitor de SAI**

El monitor de SAI (`upsmon`) es el encargado de supervisar el suministro eléctrico y, por ejemplo, ejecutar un apagado automático en caso de corte de energía. Edita la configuración con:

```bash
sudo nano /etc/nut/upsmon.conf
```

`pi-server.lan`

```bash
MONITOR server-room-rack@localhost 1 admin secure_password primary
```

`sumpfgeist.lan`

```bash
MONITOR ups@localhost 1 admin secret primary
```

> **La sintaxis es:** `MONITOR <USV-Name>@<Host> <Power-Value> <Benutzer> <Passwort> <primary|secondary>`

**Paso 4. `nut.conf`: Activar el modo de operación**

Por último, definimos en qué modo debe funcionar NUT:

```bash
sudo nano /etc/nut/nut.conf
```

Cambia la línea:

```bash
MODE=none
```

por:

```bash
MODE=netserver
```

Con esto, el servidor NUT está listo para operar en red, y podrá proporcionar datos de estado y responder a solicitudes de clientes.

## Reiniciar los servicios de NUT

Después de configurar el sistema, reiniciamos los servicios de NUT y nos aseguramos de que se inicien automáticamente al arrancar el sistema.

**Para sistemas basados en Debian/Ubuntu**

```bash
sudo systemctl restart nut-server
sudo systemctl enable nut-server

sudo systemctl restart nut-monitor
sudo systemctl enable nut-monitor
```

Esto garantiza que tanto el servidor NUT (`nut-server`) como el servicio de monitoreo (`nut-monitor`) se inicien automáticamente después del arranque.

**Para Alpine Linux**

En Alpine Linux, los servicios se gestionan con **OpenRC**. Para una configuración completa del servidor, es necesario iniciar y habilitar tanto `nut-upsd` como `nut-upsmon`:

```bash
doas rc-service nut-upsd restart
doas rc-update add nut-upsd default

doas rc-service nut-upsmon restart
doas rc-update add nut-upsmon default
```

Con esto, el servidor NUT en Alpine Linux estará completamente operativo y se iniciará automáticamente tras un reinicio.

## Comprobar el funcionamiento de NUT y resolver errores

Una vez que el servidor NUT esté correctamente configurado y en funcionamiento, se puede probar la comunicación con la UPS utilizando el comando `upsc`:

**Mostrar datos de la UPS**

```bash
upsc <UPS-NAME>
```

Ejemplo en `pi-server.lan`:

```bash
upsc server-room-rack
```

Beispiel auf `sumpfgeist.lan`:

```bash
upsc ups
```

**Errores tras la configuración**

Si al ejecutar por primera vez aparece el siguiente error: `Error: Driver not connected`, puede deberse a una conexión USB defectuosa. En un caso bastó con desconectar brevemente el cable USB y volver a conectarlo. Luego, la UPS fue detectada correctamente y apareció una salida de estado extensa como esta:

**Eaton Ellipse 650 PRO**

```bash
Init SSL without certificate database
battery.charge: 100
battery.charge.low: 20
battery.runtime: 1734
battery.type: PbAc
device.mfr: EATON
device.model: Ellipse PRO 650
...
```

**CyberPower CP 1600EPFCLCD**

```bash
Init SSL without certificate database
battery.charge: 100
battery.charge.low: 10
battery.charge.warning: 20
battery.mfr.date: CPS
battery.runtime: 3750
battery.runtime.low: 300
battery.type: PbAcid
battery.voltage: 27.4
battery.voltage.nominal: 24
device.mfr: CPS
device.model: CP1600EPFCLCD
...
```

**Error recurrente tras reinicio**

En otro caso, el mismo error apareció nuevamente tras un reinicio, pero no se pudo solucionar desconectando y reconectando el cable USB.

El análisis con `nut-scanner` aclaró el problema:

```bash
sudo nut-scanner -U
```

La salida mostró que el bus USB y el dispositivo habían cambiado:

**Durante la instalación**

```bash
bus = "003"
device = "003"
```

**Y ahora**

```bash
bus = "004"
device = "006"
```

Esto provocó que el controlador no pudiera encontrar la UPS. **Solución:** Se modificó el archivo `/etc/nut/ups.conf` para ingresar manualmente el nuevo bus:

```bash
sudo nano /etc/nut/ups.conf
```

Aquí se cambia `bus = "003"` a `bus = "004"` y se guarda el archivo. Ahora la UPS vuelve a estar accesible, lo que se puede verificar con `upsc ups`.

También aparece nuevamente como **online** en https://usv.techlab.icu

Estos errores no deben pasar desapercibidos — especialmente durante un corte eléctrico. Se recomienda encarecidamente implementar una supervisión automatizada que cubra los siguientes puntos:

- Verificación del estado de las UPS
- Notificaciones en caso de errores de conexión

La siguiente sección del artículo explicará cómo implementar estos mecanismos.

## Supervisión del estado con Uptime Kuma

Superviso el estado de mis dispositivos UPS utilizando **Uptime Kuma**, consultando la API JSON de **PeaNUT**. Para cada UPS existen dos monitores que realizan solicitudes HTTPS a los siguientes endpoints:

- https://usv.techlab.icu/api/v1/devices/ups
- https://usv.techlab.icu/api/v1/devices/server-room-rack

Para cada uno utilizo dos criterios de búsqueda:

1. Esta clave `"ups.status":"OL"` indica que la UPS está en línea y actualmente funciona con energía eléctrica de red.
2. Si se detecta el texto `Device Unreachable`, significa que la UPS ya no es accesible.

Esto puede deberse, por ejemplo, a una pérdida de conexión o a un fallo del servicio NUT. La alimentación eléctrica aún podría estar activa, pero no necesariamente.

Para una mejor visión general, he agrupado ambas comprobaciones por UPS en un mismo grupo:

- `UPS [server-room-rack]`
- `UPS [usv]`

De este modo, puedo ver de inmediato si una UPS está **fuera de línea**, si ha habido un **corte de energía**, o ambos. Las notificaciones son enviadas por **Uptime Kuma** a través de **Gotify**. Ambos servicios se ejecutan en mi sistema dentro de contenedores Docker. Más adelante, puedo escribir otro artículo en el blog sobre este tema si hay interés.

## Implementar PeaNUT con Docker

[PeaNUT](https://github.com/Brandawg93/PeaNUT) es un panel web ligero para Network UPS Tools (NUT), ideal para visualizar el estado de los sistemas UPS. La aplicación se puede implementar fácilmente con Docker.

![Image PeaNUT Dashboard](/img/galleries/nut-in-the-homelab-central-ups-monitoring-and-automation/peanut-dashboard.webp)

A continuación, se muestra mi archivo `docker-compose.yaml` para instalar PeaNUT:

```yaml
services:
  peanut:
    image: brandawg93/peanut:latest
    container_name: PeaNUT
    restart: unless-stopped
    volumes:
      - /home/sz/docker/peanut/config:/config
    networks:
      peanut:
      proxy:
        ipv4_address: 192.168.x.x
    ports:
      - 8080:8080
    environment:
      - WEB_PORT=8080
      #- WEB_USERNAME="admin"
      #- WEB_PASSWORD="admin1234"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.peanut.entrypoints=http"
      - "traefik.http.routers.peanut.rule=Host(`usv.techlab.icu`)"
      - "traefik.http.middlewares.peanut-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.routers.peanut.middlewares=peanut-https-redirect"
      - "traefik.http.routers.peanut-secure.entrypoints=https"
      - "traefik.http.routers.peanut-secure.rule=Host(`usv.techlab.icu`)"
      - "traefik.http.routers.peanut-secure.tls=true"
      - "traefik.http.routers.peanut-secure.service=peanut"
      - "traefik.http.services.peanut.loadbalancer.server.port=8080"
      - "traefik.docker.network=proxy"

networks:
  peanut:
  proxy:
    external: true
```

La interfaz web estará disponible en https://usv.techlab.icu – protegida con TLS a través de Traefik.

En el archivo `settings.yml` dentro del directorio de configuración se definen los servidores NUT. En mi caso, la configuración se ve así:

```yaml
NUT_SERVERS:
  - HOST: 192.168.x.x
    PORT: 3493
    USERNAME: admin
    PASSWORD: secure_password
  - HOST: 172.19.x.x
    PORT: 3493
    USERNAME: admin
    PASSWORD: secret

INFLUX_HOST: ""
INFLUX_TOKEN: ""
INFLUX_ORG: ""
INFLUX_BUCKET: ""
INFLUX_INTERVAL: 10
```

## Gestión del SAI conectado

Además de la supervisión del estado, los sistemas SAI (UPS) también pueden gestionarse directamente desde la línea de comandos. Para ello, Network UPS Tools (NUT) proporciona la herramienta `upscmd`.

Por ejemplo, el siguiente comando muestra una lista de todas las órdenes disponibles para el SAI llamado `server-room-rack`:

```bash
upscmd -l server-room-rack
```

**Ejemplo: controlar el zumbador (beeper)**

Un caso de uso común es desactivar o volver a activar la alarma acústica del SAI. Esto se realiza con nombre de usuario y contraseña:

```bash
# Beeper deaktivieren
upscmd -u admin server-room-rack beeper.disable

# Beeper wieder aktivieren
upscmd -u admin server-room-rack beeper.enable
```

Tras introducir la contraseña, el comando se confirma con `OK`. El SAI acepta estas órdenes directamente a través del protocolo NUT.

**Otros comandos útiles**

A continuación, una selección de comandos útiles que pueden estar disponibles según el modelo del SAI:

| Comando          | Descripción                                                                |
| ---------------- | -------------------------------------------------------------------------- |
| load.off         | Apagar la carga inmediatamente                                             |
| load.off.delay   | Apagar la carga con retardo                                                |
| load.on          | Encender la carga inmediatamente                                           |
| load.on.delay    | Encender la carga con retardo                                              |
| shutdown.return  | Apagar la carga y volver a encenderla automáticamente cuando vuelva la red |
| shutdown.stayoff | Apagar la carga y mantenerla apagada                                       |
| shutdown.stop    | Cancelar un apagado en curso                                               |

> **Nota:** No todos los modelos de SAI admiten todos los comandos. La lista exacta depende del dispositivo y se puede consultar con `upscmd -l <nombre-del-sai>`.

## Añadir más clientes NUT

En un homelab típico, a menudo hay varios sistemas conectados a diferentes SAI (UPS). Con Network UPS Tools (NUT) no solo se puede controlar la máquina conectada directamente, sino también todos los demás sistemas de la red que reciben energía del mismo SAI.

Para ello se configuran los llamados **clientes NUT**. Estos se conectan al **servidor NUT** central, que está conectado al SAI mediante un cable USB, y reciben una señal de apagado en caso de un corte de energía.

**Resumen de la arquitectura**

- Sistemas en el mismo SAI → Clientes NUT que se conectan al servidor NUT
- Sistemas con su propio SAI → Su propio servidor y cliente NUT

**Ejemplo de asignación**

**Clientes NUT:**

- `sumpfkrieger.lan` → Cliente de `sumpfgeist.lan`
- `sumpfgeist.lan` → Client von `sumpfgeist.lan`
- `nas.techlab.icu` → Client von `sumpfgeist.lan`
- `eq14.lan` → Client von `sumpfgeist.lan`
- `pi-server.lan` → Client von `pi-server.lan`

**Servidores NUT:**

- `sumpfgeist.lan` → Servidor para la CyberPower CP 1600EPFCLCD
- `pi-server.lan` → Server für die Eaton Ellipse 650 PRO

### Configurar un NAS Synology como cliente NUT

La DiskStation de Synology se puede configurar como cliente de SAI en red. Las opciones se encuentran en:

**Panel de control > Hardware y energía > SAI**

**Ajustes:**

- Activar soporte para SAI
- Tipo de SAI: Servidor SAI Synology
- Tiempo antes de apagarse: p. ej., 3 minutos
- Servidor SAI en red: `192.168.x.x` (IP del servidor NUT)

**Requisitos en el servidor NUT:**

Para que la DiskStation pueda conectarse, el servidor debe estar configurado de la siguiente manera:

- El SAI debe llamarse `ups`
- Usuario: `monuser`
- Contraseña: `secret`
- `monuser` debe estar registrado con la opción `secondary`

Tras hacer clic en **Aplicar**, se establecerá la conexión con el SAI. En caso de un corte de energía, la DiskStation se apagará de forma segura después del tiempo configurado: se detendrán todos los servicios, se desmontarán los volúmenes y la alimentación se cortará a tiempo gracias a la batería del SAI.

### Configurar otros servidores como clientes NUT

Instalación en Ubuntu:

```bash
sudo apt install nut-client
```

y verificar la conexión con el servidor NUT usando:

```bash
upsc server-room-rack@192.168.x.x
upsc ups@192.168.x.x
```

En Alpine Linux:

```bash
# Instalación
doas apk add nut

# Comprobar conexión
upsc server-room-rack@192.168.x.x
upsc ups@192.168.x.x
```

Configurar el monitor de la SAI (UPS) del cliente NUT editando:

```bash
sudo nano /etc/nut/upsmon.conf
```

o

```bash
doas nvim /etc/nut/upsmon.conf
```

y añadiendo el siguiente monitor:

Si el cliente recibe alimentación del Eaton Ellipse 650 PRO en la sala de servidores:

```bash
MONITOR server-room-rack@192.168.x.x 1 monuser PASSWORD secondary
```

O si el cliente recibe alimentación en el Homelab desde el CyberPower CP 1600EPFCLCD:

```bash
MONITOR ups@192.168.x.x 1 monuser secret secondary
```

> **Nota:** La contraseña **secret** es necesaria porque el NAS Synology, como cliente NUT, está configurado para usar esta contraseña de forma predeterminada.

En `/etc/nut/nut.conf` cambiar el modo de `none` a `MODE=netclient`.

Ahora reiniciar y habilitar el cliente con:

```bash
sudo systemctl restart nut-client
sudo systemctl enable nut-client
```

En Alpine Linux:

```bash
doas rc-service nut-upsmon start
doas rc-update add nut-upsmon default
```

Salida después del primer inicio:

```bash
doas rc-service nut-upsmon start
 * Caching service dependencies ...                                                                                                                                                                        [ ok ]
 * Starting udev ...                                                                                                                                                                                       [ ok ]
 * Waiting for uevents to be processed ...                                                                                                                                                                 [ ok ]
 * Starting UPS Monitor ...
Network UPS Tools upsmon 2.8.2
fopen /run/upsmon.pid: No such file or directory
Could not find PID file to see if previous upsmon instance is already running!
UPS: ups@192.168.x.x (secondary) (power value 1)
Using power down flag file /etc/killpower
```

**Escenario de apagado**

Cuando el servidor NUT primario (`MODE=netserver`) envía un mensaje FSD (Forced Shutdown) – por ejemplo, porque la batería está a punto de agotarse – esta información se transmite a todos los clientes conectados.

Los clientes se apagan de forma controlada antes de que la energía se agote por completo. Por lo tanto, cada servidor que ejecute `nut-client` debe supervisar el SAI correspondiente por su nombre.

## Prueba: Simulación de un corte de energía

Antes de esperar a que ocurra un corte real o desconectar el cable, se puede probar toda la configuración de NUT ejecutando manualmente el llamado **evento FSD** (Forced Shutdown). Esto se hace con el siguiente comando en el **servidor NUT**:

```bash
sudo upsmon -c fsd
```

Esto simula un apagado completo:

Todos los clientes reciben la orden de apagado seguro, y también el SAI (UPS) se apagará después del tiempo de espera configurado. Los dispositivos conectados quedarán entonces **sin alimentación**.

> **Nota:** Este comando solo funciona **localmente en el servidor**, no desde clientes remotos.

### Experiencia práctica

Hasta ahora no he utilizado este comando de prueba manual, sino que he esperado deliberadamente a cortes de energía reales, y en caso necesario he apagado los sistemas manualmente. De esta manera, he podido comprobar en varias ocasiones que toda la configuración funciona correctamente:

- **Todos los sistemas conectados** se apagan progresivamente en caso de corte de energía, según el nivel de batería de cada uno.
- El SAI **se apaga automáticamente** una vez que todos los sistemas se han apagado de forma segura.
- Esto evita que la batería del SAI se **descargue por completo**, lo que ocurre **muy rápido** en un uso **no controlado**.
- **Cuando la energía regresa**, los SAIs se encienden automáticamente y los sistemas conectados arrancan **como si nada hubiera pasado**.
- **Notificaciones push** sobre cortes de energía, apagados y recuperaciones me llegan en tiempo real a mi smartphone, gracias a la integración con **Gotify**.

En cuanto nuestra instalación solar esté en funcionamiento, será probablemente mucho menos necesario que los SAIs tengan que apagarse por completo. El suministro de energía adicional creará un margen extra que aumentará la tolerancia a fallos.

## Bonus: Integrar NUT en Home Assistant

La supervisión del SAI (UPS) mediante **NUT** también puede integrarse fácilmente en **Home Assistant**. De esta manera, los cortes de energía, el nivel de batería y las advertencias de apagado pueden mostrarse y automatizarse directamente desde allí.

**Agregar la integración**

1. En Home Assistant, ir a **"Ajustes > Dispositivos y servicios"**.
2. Hacer clic en **"Agregar integración"** y buscar **"Network UPS Tools (NUT)"**.
3. Se abrirá un cuadro de diálogo:
   - Introducir la **dirección IP** del servidor NUT.
   - El puerto se mantiene en el valor predeterminado (`3493`).
   - Introducir el **nombre de usuario** (`monuser`) y la **contraseña** correspondiente.
4. Opcionalmente, se puede **asignar o crear una habitación**.

**Nota sobre contenedores Docker**

Si Home Assistant se ejecuta dentro de un contenedor Docker (como en mi caso en `sumpfgeist.lan`), puede que el contenedor no pueda acceder a la IP habitual del host (por ejemplo, `192.168.x.x`). En ese caso, se debe utilizar la **dirección IP interna del puente de Docker** – por ejemplo:

```bash
172.21.0.1
```

Esta IP pertenece al puente Docker (`br0`) y permite la comunicación entre el contenedor de **Home Assistant** y el **servicio NUT** que se ejecuta en el host.

Con esto llegamos al final de este artículo: los SAIs ya no funcionan de manera aislada, sino que forman parte de una red inteligente. Con la futura integración del sistema solar, se creará una infraestructura energética bien planificada y fiable, sin intervención manual y con la máxima visibilidad y eficiencia.

**Herramientas utilizadas:**

- [Network UPS Tools](https://networkupstools.org/)
- [PeaNUT](https://github.com/Brandawg93/PeaNUT)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- [Gotify](https://gotify.net/)
- [Home Assistant](https://www.home-assistant.io/)

{{< chat NUT >}}
