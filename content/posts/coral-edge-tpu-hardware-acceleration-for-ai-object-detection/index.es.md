+++
title = 'Coral Edge TPU: Aceleración de hardware para la detección de objetos con IA'
summary = 'Para mi contenedor Docker de Frigate, quería habilitar la detección de objetos con IA mediante aceleración por hardware, así que compré un chip M.2 Coral Edge TPU A+E y lo instalé en mi servidor doméstico.'
date = 2025-08-13T09:15:00-03:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2025-08-13T09:15:00-03:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Linux', 'Frigate', 'AI', 'Coral', 'TPU', 'NVR', 'Docker', 'Videovigilancia']
categories = ['TechLab']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/coral-edge-tpu-hardware-acceleration-for-ai-object-detection.webp'
    alt = 'Imagen destacada de Coral Edge TPU: Aceleración de hardware para la detección de objetos con IA'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

Para mi **contenedor Docker de Frigate**, quería habilitar la detección de objetos con IA usando aceleración por hardware. Por eso compré un chip M.2 Accelerator Coral Edge TPU con clave A+E e lo instalé en mi servidor doméstico.

## Mi primer montaje: Lenovo ThinkCentre

El **Coral Edge TPU** fue reconocido sin problemas y funcionó perfectamente en la ranura Mini PCIe libre de mi **Lenovo ThinkCentre** (`sumpfgeist.lan`), que normalmente se usa para un módulo WiFi. Esto fue un éxito importante, ya que el mismo módulo no funciona en la ranura WiFi del **Beelink EQ14**, porque solo soporta una interfaz CNVi para WiFi.

## Prueba del acelerador M.2 con clave B+M para el EQ14

Para equipar también el EQ14 con aceleración por hardware, pedí un módulo M.2 Accelerator Coral Edge TPU con clave B+M.

El EQ14 usa Alpine Linux, para el cual no hay controladores oficiales disponibles. Tuve que compilar los controladores yo mismo - lo cual ya he conseguido con éxito.

La instalación y prueba del acelerador M.2 con clave B+M en el EQ14 transcurrió sin problemas. Los controladores fueron compilados en **Alpine Linux 3.22** con el kernel actual y funcionan perfectamente. Durante la compilación aparecieron algunos errores, pero pude solucionarlos.

Para documentar mis ajustes y soluciones, ya he creado un fork del repositorio de los controladores, que describo con más detalle en la última sección de este artículo.

## Instalación del Coral Edge TPU

La instalación del Coral Edge TPU fue sencilla. La ranura PCIe del Lenovo ThinkCentre estaba libre, así que simplemente conecté el módulo y reinicié el servidor. La ranura M.2 correspondiente en el EQ14 también estaba libre, lo que permitió insertar la tarjeta fácilmente y asegurala de forma segura.

## Instalación de los controladores en Ubuntu

