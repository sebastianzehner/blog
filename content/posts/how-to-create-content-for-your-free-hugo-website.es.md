+++
title = 'Cómo crear contenidos para su sitio web gratuito Hugo'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = 'Hoy te mostraré cómo crear contenido con un sitio web Hugo, cómo añadir menús, etiquetas y categorías y cómo realizar algunos ajustes especiales.'
date = 2024-08-13T16:05:39-04:00
lastmod = 2024-08-13T16:05:39-04:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['sitio web', 'Hugo', 'PaperMod']
categories = ['Tech']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/how-to-create-content-for-your-free-hugo-website.webp'
    alt = 'Imagen destacada de Cómo crear contenidos para su sitio web gratuito Hugo'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

En la [primera parte de esta serie](/es/posts/how-to-build-a-minimalistic-and-self-hosted-website-for-free/) instalamos nuestro sitio web Hugo con el tema PaperMod localmente en nuestro ordenador y configuramos todo para que ahora podamos añadir algo de contenido a nuestro nuevo sitio web.

Hoy te mostraré cómo crear este contenido, cómo añadir menús, etiquetas y categorías y cómo hacer algunos ajustes especiales.

## Crear contenido para su nuevo sitio web

### Explicación de la estructura de archivos

La carpeta **content** es para el contenido del sitio web como nuevos sitios o entradas de blog.

Las carpetas **layouts** y **assets** son para sobreescribir la configuración estándar del tema instalado. Para realizar cambios, copia el archivo de la carpeta layouts o assets del tema en la carpeta layouts o assets de hugo y sobrescríbelo allí.

En nuestro caso este es el tema PaperMod y no hacemos cambios en la carpeta `/themes/PaperMod`. En su lugar, copiamos los archivos a nuestra carpeta layouts o assets y cambiamos los archivos allí. Esto sobrescribirá automáticamente la configuración de diseño estándar si desplegamos nuestro sitio web.

La carpeta **static** es para todos los activos estáticos como imágenes y nuestros archivos de idioma se almacenan en la carpeta **i18n**.

Si una vez arrancado el servidor hugo también encontraremos una carpeta **public** con todos los archivos html y css de nuestra web para revisar en el navegador.

### Crear el primer blogpost

Para crear un blogpost en la web de Hugo ve al terminal y escribe:

```CMD
hugo new posts/first.md
```

Es importante que esté en la carpeta raíz del sitio web. En mi caso la carpeta **sebastianzehner** pero más tarde renombré esta carpeta a **blog**.

De vuelta en Visual Studio Code abre el nuevo archivo first.md para editarlo. La extensión de archivo .md significa Markdown.

### Cómo escribir y formatear

Utiliza la sintaxis básica de Markdown para escribir y dar formato a tus sitios y blogposts. Aquí tienes algunos enlaces para más información:

