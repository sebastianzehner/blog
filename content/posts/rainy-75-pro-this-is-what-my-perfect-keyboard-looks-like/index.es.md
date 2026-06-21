+++
title = 'Rainy 75 Pro: Así es mi teclado perfecto'
summary = 'En abril de 2025 la encontré: mi teclado perfecto. El Rainy 75 Pro de Wobkey no solo es de alta calidad, sino que me conquistó desde la primera pulsación.'
date = 2025-08-05T09:35:10-03:00
lastmod = 2026-05-20T10:07:13-03:00

tags = ['linux', 'keyboard', 'Rainy75Pro', 'keyd', 'setxkbmap']
categories = ['techlab']

showComments = true
chatId = "Rainy75Pro"
+++

## Mi teclado perfecto para macOS y Linux

En abril de 2025 encontré por fin el teclado perfecto: el **Rainy 75 Pro** de [Wobkey](https://www.wobkey.com/products/rainy75). No solo destaca por su alta calidad, sino que me conquistó desde la primera pulsación.

Su sólida carcasa unibody de aluminio, el sonido profundo y la experiencia de escritura equilibrada lo convierten en un verdadero protagonista en mi escritorio. Pero lo más importante para mí era que se integrara sin problemas en mi configuración con varios sistemas (macOS y Linux), sin necesidad de cambiar cables ni estar reconfigurando constantemente.

Utilizo el teclado por USB a través de un switch KVM. Es fundamental **no** conectarlo al puerto "teclado" dedicado del switch (que solo emula un teclado básico), sino a un **puerto USB real**. De lo contrario, funciones como macros o la compatibilidad con VIA no funcionarán correctamente.

En este artículo muestro cómo he adaptado el teclado de forma óptima a mis necesidades: incluyendo soporte para caracteres especiales (como las diéresis en alemán) a pesar del layout en inglés, remapeo de teclas y prácticos macros con **keyd** y **Via**.

## Por qué el layout en inglés (US)?

Quienes programan mucho acaban tarde o temprano utilizando el **layout en inglés (US)**. Al menos así fue en mi caso. `{}`, `[]` o `~` – todos estos caracteres son fácilmente accesibles sin maniobras complicadas, lo que marca una gran diferencia en el uso diario.

Además, el **layout US** es el estándar de referencia en muchas herramientas y sistemas operativos. Las combinaciones de teclas funcionan de forma más fiable y, en accesos remotos (por ejemplo, vía SSH), hay menos problemas con teclas intercambiadas.

Es cierto que faltan las diéresis (como ä, ö, ü), pero no te preocupes: existen soluciones elegantes para eso – tanto en macOS como en Linux.

## Umlaut bajo macOS: Fácil con la tecla Win o Alt derecha

En mi Mac Studio escribo los caracteres con diéresis usando las siguientes combinaciones de teclas:

```
Win+u luego u → ü
Win+u luego a → ä
Win+u luego o → ö
Win+s → ß
```

Funciona sorprendentemente bien, sin necesidad de herramientas adicionales ni software externo. La **tecla Alt derecha** cumple la misma función y, de hecho, es incluso preferible a la **tecla Win**, ya que bajo macOS equivale a la **tecla Opción**.

**Importante:** El teclado debe estar en modo Mac. Se activa **manteniendo presionadas** las teclas `Fn + M` durante al menos 3 segundos.

Solo así se garantiza que las asignaciones específicas de macOS, como Command (⌘) y Option (⌥), funcionen correctamente.

## Umlaut en Linux: Con keyd y la tecla Compose

En Ubuntu con Gnome, la configuración fue sencilla: cambié la distribución del teclado a **English (Macintosh)** y seleccioné la **tecla Alt izquierda** como _Alternative Characters Key_. Con eso, funcionaban las mismas combinaciones de teclas que en macOS. Sin embargo, no es lo más recomendable, y en su lugar debería usarse mejor la **tecla Alt derecha**, también conocida como **tecla AltGr**.

En entornos minimalistas como Alpine o Arch Linux —mis distribuciones favoritas— esto no funciona tan fácilmente. Ahí es donde entra en juego `keyd`. Y justamente ahí está mi enfoque, porque son los sistemas que utilizo a diario.

### Gracias a keyd – Remapeo de teclas como debe ser

**Keyd** es una herramienta ligera y a nivel del sistema para remapear teclas, independiente del entorno de escritorio. Perfecta para configuraciones de Linux minimalistas.

**Instalación en Alpine Linux**

```bash
doas apk add keyd setxkbmap
```

**O en Arch Linux:**

```sh
sudo pacman -Sy keyd xorg-setxkbmap
```

**Configuración básica: `/etc/keyd/default.conf`**

```ini
[ids]
*

[main]
leftalt = leftmeta
leftmeta = leftalt
```

Con esto, por ejemplo, la **tecla Alt izquierda** se convierte en la **tecla Super** (Meta) y viceversa.

### Activar la tecla Compose con setxkbmap

Con el siguiente comando se activa la función Compose a nivel del sistema:

```bash
setxkbmap -option compose:menu
```

En mi `.xinitrc` se ve así:

```bash
#!/bin/bash

# set compose key
setxkbmap -option compose:menu
```

En mi caso, la **tecla Control derecha** se convierte en la **tecla Compose** (normalmente sería la **tecla AltGr**) – ideal para caracteres especiales y diéresis.

Como mi teclado no tiene una **tecla AltGr** dedicada, antes había configurado la **tecla Control derecha** como **Alt derecha** en **Via**. Aunque **AltGr** se puede usar directamente en muchos escritorios Linux para caracteres especiales, la **tecla Compose** suele ser más flexible – especialmente en entornos minimalistas.

### Configuración avanzada de keyd para diéresis

Para facilitar aún más la escritura, he creado una capa personalizada en `keyd` llamada **dia**. En ella defino macros para caracteres con diéresis y otros símbolos especiales:

```ini
[dia]

# Make o to ö
o = macro(compose o ")

# Make a to ä
a = macro(compose a ")

# Make u to ü
u = macro(compose u ")

# Make e to €
e = macro(compose e =)

# Make s to ß
s = macro(compose s s)
```

La **tecla Alt derecha** (AltGr) activa esta capa:

```ini
rightalt = layer(dia)
```

Así, por ejemplo, basta con pulsar **AltGr + o** para escribir una `ö`, lo cual es mucho más rápido e intuitivo que las secuencias clásicas de Compose.

### Iniciar el servicio de keyd

Para que `keyd` se cargue automáticamente al iniciar el sistema, es necesario activar el siguiente servicio:

**En Alpine Linux**

```bash
doas rc-update add keyd
doas rc-service keyd start
```

**Error al iniciar?**

Si `keyd` falla al iniciarse, podría deberse a un conflicto con el paquete `keyd-openrc`. En ese caso, la siguiente secuencia suele resolver el problema:

```bash
doas apk del keyd-openrc
reboot
doas rc-update add keyd
doas rc-service keyd start
```

**En Arch Linux**

```bash
sudo systemctl enable -now keyd
```

**Recargar la configuración**

Después de realizar cambios en el archivo `/etc/keyd/default.conf`, se puede recargar `keyd` con el siguiente comando:

```bash
keyd reload
```

## Copiar y pegar en la terminal

En macOS, copiar y pegar en la terminal funciona cómodamente con `Alt+C` y `Alt+V`. Esto equivale a `Command+C` y `Command+V` en macOS.

En Linux no es tan sencillo: en muchos emuladores de terminal, `Ctrl+C` no sirve para copiar, sino que termina el programa en ejecución. En su lugar, se suele usar `Shift+Ctrl+C` para copiar y `Shift+Ctrl+V` para pegar, lo cual puede resultar poco práctico, especialmente si se cambia con frecuencia entre programas y sistemas.

En mi configuración con **st**, el terminal minimalista de [suckless](https://st.suckless.org/), al principio fue raro acostumbrarse a copiar y pegar.

Cómo lo he optimizado —incluyendo **historial del portapapeles** y atajos personalizados— lo contaré con gusto en uno de los próximos artículos del blog.

## Personalización del firmware del teclado con Via

**Via** es una [web app](https://www.usevia.app/) que permite configurar cómodamente teclados compatibles como mi **Rainy 75 Pro**.

Permite cambiar la asignación de teclas, macros y capas directamente en el firmware sin flashear, directamente por USB.

**Importante:** Via solo funciona cuando el teclado está **conectado directamente por USB**, **no a través de un KVM switch**. Además, principalmente es compatible con **navegadores basados en Chrome**. **Firefox** no funciona actualmente.

### Mi configuración actual

Antes tenía una macro en **Caps Lock**, pero desde entonces he simplificado y hecho mi configuración más consistente:

- En **tmux** uso como prefijo: `Ctrl + Space`
- En **Neovim** el Leader Key también es `Space`

Esto se siente mucho más natural y crea un flujo de trabajo coherente entre ambas herramientas.

Además, en **Via** he reasignado la **tecla derecha Ctrl** a **Alt derecha** para mejorar el acceso a caracteres especiales y ajustes de distribución del teclado.

## Conclusión

Mi **Rainy 75 Pro** no es solo un placer visual y táctil — con las herramientas adecuadas como `keyd`, `setxkbmap` y **Via**, su funcionalidad alcanza un nivel completamente nuevo. Ya sea en macOS o Linux, puedo trabajar de manera fluida, escribir umlauts sin problemas y tener un control total sobre mis combinaciones de teclas personalizadas.

En futuros artículos profundizaré en mis configuraciones de Linux, incluyendo **dwm**, **nvim** y la **configuración del portapapeles (clipboard)**. Si tienes preguntas sobre el teclado o las configuraciones, no dudes en escribirme o dejar un comentario.

**Nota:** Puedes encontrar la Rainy 75 Pro, por ejemplo, [aquí en Amazon](https://amzn.to/3HfwkO5) — enlace de afiliado, sin costo adicional para ti.

**Herramientas usadas:**

- [Rainy 75 Pro - Wobkey](https://www.wobkey.com/products/rainy75)
- [Keyd GitHub Repo](https://github.com/rvaiya/keyd)
- [Setxkbmap Linux man page](https://linux.die.net/man/1/setxkbmap)
- [Via Web App](https://www.usevia.app/)
