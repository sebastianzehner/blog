+++
title = 'Cómo crear un sitio web sencillo y autoalojado gratis'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = '''Estás aquí en mi nueva web minimalista y gratuita. Construí este sitio web hace algunas semanas porque me gusta lo simple y reemplacé WordPress con Hugo y PaperMod Theme para mi blog personal en Internet.'''
date = 2024-07-22T10:29:42-04:00 #Ctrl+Shift+I to insert date and time
lastmod = 2024-07-22T10:29:42-04:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['sitio web', 'Hugo', 'PaperMod']
categories = ['Tech']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/how-to-build-a-minimalistic-and-self-hosted-website-for-free.webp'
    alt = 'Imagen destacada de Cómo crear un sitio web sencillo y autoalojado gratis'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

Estás aquí en mi nueva web minimalista y gratuita. Construí este sitio web hace algunas semanas porque me gusta lo simple y reemplacé WordPress con Hugo y PaperMod Theme para mi blog personal en Internet. Trasladé algunas entradas antiguas del blog y escribí algunas entradas nuevas en esta plataforma. Es realmente agradable y me gusta esto - es gratis y de código abierto.

Hoy quiero mostrarte cómo construir un sitio web minimalista y auto-alojado de forma gratuita - cómo lo hice. He instalado Hugo en un Mac Studio pero también funciona en máquinas Linux o Windows. Me gusta tanto que voy a crear un segundo sitio Hugo con el Tema Smol para mi Intranet en casa.

Pero ahora empecemos con la instalación y los primeros pasos:

## Descargar e instalar Visual Studio Code

Utilizo Visual Studio Code en mi Mac Studio para escribir y configurar todas mis cosas. Esta aplicación es de código abierto y funciona también en otros sistemas. Descargué la versión para Mac y simplemente descomprimí el archivo y lo moví a la carpeta de la aplicación. Eso es todo y ahora podemos ejecutar Visual Studio Code con un simple clic del ratón en la aplicación.

También puedo compilar y sincronizar mi sitio web con Visual Studio Code en GitHub.

Es todo gratis y puedes alojar tu web directamente en GitHub y crear una URL o usar Netlify como hago yo. Quizás más adelante te cuente cómo funciona esto. Primero puedes descargar Visual Studio Code [aquí](https://code.visualstudio.com/).

## Instalar Homebrew en Mac

La forma más sencilla de instalar Hugo es utilizando el gestor de paquetes Homebrew.

Por cierto, esto también funciona para otras máquinas Linux. Copié el comando de la [página web](https://brew.sh/) y lo pegué en la línea de comandos del terminal de mi Mac. La instalación terminó automáticamente. Las herramientas de línea de comandos para Xcode también se instalarán automáticamente con este comando.

Una vez completada la instalación ejecute dos comandos en su terminal para añadir Homebrew a su PATH. Están listados detrás de "next steps" en la terminal. Puedes copiarlos y pegarlos.

Para desactivar las analíticas de Homebrew, este comando evitará que se envíen analíticas:

`brew analytics off`

Compruebe la versión instalada con:

`brew -v`

En mi caso: Homebrew 4.3.8

## Instalar Hugo con el gestor de paquetes de código abierto Homebrew

Esta instalación es muy sencilla. Puedes encontrar algo de documentación [aquí](https://gohugo.io/installation/macos/).

Como he dicho antes utilicé el gestor de paquetes Homebrew para MacOS e instalé la edición extendida de Hugo con el siguiente comando en el terminal:

`brew install hugo`

Eso es todo: Hugo ya está instalado.

## Create a new website with Hugo

En mi sistema he creado una nueva carpeta `MyHugoWebsites` en mi carpeta `Documents` y cambié a esta carpeta en la línea de comandos.

Mi nuevo sitio web se llama `sebastianzehner` y con el siguiente comando he creado este nuevo sitio web:

`hugo new site sebastianzehner`

Es posible crear diferentes archivos de configuración como YAML o TOML. He utilizado la configuración estándar con el archivo de configuración TOML.

Encontré un sitio web para transformar YAML a TOML [aquí](https://transform.tools/yaml-to-toml). A veces ayuda si lees un tutorial y utilizan diferentes archivos de configuración. Estoy usando siempre TOML para mis sitios.

## Instalar un tema en Hugo

Decidí utilizar el tema [PaperMod](https://themes.gohugo.io/themes/hugo-papermod/) como tema Hugo rápido, limpio y con capacidad de respuesta. Puedes encontrar documentación para la instalación [aquí](https://github.com/adityatelange/hugo-PaperMod/wiki/Installation).

Utilicé el siguiente comando en el terminal y cambié a la carpeta de mi sitio web `sebastianzehner`:

`git clone https://github.com/adityatelange/hugo-PaperMod themes/PaperMod –depth=1`

Ahora el tema PaperMod será descargado y guardado en la carpeta de temas del sitio web local.

Para mi Intranet local utilizaré el tema [Smol](https://github.com/colorchestra/smol). El proceso de instalación es el mismo. Mi Intranet está instalada en una Raspberry Pi.

## Configuración del sitio web de Hugo

En la barra de búsqueda de Visual Studio Code: _> install Shell Command: Install code command in PATH_

A continuación, escriba en el terminal `code .` y Visual Studio Code se abrirá con la ruta del sitio web instalado.

Abra `hugo.toml` y edite la configuración. He cambiado:

```
baseURL = 'localhost'
languageCode = 'en-us'
title = 'My new Hugo website'
theme = 'PaperMod'
```

A continuación, escriba el siguiente comando en el terminal para iniciar el servidor web local de desarrollo:

`hugo server`

El resultado será éste: `Web Server is available at //localhost:1313/`

Ahora mi sitio web se ejecuta localmente en mi Mac Studio como un servicio de servidor y actualiza todos los cambios inmediatamente. Pulsa `Ctrl+C` para detener el servidor si es necesario o termina tu trabajo.

**También fue una instalación muy fácil!**

En mi próxima entrada del blog te mostraré cómo crear contenido para tu nuevo sitio web. Cómo añadir un menú, etiquetas y categorías, algunos ajustes especiales, etc.

Saludos cordiales Sebastian

{{< chat how-to-build-a-minimalistic-and-self-hosted-website-for-free >}}
