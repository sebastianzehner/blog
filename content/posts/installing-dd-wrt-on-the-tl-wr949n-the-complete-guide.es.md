---
title: "Instalación de DD-WRT en el TL-WR949N: la guía completa"
summary: "Así es como actualicé el router brasileño TP-Link TL-WR949N con el firmware DD-WRT: incluyendo una solución para el problema relacionado con el SSID (Error 18005), una guía paso a paso y un procedimiento de recuperación mediante TFTP."
date: 2026-03-31T19:57:00-03:00
lastmod: 2026-03-31T19:57:00-03:00
draft: false
tags:
  - router
  - firmware
  - dd-wrt
categories:
  - techlab

ShowToc: true
TocOpen: true

params:
  author: Sebastian Zehner
  ShowPageViews: true

cover:
  image: /img/router-firmware-cover.webp
  alt: Firmware del router
  hidden: false
  relative: false
  responsiveImages: false

translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: es
  date: 2026-03-31
  time: "21:07:33"
---

He actualizado los routers TP-Link TL-WR949N, que son más económicos, con la firmware proporcionada por [dd-wrt.com](https://dd-wrt.com). A continuación, se describen los pasos que tuve que seguir para poder utilizar dicha firmware.

Me hubiera gustado mucho usar [openwrt.org](https://openwrt.org) como router principal, al igual que hice con [OpenWrt One](https://openwrt.org/toh/openwrt/one), pero lamentablemente no se recomienda hacerlo para [este router](https://openwrt.org/toh/tp-link/tl-wr940n). Y la razón principal es [OpenWrt en dispositivos de tipo 4/32](https://openwrt.org/supported_devices/openwrt_on_432_devices).

- **Modelo:** TL-WR949N(BR) **Versión:** 6.0

Utilizo estos routers principalmente como puntos de acceso (Access Points) en el taller y en el quincho, configurándolos con el protocolo WPA2 y el algoritmo de cifrado CCMP-128 (AES), que representa el nivel más alto de seguridad disponible para este protocolo.

## Contexto

El TL-WR949N es una versión rebrandizada del TL-WR940N, producida en Brasil y que cuenta con la misma hardware. No aparece en el sitio web internacional de TP-Link, por lo que no dispone de soporte oficial para el firmware DD-WRT. Es necesario tener en cuenta la versión de hardware utilizada; en mi caso, se trata de la versión 6.0.

Un intento directo de utilizar la versión oficial del firmware TL-WR940N (o DD-WRT) para realizar una actualización falla a través de la interfaz web habitual, debido a que el modelo WR949N cuenta con un ID de hardware diferente. No obstante, este problema puede solucionarse mediante un método alternativo (workaround).

## Archivos necesarios

| Archivo | Propósito | Fuente |
| ------------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------ |
| `wr940nv6_3_20_1_up_boot(250925).bin` | Firmware TP-Link EU-Stock para el WR940N | [Página de descarga del TP-Link para el WR940N](https://www.tp-link.com/de/support/download/tl-wr940n/#Firmware) |
| `factory-to-ddwrt-eu.bin` | Primera instalación de DD-WRT (Unión Europea) | [Rutero DD-WRT – Base de datos](https://dd-wrt.com/support/router-database/) (`wr940n`) |
| `tl-wr940ndv6-webflash.bin` | Actualización de DD-WRT a una versión más reciente (con un build más actualizado). | [Router DD-WRT – Base de datos](https://dd-wrt.com/support/router-database/) (`wr940n`) |

> **Nota:** La base de datos de routers de DD-WRT contiene versiones obsoletas (a fecha de 2020) y no debe utilizarse. Siempre se debe recurrir directamente al directorio de las versiones beta.

**Descargas de la versión beta de DD-WRT:**

[Descargar](https://download1.dd-wrt.com/dd-wrtv2/downloads/betas/) → Elegir el año o la versión del software → `tplink-tl-wr940ndv6`

**Construcciones probadas („Proven Builds“):**

| Construir. | Fecha | Indicaciones | Descargar |
| ------ | ---------- | ------------------------------- | --------------------------------------------------------------------------------------------------------- |
| r44715 | 2020-11-03 | Está registrado en la base de datos del router. | [Enlace](https://download1.dd-wrt.com/dd-wrtv2/downloads/betas/2020/11-03-2020-r44715/tplink_tl-wr940ndv6/) |
| r64210 | 31-03-2026 | Se ha confirmado que el archivo se encuentra en la carpeta “Beta”. | [Enlace](https://download1.dd-wrt.com/dd-wrtv2/downloads/betas/2026/03-31-2026-r64210/tplink-tl-wr940ndv6/) |

## Requisitos previos

- Cable LAN (siempre se debe utilizar el puerto LAN para la configuración; nunca el puerto WAN).
- Ordenador con navegador

> **Nota:** Esta guía refleja mis propias experiencias. La instalación de firmware de terceros se realiza a propio riesgo; no asumo ninguna responsabilidad en caso de que el router se dañe o se produzcan otros problemas. En caso de duda, es mejor leer la información detalladamente antes de proceder.

## Paso 1: Instalar la firmware correspondiente a la stock de TP-Link para la región UE.

La versión actual de firmware en mi router TL-WR949N v6 es la siguiente:

```text
Versão de Firmware:	3.18.1 Build 171115 Rel.43350n
Versão de Hardware:	WR949N v6 00000000
```

El dispositivo WR949N bloquea la instalación de firmwares externos a través de la interfaz web mediante el código `Error 18005`, pero puedo evitar este problema utilizando el código [Con este método alternativo (workaround)](https://openwrt.org/toh/tp-link/tl-wa801nd) de la siguiente manera.

### Cómo evitar las restricciones impuestas por el firmware

Para utilizar esta solución alternativa, introduzco las siguientes líneas una por una como SSID del dispositivo; es necesario incluir los comillas dobles al escribir cada línea. Después de configurar el SSID, guarde los cambios entre cada una de ellas.

1. Abrir la interfaz web: `http://192.168.0.1` – Iniciar sesión: `admin` / `admin`
2. **Inalámbrico → Campo “SSID” → Introduzca las siguientes líneas una por una y guarde cada una de ellas (actualizar).**

```bash
`echo "httpd -k"> /tmp/s`
`echo "sleep 10">> /tmp/s`
`echo "httpd -r&">> /tmp/s`
`echo "sleep 10">> /tmp/s`
`echo "httpd -k">> /tmp/s`
`echo "sleep 10">> /tmp/s`
`echo "httpd -f">> /tmp/s`
`sh /tmp/s`
```

Tras el último paso (`sh /tmp/s`), se reinicia el proceso `httpd`. El router en sí no se reinicia, pero la interfaz web queda inaccesible durante unos 20–30 segundos.

### Actualización del firmware

1. Abrir la interfaz web: `http://192.168.0.1` – Iniciar sesión: `admin` / `admin`
2. **Herramientas de sistema → Actualización del firmware**
3. Elegir `wr940nv6_3_20_1_up_boot(250925).bin` → **Actualizar**
4. Espere unos minutos hasta que se complete el proceso de actualización y el router se reinicie automáticamente.
5. Restauración a los valores de fábrica: Mantenga presionado el botón de reinicio durante **20 segundos** y espere a que el router se reinicie.

A continuación, se puede volver a acceder a la interfaz web a través de `http://192.168.0.1`. La primera vez que se realiza la solicitud, se pedirá directamente una nueva contraseña; ya no existe un nombre de usuario separado, solo se requiere introducir la contraseña.

La interfaz ahora está en inglés en lugar de en portugués, lo que indica que la firmware de la UE está activa.

La firmware después de la actualización:

```text
Firmware Version:	3.20.1 Build 250925 Rel.57536n (4555)
Hardware Version:	WR940N v6 00000000
```

Ahora puedo utilizar esta firmware, o bien pasar directamente al paso 2 e instalar DD-WRT.

## Paso 2: Primera instalación de DD-WRT

Tras completar el primer paso, ahora puedo instalar DD-WRT sin problemas a través de la interfaz web, y ya no aparece el mensaje `Error 18005`.

### Actualización del firmware

1. Abrir la interfaz web: `http://192.168.0.1` – Introducir la contraseña
2. **Herramientas del sistema → Actualización de firmware**
3. Elegir el código `factory-to-ddwrt-eu.bin` actual → **Actualización**
4. Espere unos minutos hasta que el proceso de actualización se complete y el router se reinicie automáticamente.
5. Restauración a los valores de fábrica: Mantenga presionado el botón de reinicio durante **20 segundos** y espere a que el router se reinicie.

A continuación, se puede acceder a la interfaz web a través de `http://192.168.1.1`. La primera vez que se realiza la solicitud, se pedirá directamente un nuevo nombre de usuario y una nueva contraseña. Una vez proporcionados estos datos, se podrá configurar el router.

## Paso 3: Actualización a una versión más reciente del firmware DD-WRT

El archivo `webflash.bin` está diseñado para actualizaciones (upgrades) cuando DD-WRT ya se encuentra instalado en el router. Proviene del mismo directorio de compilación que el archivo `factory-to-ddwrt`.

### Actualización del firmware

1. Abrir la interfaz web: `http://192.168.1.1` – Introducir el nombre de usuario y la contraseña.
2. **Administración → Actualización del firmware**
3. `tl-wr940ndv6-webflash.bin` Cargar → **Actualizar**
4. Espere unos minutos hasta que el proceso de actualización se complete y el router se reinicie automáticamente.
5. Se recomienda realizar el reinicio desde fábrica: mantenga presionado el botón de reinicio durante **20 segundos** y espere a que el router se reinicie.

## Volver a la recuperación de datos desde el almacenamiento interno de TP-Link (metodo TFTP)

Si DD-WRT está activo en el router y se desea volver a la versión de firmware original, siga los siguientes pasos:

```
PC-IP:         192.168.0.66 / 255.255.255.0
TFTP-Archivo:  wr940nv6_tp_recovery.bin
               (Contenido: Firmware original de TP-Link, renombrado)
```

> **Importante información:** La computadora (PC) y el router deben estar conectados a través de un **conmutador de red**; una conexión directa no funcionará correctamente, ya que Windows interrumpe brevemente la conexión Ethernet al reiniciar el router, lo que impide que el pedido TFTP se envíe.

**Procedimiento:**

1. Conectar la computadora (PC) y el router a través de un conmutador (switch).
2. Iniciar un servidor TFTP (por ejemplo, [tftpd64](https://pjo2.github.io/tftpd64/) o [atftp](https://sourceforge.net/projects/atftp/)).
3. Elegir el índice que contiene el archivo que ha sido renombrado.
4. Elegir la interfaz `192.168.0.66`
5. Apagar el router.
6. Mantén presionado el botón de reinicio, enciende el router.
7. Mantenga presionado el botón de reinicio hasta que se inicie la transferencia TFTP (aproximadamente 10 segundos).
8. Espere a que se complete el proceso de transferencia y que el router se reinicie.

> **Nota:** Antes de cambiar el nombre, la firmware original de TP-Link debe contener el encabezado de arranque (el nombre del archivo incluye `up_boot`). No se debe utilizar una firmware cuyo nombre no contenga `up_boot` para el protocolo TFTP.

## En resumen

El TL-WR949N es un router económico que se puede configurar sin problemas con el sistema operativo DD-WRT, siempre y cuando se tenga un poco de paciencia y se sigan los pasos adecuados. El método alternativo que utiliza el campo SSID es algo inusual, pero funciona de manera fiable. Con la versión actual del firmware DD-WRT, el router funciona de forma estable como un punto de acceso (Access Point).

La documentación de estos pasos ha valido la pena: la próxima vez que tenga que trabajar con un router, no tendré que empezar todo de cero, como he hecho hoy.

¿Has realizado el proceso de actualización del router TL-WR949N o de un modelo similar? ¿Notaste algo inusual durante el proceso, o encontraste alguna otra solución para el problema? Me gustaría recibir tus comentarios: puedes hacerlo directamente aquí abajo a través de Cactus Comments, utilizando tu cuenta de Matrix, o incluso sin cuenta como visitante. Probablemente este tema también sería adecuado para otro artículo en el blog.

Un cordial saludo, Sebastian.

{{< chat installing-dd-wrt-on-the-tl-wr949n >}}