- [Markdown Basic Syntax](https://www.markdownguide.org/basic-syntax/)
- [Content Management](https://gohugo.io/content-management/front-matter/)
- [PaperMod Features](https://github.com/adityatelange/hugo-PaperMod/wiki/Features)

Esta es una opción para crear una nueva entrada utilizando la línea de comandos.

Otra opción es directamente en Visual Studio Code y crear un nuevo archivo por ejemplo second.md en el editor. Es un archivo vacío, así que después de crear copiar o escribir algo de contenido en el nuevo archivo y guardar.

También Visual Studio Code es sólo una opción más para usar un editor. Puedes usar cualquier otro editor que quieras.

Yo empecé con Visual Studio Code pero más tarde cambié a [Neovim](https://neovim.io/) y hice algunas personalizaciones para una configuración de desarrollador agradable y nerd y me gusta.

Tal vez escriba un blogpost sobre Neovim más adelante.

## Crear menús

Abre el archivo `hugo.toml` y añade algo de código para crear el menú.

Aquí un ejemplo para una estructura simple de menú:

```TOML
[menus]
  [[menus.main]]
    name = 'Products'
    pageRef = '/products'
    weight = 10
  [[menus.main]]
    name = 'Hardware'
    pageRef = '/products/hardware'
    parent = 'Products'
    weight = 1
  [[menus.main]]
    name = 'Software'
    pageRef = '/products/software'
    parent = 'Products'
    weight = 2
  [[menus.main]]
    name = 'Services'
    pageRef = '/services'
    weight = 20
  [[menus.main]]
    name = 'Hugo'
    pre = '<i class="fa fa-heart"></i>'
    url = 'https://gohugo.io/'
    weight = 30
    [menus.main.params]
      rel = 'external'
```

Estoy utilizando una estructura de menú multilingüe. Este es un ejemplo con la estructura del menú de mi blog:

```TOML
defaultContentLanguage = 'en'
defaultContentLanguageInSubdir = true
[languages]
  [languages.en]
    languageCode = 'en-US'
    languageName = 'English'
    weight = 1
    [languages.en.menus]
        [[languages.en.menus.main]]
            name = 'Home'
            pageRef = '/'
            weight = 10
        [[languages.en.menus.main]]
            identifier = 'categories'
            name = 'Categories'
            pageRef = '/categories/'
            weight = 20
        [[languages.en.menus.main]]
            identifier = 'tags'
            name = 'Tags'
            pageRef = '/tags/'
            weight = 30
        [[languages.en.menus.main]]
            identifier = 'archives'
            name = 'Archives'
            pageRef = '/archives/'
            weight = 40
  [languages.de]
    languageCode = 'de-DE'
    languageName = 'Deutsch'
    weight = 2
    [languages.de.menus]
        [[languages.de.menus.main]]
            name = 'Start'
            pageRef = '/'
            weight = 10
        [[languages.de.menus.main]]
            identifier = 'categories'
            name = 'Kategorien'
            pageRef = '/categories/'
            weight = 20
        [[languages.de.menus.main]]
            identifier = 'tags'
            name = 'Tags'
            pageRef = '/tags/'
            weight = 30
        [[languages.de.menus.main]]
            identifier = 'archives'
            name = 'Archiv'
            pageRef = '/archives/'
            weight = 40
```

Esto es desde el principio. Más tarde añadí también el español y cambié algunos menús y configuraciones.

## Añadir etiquetas y categorías

Las etiquetas y categorias se ponen en el front matter de cada post o sitio. Ejemplo:

```TOML
tags = ['Hugo', 'Website', 'PaperMod']
categories = ['Tech']
```

Es muy importante utilizar sólo una categoría para cada sitio o blogpost. Usted puede utilizar más etiquetas diferentes en su lugar. Normalmente utilizo una categoría y tres etiquetas en cada entrada o sitio.

Si también utiliza las categorías de menús o etiquetas como yo esto es útil para estructurar tu blog y los visitantes podrían encontrar y ordenar los sitios para sus respectivos intereses.

## Algunas opciones especiales

Si quieres mostrar BreadCrumbs, ShareButtons, ReadingTime o PostNavLinks en la web. Añade esto a tu archivo hugo.toml:

```TOML
[params]
    ShowBreadCrumbs = true
    ShowShareButtons = true
    ShowReadingTime = true
    ShowPostNavLinks = true
```

Estoy usando el modo Home-Info del tema PaperMod y añadí esto a mi archivo hugo.toml. También he añadido algunos iconos de redes sociales y enlaces como Facebook y Youtube, por ejemplo:

```TOML
[params.homeInfoParams]
    title = 'Hello my friend...'
    content = 'Welcome to my blog. Here you will find a lot of cool information about a lot of cool stuff.'
    [[params.socialIcons]]
        name = 'facebook'
        url = 'https://www.facebook.com/yourfacebook'
    [[params.socialIcons]]
        name = 'youtube'
        url = 'https://www.youtube.com/@youryoutube'
```

Ahora hemos hecho algunas configuraciones básicas y añadido algunos contenidos a nuestro nuevo sitio web. El siguiente paso es desplegar y publicar nuestro nuevo sitio web en Internet.

En el próximo blogpost te mostraré cómo lo hice con GitHub y Netlify de forma gratuita. Estad atentos y nos vemos pronto.

Saludos Sebastian

{{< chat how-to-create-content-for-your-free-hugo-website >}}