La instalación de los controladores para el Coral Edge TPU fue un poco más compleja, ya que surgieron errores durante el proceso de compilación del módulo del kernel. Seguí la [guía oficial de Coral](https://coral.ai/docs/m2/get-started/#2a-on-linux) para Ubuntu, pero encontré problemas de compatibilidad, que describo a continuación.

### Preparación: Comprobación de controladores preinstalados

Primero, verifiqué si ya estaban presentes controladores Apex precompilados:

```bash
uname -r   # Muestra la versión del kernel, por ejemplo, 6.8.0-60-generic
lsmod | grep apex   # Comprueba si los controladores Apex están cargados
```

En mi caso, no había controladores preinstalados.

### La instalación estándar falla

A continuación, añadí el repositorio de paquetes Coral e intenté instalar los paquetes necesarios:

```bash
echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | sudo tee /etc/apt/sources.list.d/coral-edgetpu.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install gasket-dkms libedgetpu1-std
```

Esto produjo un error de compilación durante la construcción del módulo `gasket-dkms` para mi kernel (6.8.0-60-generic), porque el código fuente del controlador no era compatible con mi versión del kernel.

### Análisis del error y solución

El log de compilación mostró errores como:

```bash
error: passing argument 1 of ‘class_create’ from incompatible pointer type
error: too many arguments to function ‘class_create’
```

Este es un problema conocido con el controlador original `gasket-dkms`, ya que fue escrito para versiones anteriores del kernel.

### Solución: Usar un fork y compilar el controlador tú mismo

Para solucionar el problema, primero eliminé el paquete incompatible:

```bash
sudo apt purge gasket-dkms
```

Luego, cloné un fork parcheado que resuelve el problema:

```bash
cd ~/downloads
git clone https://github.com/KyleGospo/gasket-dkms
```

También es necesario instalar las dependencias de compilación:

```bash
sudo apt install dkms libfuse2 dh-dkms devscripts debhelper
```

Después, compilé el paquete con `debuild`:

```bash
cd gasket-dkms
debuild -us -uc -tc -b
```

Como `debhelper` no estaba instalado en mi sistema, ocurrió un error que solucioné instalando `debhelper`.

Tras una compilación exitosa, instalé el paquete `.deb` generado:

```bash
cd ..
sudo dpkg -i gasket-dkms_*.deb
```

En mi sistema, ejecuté específicamente:

```bash
sudo dpkg -i gasket-dkms_1.0-18_all.deb
```

### Permisos y reinicio

Como solo uso el hardware dentro de contenedores Docker y mi usuario forma parte del grupo `docker`, configuré los permisos adecuados mediante una regla `udev`:

```bash
sudo sh -c "echo 'SUBSYSTEM==\"apex\", MODE=\"0660\", GROUP=\"docker\"' > /etc/udev/rules.d/65-apex.rules"
```

Luego, reinicié el sistema:

```bash
sudo reboot
```

### Verificación

Después del reinicio, comprobé si el dispositivo fue detectado:

```bash
ls -alh /dev/apex*
```

Salida:

```bash
crw-rw----  120,0 root docker 10 Jun 11:12 /dev/apex_0
```

Esto confirmó que la instalación del controlador fue exitosa y que el hardware está listo para usarse en contenedores Docker como Frigate.

## Docker Compose: Uso del Coral Edge TPU en el contenedor Frigate

Para usar el Coral Edge TPU dentro del contenedor Docker de Frigate, necesitamos hacer que el hardware sea accesible para el contenedor y ajustar la configuración. Puedes encontrar mi artículo completo sobre Frigate [aquí](/es/posts/frigate-open-source-nvr-real-time-ai-object-detection/).

### Pasar el dispositivo al contenedor

En el archivo `docker-compose.yaml` de Frigate (por ejemplo, en `~/docker-compose/frigate/`), añade la siguiente sección bajo `services.frigate`:

```yaml
devices:
  - /dev/apex_0:/dev/apex_0
```

Esto pasa el dispositivo `/dev/apex_0` del sistema host al contenedor.

### Ajustar la configuración de Frigate

En el archivo de configuración de Frigate `config.yml` (por ejemplo, en `~/docker/frigate/`), añade o modifica la configuración del detector para la TPU:

```yaml
detectors:
  coral1:
    type: edgetpu
    device: pci:0
```

Esto indica a Frigate que use el detector Edge TPU, que se comunica a través del dispositivo PCIe `pci:0`.

### Reiniciar el contenedor

Después de hacer estos cambios, reinicia el contenedor Frigate:

```bash
cd ~/docker-compose/frigate
docker compose down
docker compose up -d
```

Frigate usará ahora la aceleración por hardware del Coral Edge TPU para la detección de objetos con IA. Para más detalles sobre la configuración de Frigate, consulta [aquí](/es/posts/frigate-open-source-nvr-real-time-ai-object-detection/).

## Controladores en Alpine Linux

Para Alpine Linux, existe un repositorio especial con una corrección de errores que permite compilar los controladores Coral Edge TPU para la versión de Alpine y el kernel que estoy utilizando.

Cloné el repositorio [aquí](https://github.com/sebastianzehner/alpine-coral-tpu) y lo adapté para mi versión del kernel. Las instrucciones detalladas de instalación también se encuentran allí.

Para usar el chip Coral en el EQ14, también compré un modelo diferente de TPU en una placa SOM (System-On-Module) adecuado para la ranura M.2-2280-B-M-S3 (B/M Key). Con los controladores compilados por mí mismo, el dispositivo fue reconocido por el sistema.

### Verificación del hardware

Puedes comprobar si el Edge TPU ha sido detectado ejecutando el siguiente comando:

```bash
ls -alh /dev/apex*
```

En mi sistema, la salida es la siguiente:

```bash
crw-rw----  120,0 root 28 Jun 20:46 /dev/apex_0
```

### Migración al EQ14 y rendimiento

Migré mi instalación de Frigate desde el **ThinkCentre** (`sumpfgeist.lan`) al **EQ14** (`eq14.lan`). Allí, el chip Coral es reconocido y la detección de objetos con IA funciona con una latencia promedio de aproximadamente 8 ms por cuadro. La temperatura del chip ronda los 45 °C, lo cual está dentro de un rango seguro.

![Image Frigate Webinterface Detectors Coral Edge TPU](/img/galleries/coral-edge-tpu-hardware-acceleration-for-ai-object-detection/coral-edge-tpu-frigate-detector.webp)

### Actualización del kernel y recompilación

Mientras tanto, actualicé **Alpine Linux** en el **EQ14** con un kernel nuevo. Antes de reiniciar, recompilé los controladores para asegurar la compatibilidad.

Después de iniciar el sistema, copié y activé los archivos actuales del controlador, por lo que el chip Coral fue reconocido nuevamente y Frigate siguió funcionando sin problemas.

Desde entonces, mi repositorio ha sido actualizado para soportar el kernel más reciente de **Alpine Linux 3.22**. Siempre puedes seguir mi guía paso a paso en [GitHub](https://github.com/sebastianzehner/alpine-coral-tpu) para instalar y compilar los controladores con éxito.

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
- [GitHub](https://github.com/sebastianzehner/alpine-coral-tpu)
- [Coral Edge TPU](https://coral.ai/products/)

{{< chat CoralTPU >}}
